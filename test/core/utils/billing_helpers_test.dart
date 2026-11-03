import 'package:achievia/core/utils/billing_helpers.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPesoFromCentavos', () {
    test('formats the four subscription prices from integer centavos', () {
      expect(formatPesoFromCentavos(29900), '₱299');
      expect(formatPesoFromCentavos(59900), '₱599');
      expect(formatPesoFromCentavos(99900), '₱999');
      expect(formatPesoFromCentavos(169900), '₱1,699');
    });

    test('keeps centavos and handles edge values', () {
      expect(formatPesoFromCentavos(29950), '₱299.50');
      expect(formatPesoFromCentavos(5), '₱0.05');
      expect(formatPesoFromCentavos(0), '₱0');
    });
  });

  group('safeCheckoutUri', () {
    test('accepts only https pages', () {
      expect(safeCheckoutUri('https://checkout.paymongo.com/cs_1'), isNotNull);
      expect(safeCheckoutUri('http://checkout.paymongo.com/cs_1'), isNull);
      expect(safeCheckoutUri('achievia://callback'), isNull);
      expect(safeCheckoutUri('javascript:alert(1)'), isNull);
      expect(safeCheckoutUri('/relative'), isNull);
      expect(safeCheckoutUri(''), isNull);
      expect(safeCheckoutUri(null), isNull);
    });
  });

  group('parsePaymentReturn', () {
    const order = '11111111-2222-4333-8444-555555555555';

    test('reads a success and a cancel redirect', () {
      final ok = parsePaymentReturn(
        Uri.parse('achievia://callback?payment=success&order=$order'),
      );
      expect(ok?.orderId, order);
      expect(ok?.cancelled, isFalse);
      final cancelled = parsePaymentReturn(
        Uri.parse('achievia://callback?payment=cancelled&order=$order'),
      );
      expect(cancelled?.cancelled, isTrue);
    });

    test('ignores auth callbacks and malformed links', () {
      expect(
        parsePaymentReturn(Uri.parse('achievia://callback?code=abc')),
        isNull,
      );
      expect(
        parsePaymentReturn(
          Uri.parse('achievia://callback?payment=success&order=nope'),
        ),
        isNull,
      );
      expect(
        parsePaymentReturn(
          Uri.parse('achievia://callback?payment=hacked&order=$order'),
        ),
        isNull,
      );
    });
  });

  group('trial', () {
    test('days left rounds up and never goes negative', () {
      final now = DateTime(2026, 10, 12, 9);
      expect(daysLeftUntil(DateTime(2026, 10, 19, 9), now), 7);
      expect(daysLeftUntil(DateTime(2026, 10, 12, 10), now), 1);
      expect(daysLeftUntil(DateTime(2026, 10, 12, 8), now), 0);
      expect(daysLeftUntil(now, now), 0);
    });

    test('access reflects the trial and who may start it', () {
      final now = DateTime(2026, 10, 12, 9);
      final running = AccessStatus(
        subscriptionActive: false,
        motherNotesOwned: false,
        trialActive: true,
        trialUsed: true,
        trialEndsAt: DateTime(2026, 10, 15, 9),
      );
      expect(running.hasFullAccess, isTrue);
      expect(running.canStartTrial, isFalse);
      expect(describeTrial(running, now), contains('3 days left'));

      expect(AccessStatus.none.hasFullAccess, isFalse);
      expect(AccessStatus.none.canStartTrial, isTrue);

      final ended = AccessStatus(
        subscriptionActive: false,
        motherNotesOwned: false,
        trialUsed: true,
        trialEndsAt: DateTime(2026, 10, 1),
      );
      expect(ended.hasFullAccess, isFalse);
      expect(ended.canStartTrial, isFalse);
      expect(describeTrial(ended, now), 'Free trial ended');
    });

    test('trial fields are parsed from the server response', () {
      final access = AccessStatus.fromJson({
        'subscription_active': false,
        'mother_notes_owned': false,
        'trial_active': true,
        'trial_used': true,
        'trial_ends_at': '2026-10-19T09:00:00+00:00',
      });
      expect(access.trialActive, isTrue);
      expect(access.trialUsed, isTrue);
      expect(access.trialEndsAt, isNotNull);
    });
  });

  group('entities', () {
    test('plans without a price or with an unknown kind are dropped', () {
      expect(
        BillingPlan.tryFromRow({
          'code': 'sub_1m',
          'kind': 'subscription',
          'title': '1 Month',
          'amount_centavos': 29900,
          'duration_months': 1,
        })?.amountCentavos,
        29900,
      );
      expect(
        BillingPlan.tryFromRow({
          'code': 'mother_notes',
          'kind': 'mother_notes',
          'title': 'Mother Notes',
          'amount_centavos': null,
        }),
        isNull,
      );
      expect(
        BillingPlan.tryFromRow({
          'code': 'x',
          'kind': 'gift',
          'title': 'x',
          'amount_centavos': 100,
        }),
        isNull,
      );
    });

    test('an unknown order status is not treated as paid', () {
      expect(
        PaymentOrder.tryFromJson({
          'id': 'o',
          'status': 'granted',
          'amount_centavos': 100,
        }),
        isNull,
      );
      final order = PaymentOrder.tryFromJson({
        'id': 'o',
        'status': 'pending',
        'amount_centavos': 100,
        'last_failure': 'card_declined',
      })!;
      expect(order.hasFailedAttempt, isTrue);
      expect(order.status.isTerminal, isFalse);
    });

    test('access defaults to none for unusable data', () {
      expect(AccessStatus.fromJson(null).subscriptionActive, isFalse);
      final access = AccessStatus.fromJson({
        'subscription_active': true,
        'subscription_expires_at': '2027-01-01T00:00:00+00:00',
        'mother_notes_owned': true,
      });
      expect(access.subscriptionActive, isTrue);
      expect(access.motherNotesOwned, isTrue);
      expect(access.subscriptionExpiresAt, isNotNull);
    });
  });
}
