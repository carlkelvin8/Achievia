import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device output for answer feedback. Failures are swallowed: a missing sound
/// or vibrator must never break answering a question.
abstract class AnswerFeedbackOutput {
  Future<void> playSound({required bool correct});
  Future<void> vibrate();
}

/// Android: short tones and a short vibration through a small native channel.
/// Elsewhere: the system click / alert sound and a haptic pulse.
class PlatformAnswerFeedbackOutput implements AnswerFeedbackOutput {
  static const MethodChannel _channel = MethodChannel('achievia/alert_sound');

  bool get _android => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> playSound({required bool correct}) async {
    try {
      if (_android) {
        await _channel.invokeMethod<void>('playAnswerTone', {
          'correct': correct,
        });
      } else {
        await SystemSound.play(
          correct ? SystemSoundType.click : SystemSoundType.alert,
        );
      }
    } catch (error) {
      debugPrint('Answer sound unavailable: ${error.runtimeType}');
    }
  }

  @override
  Future<void> vibrate() async {
    try {
      if (_android) {
        await _channel.invokeMethod<void>('vibrate', {'ms': 250});
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (error) {
      debugPrint('Vibration unavailable: ${error.runtimeType}');
    }
  }
}

final answerFeedbackOutputProvider = Provider<AnswerFeedbackOutput>(
  (ref) => PlatformAnswerFeedbackOutput(),
);

@immutable
class AnswerFeedbackSettings {
  final bool sounds;
  final bool vibrate;

  const AnswerFeedbackSettings({this.sounds = true, this.vibrate = true});

  AnswerFeedbackSettings copyWith({bool? sounds, bool? vibrate}) =>
      AnswerFeedbackSettings(
        sounds: sounds ?? this.sounds,
        vibrate: vibrate ?? this.vibrate,
      );
}

/// The "Answer Feedback" preferences and the feedback itself.
///
/// Applies to Study Deck and Take an Exam only; Mock Boards never call
/// [onAnswered], whatever the settings are. The two switches are independent:
/// sounds play for correct and incorrect answers, vibration only for an
/// incorrect one. Stored on the device like the other display preferences.
class AnswerFeedbackNotifier extends Notifier<AnswerFeedbackSettings> {
  static const soundsKey = 'answer_feedback_sounds';
  static const vibrateKey = 'answer_feedback_vibrate';

  bool _edited = false;
  Future<void>? _loading;

  @override
  AnswerFeedbackSettings build() {
    _loading = _load();
    return const AnswerFeedbackSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_edited || !ref.mounted) return;
      state = AnswerFeedbackSettings(
        sounds: prefs.getBool(soundsKey) ?? true,
        vibrate: prefs.getBool(vibrateKey) ?? true,
      );
    } catch (error) {
      debugPrint('Unable to load answer feedback settings: $error');
    }
  }

  Future<void> setSounds(bool value) => _set(soundsKey, value, (s) {
    return s.copyWith(sounds: value);
  });

  Future<void> setVibrate(bool value) => _set(vibrateKey, value, (s) {
    return s.copyWith(vibrate: value);
  });

  Future<void> _set(
    String key,
    bool value,
    AnswerFeedbackSettings Function(AnswerFeedbackSettings) update,
  ) async {
    _edited = true;
    state = update(state);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (error) {
      debugPrint('Unable to persist answer feedback setting: $error');
    }
  }

  /// Plays the feedback for one registered answer. Never throws.
  Future<void> onAnswered({required bool correct}) async {
    try {
      await _loading;
      if (!ref.mounted) return;
      final settings = state;
      final output = ref.read(answerFeedbackOutputProvider);
      if (settings.sounds) await output.playSound(correct: correct);
      if (settings.vibrate && !correct) await output.vibrate();
    } catch (error) {
      debugPrint('Answer feedback failed: ${error.runtimeType}');
    }
  }
}

final answerFeedbackProvider =
    NotifierProvider<AnswerFeedbackNotifier, AnswerFeedbackSettings>(
      AnswerFeedbackNotifier.new,
    );
