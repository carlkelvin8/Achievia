import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/billing_helpers.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:achievia/presentation/provider/billing/billing_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String checkoutFailureMessage(CheckoutFailure failure) {
  switch (failure) {
    case CheckoutFailure.notSignedIn:
      return 'Please sign in again to continue.';
    case CheckoutFailure.planUnavailable:
      return 'This plan is not available right now.';
    case CheckoutFailure.alreadyOwned:
      return 'You already own this.';
    case CheckoutFailure.notConfigured:
      return 'Payments are not available yet. Please try again later.';
    case CheckoutFailure.invalidResponse:
    case CheckoutFailure.network:
      return 'We could not start the payment. Check your connection and '
          'try again.';
  }
}

/// Plans and purchases. Prices come from the backend; picking a plan only
/// sends its code.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Future<void> _buy(BuildContext context, WidgetRef ref, String code) async {
    final orderId = await ref
        .read(checkoutControllerProvider.notifier)
        .start(code);
    if (!context.mounted) return;
    if (orderId != null) {
      context.push(
        Uri(
          path: RouteConstants.paymentStatus,
          queryParameters: {'order': orderId},
        ).toString(),
      );
      return;
    }
    final failure = ref.read(checkoutControllerProvider).failure;
    if (failure != null) {
      AppToast.showError(context, checkoutFailureMessage(failure));
      ref.read(checkoutControllerProvider.notifier).clearFailure();
    }
  }

  Future<void> _startTrial(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(trialControllerProvider.notifier).claim();
    if (!context.mounted) return;
    switch (result) {
      case TrialClaimResult.started:
        AppToast.showSuccess(context, 'Your 7-day free trial has started.');
      case TrialClaimResult.alreadyUsed:
        AppToast.showInfo(context, 'You already used your free trial.');
      case TrialClaimResult.subscribed:
        AppToast.showInfo(context, 'You already have an active subscription.');
      case null:
        AppToast.showError(
          context,
          'We could not start your trial. Please try again.',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(billingPlansProvider);
    final access = ref.watch(accessStatusProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Subscription', centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(billingPlansProvider);
          ref.invalidate(accessStatusProvider);
          await ref
              .read(billingPlansProvider.future)
              .catchError((_) => <BillingPlan>[]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AccessCard(
              access: access,
              trialBusy: ref.watch(trialControllerProvider),
              onStartTrial: () => _startTrial(context, ref),
            ),
            const SizedBox(height: 16),
            Text('Choose a plan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'One-time payment. Your plan does not renew automatically.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            plans.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                key: const ValueKey('plans-error'),
                children: [
                  const Text('We could not load the plans.'),
                  TextButton(
                    onPressed: () => ref.invalidate(billingPlansProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (list) => _PlanList(
                plans: list,
                access: access.value ?? AccessStatus.none,
                busyCode: checkout.busy ? checkout.pendingPlanCode : null,
                onBuy: (code) => _buy(context, ref, code),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final AsyncValue<AccessStatus> access;
  final bool trialBusy;
  final VoidCallback onStartTrial;

  const _AccessCard({
    required this.access,
    required this.trialBusy,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = access.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: value == null
            ? Text(
                access.hasError
                    ? 'We could not check your subscription.'
                    : 'Checking your subscription...',
                key: const ValueKey('access-unknown'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    describeAccess(value),
                    key: const ValueKey('access-subscription'),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (describeTrial(value, DateTime.now()).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      describeTrial(value, DateTime.now()),
                      key: const ValueKey('access-trial'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    value.motherNotesOwned
                        ? 'Mother Notes: owned (lifetime)'
                        : 'Mother Notes: not purchased',
                    key: const ValueKey('access-mother-notes'),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (value.canStartTrial) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('start-trial'),
                        onPressed: trialBusy ? null : onStartTrial,
                        icon: trialBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.card_giftcard),
                        label: const Text('Start 7-day free trial'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  final List<BillingPlan> plans;
  final AccessStatus access;
  final String? busyCode;
  final void Function(String code) onBuy;

  const _PlanList({
    required this.plans,
    required this.access,
    required this.busyCode,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    // Shortest plan first, whatever order the backend returned them in.
    final subscriptions = [
      for (final p in plans)
        if (p.kind == BillingPlanKind.subscription) p,
    ]..sort((a, b) => (a.durationMonths ?? 0).compareTo(b.durationMonths ?? 0));
    BillingPlan? motherNotes;
    for (final plan in plans) {
      if (plan.kind == BillingPlanKind.motherNotes) motherNotes = plan;
    }

    return Column(
      children: [
        for (final plan in subscriptions)
          _PlanTile(
            key: ValueKey('plan-${plan.code}'),
            title: plan.title,
            subtitle: subscriptionLength(plan.durationMonths),
            price: formatPesoFromCentavos(plan.amountCentavos),
            busy: busyCode == plan.code,
            enabled: busyCode == null,
            actionLabel: access.subscriptionActive ? 'Extend' : 'Subscribe',
            onPressed: () => onBuy(plan.code),
          ),
        const SizedBox(height: 16),
        if (motherNotes != null)
          _PlanTile(
            key: const ValueKey('plan-mother_notes'),
            title: motherNotes.title,
            subtitle: 'One-time purchase. Yours for life.',
            price: formatPesoFromCentavos(motherNotes.amountCentavos),
            busy: busyCode == motherNotes.code,
            enabled: busyCode == null && !access.motherNotesOwned,
            actionLabel: access.motherNotesOwned ? 'Owned' : 'Buy',
            onPressed: () => onBuy(motherNotes!.code),
          )
        else
          const Card(
            key: ValueKey('plan-mother_notes-unavailable'),
            child: ListTile(
              title: Text('Mother Notes (lifetime)'),
              subtitle: Text('Coming soon'),
            ),
          ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool busy;
  final bool enabled;
  final String actionLabel;
  final VoidCallback onPressed;

  const _PlanTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.busy,
    required this.enabled,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle.isEmpty ? price : '$price · $subtitle'),
        trailing: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: enabled ? onPressed : null,
                child: Text(actionLabel),
              ),
      ),
    );
  }
}
