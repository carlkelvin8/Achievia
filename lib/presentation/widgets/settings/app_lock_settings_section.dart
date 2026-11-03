import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/data/data_source/auth/biometric_authenticator.dart';
import 'package:achievia/presentation/provider/auth/app_lock_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricAvailabilityProvider =
    FutureProvider.autoDispose<BiometricAvailability>(
      (ref) => ref.watch(biometricAuthenticatorProvider).availability(),
    );

/// Turn the fingerprint / face lock on or off for this account on this phone.
class AppLockSettingsSection extends ConsumerWidget {
  const AppLockSettingsSection({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final controller = ref.read(appLockProvider.notifier);
    final result = on ? await controller.enable() : await controller.disable();
    if (!context.mounted) return;
    switch (result) {
      case AppLockToggleResult.enabled:
        AppToast.showSuccess(context, 'Biometric lock is on.');
      case AppLockToggleResult.disabled:
        AppToast.showInfo(context, 'Biometric lock is off.');
      case AppLockToggleResult.notAvailable:
        AppToast.showError(
          context,
          'This device does not support fingerprint or face unlock.',
        );
      case AppLockToggleResult.notEnrolled:
        AppToast.showWarning(
          context,
          'Add a fingerprint or face in your phone settings first.',
        );
      case AppLockToggleResult.canceled:
        break;
      case AppLockToggleResult.failed:
        AppToast.showError(context, 'We could not verify you. Try again.');
    }
    ref.invalidate(biometricAvailabilityProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLockProvider);
    final availability = ref.watch(biometricAvailabilityProvider).value;

    final String subtitle;
    if (state.enabled) {
      subtitle = 'Locked when you leave the app for 30 seconds or more.';
    } else if (availability == BiometricAvailability.unsupported) {
      subtitle = 'Not available on this device.';
    } else if (availability == BiometricAvailability.notEnrolled) {
      subtitle = 'Add a fingerprint or face in your phone settings first.';
    } else {
      subtitle = 'Ask for your fingerprint or face to open Achievia.';
    }

    // An already enabled lock can always be turned off; turning it on needs
    // a usable biometric.
    final canToggle =
        !state.busy &&
        (state.enabled || availability != BiometricAvailability.unsupported);

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsItem(
            icon: Icons.fingerprint,
            title: 'Biometric lock',
            trailing: Switch(
              key: const ValueKey('app-lock-switch'),
              value: state.enabled,
              onChanged: canToggle ? (on) => _toggle(context, ref, on) : null,
            ),
          ),
          SettingsDescription(
            subtitle,
            key: const ValueKey('app-lock-subtitle'),
          ),
        ],
      ),
    );
  }
}
