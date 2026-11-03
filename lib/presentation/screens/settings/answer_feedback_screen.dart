import 'package:achievia/core/utils/answer_feedback.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound and vibration preferences for Study Deck and Take an Exam.
class AnswerFeedbackScreen extends ConsumerWidget {
  const AnswerFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(answerFeedbackProvider);
    final notifier = ref.read(answerFeedbackProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(title: 'Answer Feedback', centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        children: [
          SettingsCard(
            child: SettingsItem(
              icon: Icons.volume_up_outlined,
              title: 'Sounds',
              subtitle: 'Play sounds for correct and incorrect answers',
              trailing: Switch(
                key: const ValueKey('answer-feedback-sounds'),
                value: settings.sounds,
                onChanged: notifier.setSounds,
              ),
            ),
          ),
          SettingsCard(
            child: SettingsItem(
              icon: Icons.vibration,
              title: 'Vibrate',
              subtitle: 'Vibrate when an answer is incorrect',
              trailing: Switch(
                key: const ValueKey('answer-feedback-vibrate'),
                value: settings.vibrate,
                onChanged: notifier.setVibrate,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Applies to Study Deck and Take an Exam. Mock Boards never play '
              'answer sounds or vibrations.',
              key: const ValueKey('answer-feedback-note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
