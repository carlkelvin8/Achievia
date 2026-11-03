import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Can this device protect the app with a fingerprint / face?
enum BiometricAvailability {
  /// Biometrics are enrolled and usable.
  available,

  /// The device supports it, but the user has not enrolled any biometric.
  notEnrolled,

  /// No biometric hardware, or no secure lock screen at all.
  unsupported,
}

enum BiometricOutcome {
  success,

  /// The check ran and did not match / was refused.
  failed,

  /// The user closed the prompt.
  canceled,

  /// Too many wrong attempts; the system blocks biometrics for a while.
  lockedOut,

  /// Nothing to authenticate with (nothing enrolled, no hardware).
  unavailable,

  error,
}

abstract class BiometricAuthenticator {
  Future<BiometricAvailability> availability();
  Future<BiometricOutcome> authenticate(String reason);
}

/// Real implementation on top of the platform biometric prompt. The check
/// happens in the operating system; the app only learns pass or fail.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  final LocalAuthentication _auth;
  LocalAuthBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  @override
  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return BiometricAvailability.unsupported;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.available;
    } catch (error) {
      debugPrint('Biometric availability check failed: ${error.runtimeType}');
      return BiometricAvailability.unsupported;
    }
  }

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // The device PIN / pattern stays available as the system fallback, so
        // a worn-out fingerprint sensor never strands the user.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.failed;
    } on LocalAuthException catch (error) {
      switch (error.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
        case LocalAuthExceptionCode.systemCanceled:
          return BiometricOutcome.canceled;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricOutcome.lockedOut;
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricOutcome.unavailable;
        default:
          return BiometricOutcome.error;
      }
    } catch (error) {
      debugPrint('Biometric prompt failed: ${error.runtimeType}');
      return BiometricOutcome.error;
    }
  }
}
