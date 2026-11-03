import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A short alert sound. Failures are swallowed: a missing or muted sound must
/// never break the thing that asked for it.
abstract class AlertSound {
  Future<void> play();
}

/// Uses the platform's own notification sound, so it follows the device's
/// volume, silent / vibrate mode and Do Not Disturb settings and needs no
/// bundled audio file.
///
/// Android: the default notification ringtone, through a small native channel
/// (`SystemSound.alert` does nothing on Android). iOS: the system alert sound.
class PlatformAlertSound implements AlertSound {
  static const MethodChannel _channel = MethodChannel('achievia/alert_sound');

  @override
  Future<void> play() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod<void>('playNotification');
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (error) {
      debugPrint('Alert sound unavailable: ${error.runtimeType}');
    }
  }
}
