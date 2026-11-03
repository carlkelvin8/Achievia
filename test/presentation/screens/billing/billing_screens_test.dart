import 'package:achievia/data/data_source/billing/billing_remote_datasource.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:achievia/presentation/provider/billing/billing_provider.dart';
import 'package:achievia/presentation/screens/billing/payment_status_screen.dart';
import 'package:achievia/presentation/screens/billing/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';

const _plans = [
  BillingPlan(
    code: 'sub_1m',
    kind: BillingPlanKind.subscription,
    title: '1 Month',
    amountCentavos: 29900,
    durationMonths: 1,
  ),
  BillingPlan(
    code: 'sub_12m',
    kind: BillingPlanKind.subscription,
    title: '12 Months',
    amountCentavos: 169900,
    durationMonths: 12,
  ),
];

class FakeBilling implements BillingRepository {
  FakeBilling({
    this.plans = _plans,
    this.access = AccessStatus.none,
    this.checkout,
    this.checkoutError,
    List<PaymentOrder?> orders = const [],
  }) : _orders = [...orders];

  final List<BillingPlan> plans;
  AccessStatus access;
  int trialClaims = 0;
  final CheckoutSession? checkout;
  final CheckoutException? checkoutError;
  final List<PaymentOrder?> _orders;
  final requestedPlans = <String>[];

  @override
  Future<List<BillingPlan>> getPlans() async => plans;

  @override
  Future<AccessStatus> getAccess() async => access;

  @override
  Future<CheckoutSession> createCheckout(String planCode) async {
    requestedPlans.add(planCode);
    if (checkoutError != null) throw checkoutError!;
    return checkout!;
  }

  @override
  Future<PaymentOrder?> getOrder(String orderId) async {
    if (_orders.isEmpty) return null;
    return _orders.length > 1 ? _orders.removeAt(0) : _orders.first;
  }

  @override
  Future<void> cancelOrder(String orderId) async {}

  @override
  Future<TrialClaimResult> claimFreeTrial() async {
    trialClaims++;
    if (access.trialUsed || access.subscriptionActive) {
      return access.subscriptionActive
          ? TrialClaimResult.subscribed
          : TrialClaimResult.alreadyUsed;
    }
    access = AccessStatus(
      subscriptionActive: false,
      motherNotesOwned: false,
      trialActive: true,
      trialUsed: true,
      trialEndsAt: DateTime.now().add(const Duration(days: 7)),
    );
    return TrialClaimResult.started;
  }
}

PaymentOrder order(PaymentOrderStatus status, {String? failure}) =>
    PaymentOrder(
      id: 'o1',
      planCode: 'sub_1m',
      kind: BillingPlanKind.subscription,
      amountCentavos: 29900,
      status: status,
      lastFailure: failure,
    );

