import 'package:achievia/data/data_source/billing/billing_remote_datasource.dart';
import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => SupabaseBillingRepository(Supabase.instance.client),
);

/// How the hosted checkout page is opened (overridden in tests).
final checkoutLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Gap between two status checks of the "Payment processing" screen.
final paymentPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

final billingPlansProvider = FutureProvider.autoDispose<List<BillingPlan>>(
  (ref) => ref.watch(billingRepositoryProvider).getPlans(),
);

/// Server-verified access. Only the webhook can change it.
final accessStatusProvider = FutureProvider<AccessStatus>(
  (ref) => ref.watch(billingRepositoryProvider).getAccess(),
);

/// Polls one order until the backend reports a final state. The status comes
/// from the database row that the verified webhook updates; the checkout
/// redirect is never trusted.
final paymentOrderStatusProvider = StreamProvider.autoDispose
    .family<PaymentOrder?, String>((ref, orderId) async* {
      final repository = ref.watch(billingRepositoryProvider);
      final interval = ref.watch(paymentPollIntervalProvider);
      var attempt = 0;
      while (true) {
        PaymentOrder? order;
        try {
          order = await repository.getOrder(orderId);
        } catch (_) {
          // A transient error keeps polling; the screen keeps its last state.
          order = null;
          if (attempt == 0) rethrow;
        }
        if (order != null) {
          yield order;
          if (order.status.isTerminal) {
            if (order.status == PaymentOrderStatus.paid) {
              ref.invalidate(accessStatusProvider);
            }
            return;
          }
        }
        attempt++;
        // Back off once the first minute has passed.
        await Future<void>.delayed(attempt < 20 ? interval : interval * 3);
        // The screen was left while waiting: stop polling.
        if (!ref.mounted) return;
      }
    });

class CheckoutState {
  final bool busy;
  final CheckoutFailure? failure;
  final String? pendingPlanCode;

  const CheckoutState({this.busy = false, this.failure, this.pendingPlanCode});
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Creates the checkout on the backend, opens it, and returns the order id
  /// to follow, or null when something failed (see [state]).
  Future<String?> start(String planCode) async {
    if (state.busy) return null;
    state = CheckoutState(busy: true, pendingPlanCode: planCode);
    try {
      final session = await ref
          .read(billingRepositoryProvider)
          .createCheckout(planCode);
      final opened = await ref.read(checkoutLauncherProvider)(
        session.checkoutUri,
      );
      if (!opened) {
        state = const CheckoutState(failure: CheckoutFailure.network);
        return null;
      }
      state = const CheckoutState();
      return session.orderId;
    } on CheckoutException catch (error) {
      state = CheckoutState(failure: error.failure);
      return null;
    } catch (_) {
      state = const CheckoutState(failure: CheckoutFailure.network);
      return null;
    }
  }

  void clearFailure() => state = const CheckoutState();
}

/// Starts the one-time 7-day trial. The server decides everything (start,
/// end, whether it was already used); the app only asks and then re-reads the
/// access status.
class TrialController extends Notifier<bool> {
  @override
  bool build() => false; // busy

  /// Null when the request failed.
  Future<TrialClaimResult?> claim() async {
    if (state) return null;
    state = true;
    try {
      final result = await ref.read(billingRepositoryProvider).claimFreeTrial();
      ref.invalidate(accessStatusProvider);
      return result;
    } catch (_) {
      return null;
    } finally {
      state = false;
    }
  }
}

final trialControllerProvider = NotifierProvider<TrialController, bool>(
  TrialController.new,
);

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
