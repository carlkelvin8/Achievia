import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:achievia/presentation/provider/billing/billing_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shows where a purchase stands. It only displays the state the backend
/// reports (set by the verified PayMongo webhook); it never grants access, and
/// being sent here by the checkout redirect proves nothing.
class PaymentStatusScreen extends ConsumerWidget {
  final String orderId;
  final bool returnedFromCancel;

  const PaymentStatusScreen({
    super.key,
    required this.orderId,
    this.returnedFromCancel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(paymentOrderStatusProvider(orderId));
    return Scaffold(
      appBar: const CustomAppBar(title: 'Payment', centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: status.when(
            loading: () => const _Processing(),
            error: (_, _) => _Message(
              key: const ValueKey('payment-error'),
              icon: Icons.cloud_off,
              title: 'We could not check your payment',
              body:
                  'If you already paid, your access will appear once the '
                  'payment is confirmed. Check again in a moment.',
              actionLabel: 'Check again',
              onAction: () =>
                  ref.invalidate(paymentOrderStatusProvider(orderId)),
            ),
            data: (order) => _body(context, ref, order),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, PaymentOrder? order) {
    if (order == null) {
      return const _Processing();
    }
    switch (order.status) {
      case PaymentOrderStatus.paid:
        return _Message(
          key: const ValueKey('payment-paid'),
          icon: Icons.check_circle,
          iconColor: Colors.green,
          title: 'Payment confirmed',
          body: order.kind == BillingPlanKind.motherNotes
              ? 'Mother Notes is now yours for life.'
              : 'Your subscription is active.',
          actionLabel: 'Done',
          onAction: () => context.go(RouteConstants.subscription),
        );
      case PaymentOrderStatus.expired:
        return _Message(
          key: const ValueKey('payment-expired'),
          icon: Icons.timer_off,
          title: 'This checkout expired',
          body: 'You were not charged. You can start a new payment anytime.',
          actionLabel: 'Back to plans',
          onAction: () => context.go(RouteConstants.subscription),
        );
      case PaymentOrderStatus.cancelled:
        return _Message(
          key: const ValueKey('payment-cancelled'),
          icon: Icons.cancel_outlined,
          title: 'Payment cancelled',
          body: 'No payment was made.',
          actionLabel: 'Back to plans',
          onAction: () => context.go(RouteConstants.subscription),
        );
      case PaymentOrderStatus.pending:
        if (order.hasFailedAttempt) {
          return _Message(
            key: const ValueKey('payment-failed'),
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'The payment did not go through',
            body:
                'You were not charged for the failed attempt. You can try '
                'again from the plans screen.',
            actionLabel: 'Back to plans',
            onAction: () => context.go(RouteConstants.subscription),
          );
        }
        if (returnedFromCancel) {
          return _Message(
            key: const ValueKey('payment-returned'),
            icon: Icons.hourglass_empty,
            title: 'Waiting for payment',
            body:
                'If you completed the payment, it will be confirmed here '
                'shortly. Otherwise nothing was charged.',
            actionLabel: 'Back to plans',
            onAction: () => context.go(RouteConstants.subscription),
            showProgress: true,
          );
        }
        return const _Processing();
    }
  }
}

class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('payment-processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Payment processing',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we confirm your payment. This can take a '
          'little while. You can leave this screen; your access will be '
          'updated once the payment is confirmed.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final bool showProgress;

  const _Message({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (showProgress) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