Widget host(
  FakeBilling billing,
  Widget child, {
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      billingRepositoryProvider.overrideWithValue(billing),
      paymentPollIntervalProvider.overrideWithValue(
        const Duration(milliseconds: 10),
      ),
      ...extra,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('SubscriptionScreen', () {
    testWidgets('lists the plans with prices from centavos', (tester) async {
      await tester.pumpWidget(host(FakeBilling(), const SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('₱299 · 1 month'), findsOneWidget);
      expect(find.text('₱1,699 · 12 months'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('plan-mother_notes-unavailable')),
        findsOneWidget,
      );
      expect(find.text('No active subscription'), findsOneWidget);
    });

    testWidgets('shows Mother Notes as owned and the subscription expiry', (
      tester,
    ) async {
      final billing = FakeBilling(
        plans: [
          ..._plans,
          const BillingPlan(
            code: 'mother_notes',
            kind: BillingPlanKind.motherNotes,
            title: 'Mother Notes (lifetime)',
            amountCentavos: 49900,
          ),
        ],
        access: AccessStatus(
          subscriptionActive: true,
          subscriptionExpiresAt: DateTime(2027, 3, 5),
          motherNotesOwned: true,
        ),
      );
      await tester.pumpWidget(host(billing, const SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Active until March 5, 2027'), findsOneWidget);
      expect(find.text('Mother Notes: owned (lifetime)'), findsOneWidget);
      expect(find.text('Owned'), findsOneWidget);
      expect(find.text('Extend'), findsNWidgets(2));
    });

    testWidgets('buying sends only the plan code and opens the checkout', (
      tester,
    ) async {
      final opened = <Uri>[];
      final billing = FakeBilling(
        checkout: CheckoutSession(
          orderId: 'o1',
          checkoutUri: Uri.parse('https://checkout.example.test/cs_1'),
        ),
        orders: [order(PaymentOrderStatus.pending)],
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SubscriptionScreen()),
          GoRoute(
            path: RouteConstants.paymentStatus,
            builder: (_, state) => PaymentStatusScreen(
              orderId: state.uri.queryParameters['order']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billingRepositoryProvider.overrideWithValue(billing),
            paymentPollIntervalProvider.overrideWithValue(
              const Duration(milliseconds: 10),
            ),
            checkoutLauncherProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return true;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('plan-sub_1m')),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(billing.requestedPlans, ['sub_1m']);
      expect(opened.single.toString(), 'https://checkout.example.test/cs_1');
      // After opening the page the customer lands on the status screen.
      await tester.pump();
      expect(find.byKey(const ValueKey('payment-processing')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('a backend failure is reported and nothing is opened', (
      tester,
    ) async {
      final opened = <Uri>[];
      final billing = FakeBilling(
        checkoutError: const CheckoutException(CheckoutFailure.notConfigured),
      );
      await tester.pumpWidget(
        host(
          billing,
          const SubscriptionScreen(),
          extra: [
            checkoutLauncherProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return true;
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('plan-sub_12m')),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(opened, isEmpty);
      expect(
        find.textContaining('Payments are not available yet'),
        findsOneWidget,
      );
    });
  });

  group('free trial', () {
    testWidgets('a new user can start the 7-day trial once', (tester) async {
      final billing = FakeBilling();
      await tester.pumpWidget(host(billing, const SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-trial')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-trial')));
      await tester.pumpAndSettle();

      expect(billing.trialClaims, 1);
      expect(find.byKey(const ValueKey('start-trial')), findsNothing);
      expect(find.textContaining('Free trial: 7 days left'), findsOneWidget);
    });

    testWidgets('no trial button once it was used or while subscribed', (
      tester,
    ) async {
      final used = FakeBilling(
        access: AccessStatus(
          subscriptionActive: false,
          motherNotesOwned: false,
          trialUsed: true,
          trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await tester.pumpWidget(host(used, const SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-trial')), findsNothing);
      expect(find.text('Free trial ended'), findsOneWidget);

      final subscribed = FakeBilling(
        access: AccessStatus(
          subscriptionActive: true,
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
          motherNotesOwned: false,
        ),
      );
      await tester.pumpWidget(host(subscribed, const SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-trial')), findsNothing);
    });
  });

  group('PaymentStatusScreen', () {
    testWidgets('shows Payment processing until the backend confirms', (
      tester,
    ) async {
      final billing = FakeBilling(
        orders: [
          order(PaymentOrderStatus.pending),
          order(PaymentOrderStatus.pending),
          order(PaymentOrderStatus.paid),
        ],
      );
      await tester.pumpWidget(
        host(billing, const PaymentStatusScreen(orderId: 'o1')),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('payment-processing')), findsOneWidget);
      expect(find.text('Payment processing'), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-paid')), findsNothing);

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byKey(const ValueKey('payment-paid')), findsOneWidget);
    });

    testWidgets('a pending order never shows a paid state', (tester) async {
      final billing = FakeBilling(orders: [order(PaymentOrderStatus.pending)]);
      await tester.pumpWidget(
        host(billing, const PaymentStatusScreen(orderId: 'o1')),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byKey(const ValueKey('payment-paid')), findsNothing);
      expect(find.byKey(const ValueKey('payment-processing')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('failed, expired and cancelled orders show no access', (
      tester,
    ) async {
      final cases = {
        'payment-failed': order(
          PaymentOrderStatus.pending,
          failure: 'declined',
        ),
        'payment-expired': order(PaymentOrderStatus.expired),
        'payment-cancelled': order(PaymentOrderStatus.cancelled),
      };
      for (final entry in cases.entries) {
        final billing = FakeBilling(orders: [entry.value]);
        await tester.pumpWidget(
          host(billing, const PaymentStatusScreen(orderId: 'o1')),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(ValueKey(entry.key)),
          findsOneWidget,
          reason: entry.key,
        );
        expect(find.byKey(const ValueKey('payment-paid')), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
  });
}
