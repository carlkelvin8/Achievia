import 'package:achievia/core/constants/routers/route_constants.dart';

/// Pure helpers for two-factor authentication (TOTP, authenticator app).

final _sixDigits = RegExp(r'^\d{6}$');

/// Authenticator codes are exactly six digits. Spaces typed by the user
/// ("123 456") are removed before checking.
String normalizeTotpCode(String input) => input.replaceAll(RegExp(r'\s+'), '');

bool isValidTotpCode(String input) =>
    _sixDigits.hasMatch(normalizeTotpCode(input));

/// "JBSWY3DPEHPK3PXP" -> "JBSW Y3DP EHPK 3PXP" so it is easy to type by hand.
String formatTotpSecret(String secret) {
  final clean = secret.replaceAll(RegExp(r'\s+'), '');
  final groups = <String>[];
  for (var i = 0; i < clean.length; i += 4) {
    groups.add(clean.substring(i, i + 4 > clean.length ? clean.length : i + 4));
  }
  return groups.join(' ');
}

/// Supabase returns the QR code as `data:image/svg+xml;utf-8,<svg ...>`.
/// Returns the SVG markup, or null when the value is not a usable SVG.
String? qrSvgFromEnrollment(String qrCode) {
  const prefix = 'data:image/svg+xml;utf-8,';
  var svg = qrCode.startsWith(prefix)
      ? qrCode.substring(prefix.length)
      : qrCode;
  svg = svg.trim();
  if (!svg.startsWith('<svg') && !svg.startsWith('<?xml')) {
    // Percent-encoded variant.
    try {
      final decoded = Uri.decodeFull(svg).trim();
      if (decoded.startsWith('<svg') || decoded.startsWith('<?xml')) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }
  return svg;
}

/// Where the router must send a signed-in user because of MFA.
///
/// A user who enrolled an authenticator app must prove it on every new login:
/// until the session reaches the second level (aal2) every route except the
/// code screen redirects there, and a user who does not need it never sees
/// that screen.
String? mfaRedirect({
  required bool isLoggedIn,
  required bool challengeRequired,
  required String location,
}) {
  if (!isLoggedIn) return null;
  if (challengeRequired) {
    return location == RouteConstants.mfaVerify
        ? null
        : RouteConstants.mfaVerify;
  }
  return location == RouteConstants.mfaVerify ? RouteConstants.main : null;
}

/// First level reached, second level available but not yet verified.
bool challengeRequiredFor({
  required String? currentLevel,
  required String? nextLevel,
}) => currentLevel == 'aal1' && nextLevel == 'aal2';
