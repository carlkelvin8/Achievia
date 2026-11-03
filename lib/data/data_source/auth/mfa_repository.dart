import 'package:achievia/core/utils/mfa_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MfaFailure {
  invalidCode,
  rateLimited,
  recentLoginRequired,
  network,
  unknown,
}

class MfaException implements Exception {
  final MfaFailure failure;
  const MfaException(this.failure);

  @override
  String toString() => 'MfaException($failure)';
}

class MfaEnrollment {
  final String factorId;

  /// SVG markup of the QR code, or null if it could not be read (the
  /// [secret] can still be typed into the authenticator app).
  final String? qrSvg;
  final String secret;

  const MfaEnrollment({
    required this.factorId,
    required this.qrSvg,
    required this.secret,
  });
}

/// Two-factor authentication through an authenticator app (TOTP), handled by
/// Supabase Auth: the secret never leaves Supabase and the app only ever
/// sends six-digit codes.
abstract class MfaRepository {
  /// Id of the verified authenticator factor, or null when MFA is off.
  Future<String?> verifiedFactorId();

  /// Starts enrolling an authenticator app (removes abandoned attempts).
  Future<MfaEnrollment> beginEnrollment();

  /// Activates the factor with a code from the authenticator app.
  Future<void> confirmEnrollment({
    required String factorId,
    required String code,
  });

  /// Throws away an enrollment that was not confirmed.
  Future<void> cancelEnrollment(String factorId);

  /// Proves the second factor for the current session (login step).
  Future<void> verifyLogin(String code);

  /// Turns MFA off. Needs a session that already passed the second factor.
  Future<void> disable(String factorId);
}

class SupabaseMfaRepository implements MfaRepository {
  final SupabaseClient _client;
  SupabaseMfaRepository(this._client);

  GoTrueMFAApi get _mfa => _client.auth.mfa;

  @override
  Future<String?> verifiedFactorId() async {
    final factors = await _guard(_mfa.listFactors);
    return factors.totp.isEmpty ? null : factors.totp.first.id;
  }

  @override
  Future<MfaEnrollment> beginEnrollment() async {
    final factors = await _guard(_mfa.listFactors);
    // Abandoned, never-confirmed attempts would otherwise pile up.
    for (final factor in factors.all) {
      if (factor.factorType == FactorType.totp &&
          factor.status != FactorStatus.verified) {
        await _guard(() => _mfa.unenroll(factor.id));
      }
    }
    final response = await _guard(
      () => _mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Achievia',
        friendlyName: 'Achievia ${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    final totp = response.totp;
    if (totp == null) throw const MfaException(MfaFailure.unknown);
    return MfaEnrollment(
      factorId: response.id,
      qrSvg: qrSvgFromEnrollment(totp.qrCode),
      secret: totp.secret,
    );
  }

  @override
  Future<void> confirmEnrollment({
    required String factorId,
    required String code,
  }) async {
    await _guard(
      () => _mfa.challengeAndVerify(
        factorId: factorId,
        code: normalizeTotpCode(code),
      ),
    );
  }

  @override
  Future<void> cancelEnrollment(String factorId) async {
    try {
      await _mfa.unenroll(factorId);
    } catch (error) {
      debugPrint('MFA enrollment cleanup failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> verifyLogin(String code) async {
    final factorId = await verifiedFactorId();
    if (factorId == null) throw const MfaException(MfaFailure.unknown);
    await _guard(
      () => _mfa.challengeAndVerify(
        factorId: factorId,
        code: normalizeTotpCode(code),
      ),
    );
  }

  @override
  Future<void> disable(String factorId) async {
    await _guard(() => _mfa.unenroll(factorId));
    // Refresh so the session no longer asks for a second factor.
    await _guard(_client.auth.refreshSession);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      throw MfaException(_failureFor(error));
    } catch (_) {
      throw const MfaException(MfaFailure.network);
    }
  }

  MfaFailure _failureFor(AuthException error) {
    final code = error.code;
    final status = error.statusCode;
    if (code == 'mfa_verification_failed' ||
        code == 'mfa_challenge_expired' ||
        code == 'validation_failed') {
      return MfaFailure.invalidCode;
    }
    if (status == '429' || code == 'over_request_rate_limit') {
      return MfaFailure.rateLimited;
    }
    if (code == 'insufficient_aal' || code == 'reauthentication_needed') {
      return MfaFailure.recentLoginRequired;
    }
    final message = error.message.toLowerCase();
    if (message.contains('invalid') && message.contains('code')) {
      return MfaFailure.invalidCode;
    }
    return MfaFailure.unknown;
  }
}
