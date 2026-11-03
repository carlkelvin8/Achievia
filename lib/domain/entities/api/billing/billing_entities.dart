/// What the app knows about purchases. Prices are integer centavos everywhere;
/// the server owns them and the app only displays them.
library;

enum BillingPlanKind { subscription, motherNotes }

class BillingPlan {
  final String code;
  final BillingPlanKind kind;
  final String title;
  final int amountCentavos;
  final String currency;
  final int? durationMonths;

  const BillingPlan({
    required this.code,
    required this.kind,
    required this.title,
    required this.amountCentavos,
    this.currency = 'PHP',
    this.durationMonths,
  });

  /// Null for rows that are unusable (no price, unknown kind).
  static BillingPlan? tryFromRow(Map<String, dynamic> row) {
    final code = row['code'];
    final title = row['title'];
    final amount = row['amount_centavos'];
    final kind = switch (row['kind']) {
      'subscription' => BillingPlanKind.subscription,
      'mother_notes' => BillingPlanKind.motherNotes,
      _ => null,
    };
    if (code is! String || title is! String || kind == null) return null;
    if (amount is! int || amount <= 0) return null;
    final months = row['duration_months'];
    return BillingPlan(
      code: code,
      kind: kind,
      title: title,
      amountCentavos: amount,
      currency: (row['currency'] ?? 'PHP').toString(),
      durationMonths: months is int ? months : null,
    );
  }
}

enum PaymentOrderStatus { pending, paid, cancelled, expired }

extension PaymentOrderStatusX on PaymentOrderStatus {
  /// No further change is expected from the gateway.
  bool get isTerminal => this != PaymentOrderStatus.pending;
}

class PaymentOrder {
  final String id;
  final String planCode;
  final BillingPlanKind kind;
  final int amountCentavos;
  final PaymentOrderStatus status;

  /// Reason of the latest failed attempt while the order is still pending.
  final String? lastFailure;

  const PaymentOrder({
    required this.id,
    required this.planCode,
    required this.kind,
    required this.amountCentavos,
    required this.status,
    this.lastFailure,
  });

  bool get hasFailedAttempt =>
      status == PaymentOrderStatus.pending &&
      (lastFailure != null && lastFailure!.isNotEmpty);

  static PaymentOrder? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final status = switch (json['status']) {
      'pending' => PaymentOrderStatus.pending,
      'paid' => PaymentOrderStatus.paid,
      'cancelled' => PaymentOrderStatus.cancelled,
      'expired' => PaymentOrderStatus.expired,
      _ => null,
    };
    final kind = json['kind'] == 'mother_notes'
        ? BillingPlanKind.motherNotes
        : BillingPlanKind.subscription;
    final amount = json['amount_centavos'];
    if (id is! String || status == null || amount is! int) return null;
    return PaymentOrder(
      id: id,
      planCode: (json['plan_code'] ?? '').toString(),
      kind: kind,
      amountCentavos: amount,
      status: status,
      lastFailure: json['last_failure']?.toString(),
    );
  }
}

class AccessStatus {
  final bool subscriptionActive;
  final DateTime? subscriptionExpiresAt;
  final bool motherNotesOwned;

  /// Free trial (7 days, once per account, started by the server).
  final bool trialActive;
  final bool trialUsed;
  final DateTime? trialEndsAt;

  const AccessStatus({
    required this.subscriptionActive,
    this.subscriptionExpiresAt,
    required this.motherNotesOwned,
    this.trialActive = false,
    this.trialUsed = false,
    this.trialEndsAt,
  });

  /// Paid subscription or a running trial.
  bool get hasFullAccess => subscriptionActive || trialActive;

  /// The trial can still be started.
  bool get canStartTrial => !trialUsed && !subscriptionActive;

  static const none = AccessStatus(
    subscriptionActive: false,
    motherNotesOwned: false,
  );

  static AccessStatus fromJson(Object? json) {
    if (json is! Map) return none;
    final expires = DateTime.tryParse('${json['subscription_expires_at']}');
    final trialEnds = DateTime.tryParse('${json['trial_ends_at']}');
    return AccessStatus(
      subscriptionActive: json['subscription_active'] == true,
      subscriptionExpiresAt: expires?.toLocal(),
      motherNotesOwned: json['mother_notes_owned'] == true,
      trialActive: json['trial_active'] == true,
      trialUsed: json['trial_used'] == true,
      trialEndsAt: trialEnds?.toLocal(),
    );
  }
}

enum TrialClaimResult { started, alreadyUsed, subscribed }

/// What the Edge Function returns after creating a checkout.
class CheckoutSession {
  final String orderId;
  final Uri checkoutUri;

  const CheckoutSession({required this.orderId, required this.checkoutUri});
}

enum CheckoutFailure {
  notSignedIn,
  planUnavailable,
  alreadyOwned,
  notConfigured,
  invalidResponse,
  network,
}

class CheckoutException implements Exception {
  final CheckoutFailure failure;
  const CheckoutException(this.failure);

  @override
  String toString() => 'CheckoutException($failure)';
}
