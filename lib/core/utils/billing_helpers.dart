import 'package:achievia/domain/entities/api/billing/billing_entities.dart';
import 'package:intl/intl.dart';

/// "₱299", "₱1,699" or "₱299.50": integer centavos in, no floating point.
String formatPesoFromCentavos(int centavos) {
  final negative = centavos < 0;
  final abs = centavos.abs();
  final pesos = abs ~/ 100;
  final cents = abs % 100;
  final whole = NumberFormat.decimalPattern('en_US').format(pesos);
  final text = cents == 0
      ? '₱$whole'
      : '₱$whole.${cents.toString().padLeft(2, '0')}';
  return negative ? '-$text' : text;
}

String subscriptionLength(int? months) {
  if (months == null) return '';
  return months == 1 ? '1 month' : '$months months';
}

/// Accepts only an https checkout page. Anything else (a custom scheme, a
/// relative link, an empty string) is refused before it reaches the browser.
Uri? safeCheckoutUri(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

/// `achievia://callback?payment=success&order=<uuid>` (or `cancelled`).
class PaymentReturn {
  final String orderId;
  final bool cancelled;
  const PaymentReturn({required this.orderId, required this.cancelled});
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Returns the order a checkout redirect refers to, or null when [uri] is not
/// a payment return. The result is only a pointer to a status screen: access
/// is never decided from a redirect.
PaymentReturn? parsePaymentReturn(Uri uri) {
  final result = uri.queryParameters['payment'];
  final order = uri.queryParameters['order'];
  if (result != 'success' && result != 'cancelled') return null;
  if (order == null || !_uuid.hasMatch(order)) return null;
  return PaymentReturn(orderId: order, cancelled: result == 'cancelled');
}

/// Whole days left, rounded up ("1 day left" until it actually ends).
int daysLeftUntil(DateTime end, DateTime now) {
  final remaining = end.difference(now);
  if (remaining.isNegative || remaining == Duration.zero) return 0;
  return (remaining.inHours + 23) ~/ 24;
}

String describeTrial(AccessStatus access, DateTime now) {
  final ends = access.trialEndsAt;
  if (access.trialActive && ends != null) {
    final days = daysLeftUntil(ends, now);
    final label = days == 1 ? '1 day left' : '$days days left';
    return 'Free trial: $label (until ${DateFormat('MMMM d, yyyy').format(ends)})';
  }
  if (access.trialUsed) return 'Free trial ended';
  return '';
}

String describeAccess(AccessStatus access) {
  final expires = access.subscriptionExpiresAt;
  if (access.subscriptionActive && expires != null) {
    return 'Active until ${DateFormat('MMMM d, yyyy').format(expires)}';
  }
  if (expires != null) {
    return 'Expired on ${DateFormat('MMMM d, yyyy').format(expires)}';
  }
  return 'No active subscription';
}
