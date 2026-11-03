import 'package:achievia/core/utils/billing_helpers.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Talks to the payment backend. The app never sees PayMongo keys: checkout
/// sessions are created by the `create-checkout` Edge Function and access is
/// granted only by the verified webhook; this class can only read the result.
abstract class BillingRepository {
  Future<List<BillingPlan>> getPlans();
  Future<CheckoutSession> createCheckout(String planCode);
  Future<PaymentOrder?> getOrder(String orderId);
  Future<void> cancelOrder(String orderId);
  Future<AccessStatus> getAccess();
  Future<TrialClaimResult> claimFreeTrial();
}

class SupabaseBillingRepository implements BillingRepository {
  /// A request that never answers must end in an error the screen can show
  /// with a Retry button, not an endless spinner.
  static const _readTimeout = Duration(seconds: 12);
  static const _checkoutTimeout = Duration(seconds: 30);

  final SupabaseClient _client;

  SupabaseBillingRepository(this._client);

  @override
  Future<List<BillingPlan>> getPlans() async {
    final rows = await _client
        .from('billing_plans')
        .select('code, kind, title, amount_centavos, currency, duration_months')
        .order('sort_order')
        .timeout(_readTimeout);
    return [
      for (final row in rows)
        if (BillingPlan.tryFromRow(Map<String, dynamic>.from(row))
            case final plan?)
          plan,
    ];
  }

  @override
  Future<CheckoutSession> createCheckout(String planCode) async {
    final FunctionResponse response;
    try {
      response = await _client.functions
          .invoke('create-checkout', body: {'plan_code': planCode})
          .timeout(_checkoutTimeout);
    } on FunctionException catch (error) {
      throw CheckoutException(_failureFor(error));
    } catch (error) {
      debugPrint('Checkout request failed: ${error.runtimeType}');
      throw const CheckoutException(CheckoutFailure.network);
    }

    final data = response.data;
    if (data is! Map) {
      throw const CheckoutException(CheckoutFailure.invalidResponse);
    }
    final orderId = data['order_id'];
    final uri = safeCheckoutUri(data['checkout_url']);
    if (orderId is! String || uri == null) {
      throw const CheckoutException(CheckoutFailure.invalidResponse);
    }
    return CheckoutSession(orderId: orderId, checkoutUri: uri);
  }

  CheckoutFailure _failureFor(FunctionException error) {
    final details = error.details;
    final code = details is Map ? details['error']?.toString() : null;
    switch (code) {
      case 'unauthorized':
        return CheckoutFailure.notSignedIn;
      case 'plan_unavailable':
      case 'invalid_plan':
        return CheckoutFailure.planUnavailable;
      case 'already_owned':
        return CheckoutFailure.alreadyOwned;
      case 'payments_not_configured':
        return CheckoutFailure.notConfigured;
    }
    if (error.status == 401) return CheckoutFailure.notSignedIn;
    return CheckoutFailure.network;
  }

  @override
  Future<PaymentOrder?> getOrder(String orderId) async {
    final json = await _client
        .rpc('get_my_payment_order', params: {'p_order_id': orderId})
        .timeout(_readTimeout);
    return PaymentOrder.tryFromJson(json);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _client
        .rpc('cancel_my_payment_order', params: {'p_order_id': orderId})
        .timeout(_readTimeout);
  }

  @override
  Future<TrialClaimResult> claimFreeTrial() async {
    final json = await _client.rpc('claim_free_trial').timeout(_readTimeout);
    final status = json is Map ? json['status'] : null;
    switch (status) {
      case 'started':
        return TrialClaimResult.started;
      case 'subscribed':
        return TrialClaimResult.subscribed;
      case 'already_used':
        return TrialClaimResult.alreadyUsed;
    }
    throw StateError('Unexpected trial response');
  }

  @override
  Future<AccessStatus> getAccess() async {
    final json = await _client.rpc('get_my_access').timeout(_readTimeout);
    return AccessStatus.fromJson(json);
  }
}
