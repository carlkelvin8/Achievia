import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/settings/settings_group_card.dart';

/// Comfort music section with music toggle switches
class PomodoroComfortMusicSection extends ConsumerWidget {
  const PomodoroComfortMusicSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(pomodoroSettingsProvider);
    final settingsNotifier = ref.read(pomodoroSettingsProvider.notifier);

    return SettingsGroupCard(
      title: 'Comfort music',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pomodoro Music'),
          value: settings.pomodoroMusicEnabled,
          onChanged: (v) => settingsNotifier.togglePomodoroMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Review music'),
          value: settings.reviewMusicEnabled,
          onChanged: (v) => settingsNotifier.toggleReviewMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Break time music'),
          value: settings.breakMusicEnabled,
          onChanged: (v) => settingsNotifier.toggleBreakMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default'),
          value: settings.defaultEnabled,
          onChanged: (v) => settingsNotifier.toggleDefault(v),
        ),
        Text(
          'You can adjust your favorite comfort music and turn on Pomodoro music only if it helps you focus and lessen test anxiety during your study sessions.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
