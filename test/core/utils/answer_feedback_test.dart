import 'dart:io';

import 'package:achievia/core/utils/answer_feedback.dart';
import 'package:achievia/presentation/screens/settings/answer_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Recorder implements AnswerFeedbackOutput {
  final sounds = <bool>[];
  int vibrations = 0;
  bool throwOnSound = false;

  @override
  Future<void> playSound({required bool correct}) async {
    if (throwOnSound) throw Exception('no audio');
    sounds.add(correct);
  }

  @override
  Future<void> vibrate() async => vibrations++;
}

ProviderContainer containerWith(Recorder out) {
  final c = ProviderContainer(
    overrides: [answerFeedbackOutputProvider.overrideWithValue(out)],
  );
  addTearDown(c.dispose);
  c.listen(answerFeedbackProvider, (_, _) {});
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('feedback rules', () {
    test(
      'both on by default: sound for both, vibration only when wrong',
      () async {
        final out = Recorder();
        final n = containerWith(out).read(answerFeedbackProvider.notifier);
        await n.onAnswered(correct: true);
        expect(out.sounds, [true]);
        expect(out.vibrations, 0);
        await n.onAnswered(correct: false);
        expect(out.sounds, [true, false]);
        expect(out.vibrations, 1);
      },
    );

    test('sounds off keeps vibration working', () async {
      final out = Recorder();
      final n = containerWith(out).read(answerFeedbackProvider.notifier);
      await n.setSounds(false);
      await n.onAnswered(correct: false);
      await n.onAnswered(correct: true);
      expect(out.sounds, isEmpty);
      expect(out.vibrations, 1);
    });

    test('vibrate off keeps sounds working', () async {
      final out = Recorder();
      final n = containerWith(out).read(answerFeedbackProvider.notifier);
      await n.setVibrate(false);
      await n.onAnswered(correct: false);
      expect(out.sounds, [false]);
      expect(out.vibrations, 0);
    });

    test('both off: nothing happens', () async {
      final out = Recorder();
      final n = containerWith(out).read(answerFeedbackProvider.notifier);
      await n.setSounds(false);
      await n.setVibrate(false);
      await n.onAnswered(correct: false);
      expect(out.sounds, isEmpty);
      expect(out.vibrations, 0);
    });

    test('a failing sound never throws', () async {
      final out = Recorder()..throwOnSound = true;
      final n = containerWith(out).read(answerFeedbackProvider.notifier);
      await n.onAnswered(correct: false);
      expect(out.vibrations, 0, reason: 'swallowed, answering is unaffected');
    });
  });

  group('persistence', () {
    test(
      'saved choices are used by the next session, before an answer',
      () async {
        SharedPreferences.setMockInitialValues({
          AnswerFeedbackNotifier.soundsKey: false,
          AnswerFeedbackNotifier.vibrateKey: true,
        });
        final out = Recorder();
        final n = containerWith(out).read(answerFeedbackProvider.notifier);
        // The very first answer already respects the stored settings.
        await n.onAnswered(correct: false);
        expect(out.sounds, isEmpty);
        expect(out.vibrations, 1);
      },
    );

    test('a toggle is stored', () async {
      final out = Recorder();
      final c = containerWith(out);
      await c.read(answerFeedbackProvider.notifier).setVibrate(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AnswerFeedbackNotifier.vibrateKey), isFalse);
      expect(c.read(answerFeedbackProvider).vibrate, isFalse);
    });
  });

  testWidgets('settings screen shows both switches and toggles them', (
    tester,
  ) async {
    final out = Recorder();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [answerFeedbackOutputProvider.overrideWithValue(out)],
        child: const MaterialApp(home: AnswerFeedbackScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sounds'), findsOneWidget);
    expect(find.text('Vibrate'), findsOneWidget);
    Switch sw(String key) => tester.widget<Switch>(find.byKey(ValueKey(key)));
    expect(sw('answer-feedback-sounds').value, isTrue);
    expect(sw('answer-feedback-vibrate').value, isTrue);

    await tester.tap(find.byKey(const ValueKey('answer-feedback-sounds')));
    await tester.pump();
    expect(sw('answer-feedback-sounds').value, isFalse);
    expect(sw('answer-feedback-vibrate').value, isTrue);
  });

  test('Mock Boards never use answer feedback', () {
    for (final path in [
      'lib/presentation/screens/main/exam_screen.dart',
      'lib/core/utils/questions_helpers.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('answer_feedback')), reason: path);
      expect(source, isNot(contains('answerFeedback')), reason: path);
    }
  });
}
