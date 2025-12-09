import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/cards/info_card.dart';
import 'package:achievia/presentation/widgets/cards/timer_display.dart';
import 'package:achievia/presentation/widgets/settings/setting_tile.dart';
import 'package:achievia/presentation/widgets/settings/settings_group_card.dart';

class PomodoroTimerScreen extends ConsumerWidget {
  const PomodoroTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timer = ref.watch(pomodoroProvider);
    final settings = ref.watch(pomodoroSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                icon: Icons.timer,
                title: 'Pomodoro Timer',
                description:
                    'Pomodoro Timer is a time-management tool that helps break your study into focused sessions with short breaks in between.',
              ),
              const SizedBox(height: 16),
              _buildTimerCard(theme, timer, ref),
              const SizedBox(height: 16),
              _buildCustomizeCard(theme, ref, settings),
              const SizedBox(height: 16),
              _buildComfortMusicCard(theme, ref, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(ThemeData theme, dynamic timer, WidgetRef ref) {
    final notifier = ref.read(pomodoroProvider.notifier);
    return TimerDisplay(
      phaseLabel: notifier.getPhaseLabel(timer.phase),
      timeDisplay: notifier.formatDuration(timer.remaining),
      actions: [
        FilledButton(
          onPressed: () => ref.read(pomodoroProvider.notifier).start(),
          child: const Text('Start'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => ref.read(pomodoroProvider.notifier).pause(),
          child: const Text('Pause'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => ref.read(pomodoroProvider.notifier).reset(),
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildCustomizeCard(ThemeData theme, WidgetRef ref, dynamic settings) {
    return SettingsGroupCard(
      title: 'Customize',
      children: [
        SettingTile(
          label: 'Review duration',
          valueLabel: '${settings.focusDuration.inMinutes} mins',
          onTap: () => _editValue(
            context: ref.context,
            title: 'Review duration (mins)',
            initial: settings.focusDuration.inMinutes,
            min: 1,
            max: 180,
            onSubmit: (v) => ref
                .read(pomodoroSettingsProvider.notifier)
                .setFocusMinutes(v),
          ),
          onDecrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setFocusMinutes(
                (settings.focusDuration.inMinutes - 5).clamp(5, 120),
              ),
          onIncrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setFocusMinutes(
                (settings.focusDuration.inMinutes + 5).clamp(5, 120),
              ),
        ),
        SettingTile(
          label: 'Short break duration',
          valueLabel: '${settings.shortBreakDuration.inMinutes} mins',
          onTap: () => _editValue(
            context: ref.context,
            title: 'Short break (mins)',
            initial: settings.shortBreakDuration.inMinutes,
            min: 1,
            max: 60,
            onSubmit: (v) => ref
                .read(pomodoroSettingsProvider.notifier)
                .setShortBreakMinutes(v),
          ),
          onDecrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setShortBreakMinutes(
                (settings.shortBreakDuration.inMinutes - 1).clamp(1, 60),
              ),
          onIncrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setShortBreakMinutes(
                (settings.shortBreakDuration.inMinutes + 1).clamp(1, 60),
              ),
        ),
        SettingTile(
          label: 'Long break duration',
          valueLabel: '${settings.longBreakDuration.inMinutes} mins',
          onTap: () => _editValue(
            context: ref.context,
            title: 'Long break (mins)',
            initial: settings.longBreakDuration.inMinutes,
            min: 5,
            max: 180,
            onSubmit: (v) => ref
                .read(pomodoroSettingsProvider.notifier)
                .setLongBreakMinutes(v),
          ),
          onDecrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setLongBreakMinutes(
                (settings.longBreakDuration.inMinutes - 5).clamp(5, 120),
              ),
          onIncrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setLongBreakMinutes(
                (settings.longBreakDuration.inMinutes + 5).clamp(5, 120),
              ),
        ),
        SettingTile(
          label: 'Sessions before long break',
          valueLabel: '${settings.sessionsBeforeLongBreak} sessions',
          onTap: () => _editValue(
            context: ref.context,
            title: 'Sessions before long break',
            initial: settings.sessionsBeforeLongBreak,
            min: 1,
            max: 10,
            onSubmit: (v) => ref
                .read(pomodoroSettingsProvider.notifier)
                .setSessionsBeforeLong(v),
          ),
          onDecrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setSessionsBeforeLong(
                (settings.sessionsBeforeLongBreak - 1).clamp(1, 10),
              ),
          onIncrement: () => ref
              .read(pomodoroSettingsProvider.notifier)
              .setSessionsBeforeLong(
                (settings.sessionsBeforeLongBreak + 1).clamp(1, 10),
              ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default'),
          value: settings.defaultEnabled,
          onChanged: (v) =>
              ref.read(pomodoroSettingsProvider.notifier).toggleDefault(v),
        ),
      ],
    );
  }

  Widget _buildComfortMusicCard(ThemeData theme, WidgetRef ref, dynamic settings) {
    return SettingsGroupCard(
      title: 'Comfort music',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pomodoro Music'),
          value: settings.pomodoroMusicEnabled,
          onChanged: (v) => ref
              .read(pomodoroSettingsProvider.notifier)
              .togglePomodoroMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Review music'),
          value: settings.reviewMusicEnabled,
          onChanged: (v) => ref
              .read(pomodoroSettingsProvider.notifier)
              .toggleReviewMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Break time music'),
          value: settings.breakMusicEnabled,
          onChanged: (v) => ref
              .read(pomodoroSettingsProvider.notifier)
              .toggleBreakMusic(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default'),
          value: settings.defaultEnabled,
          onChanged: (v) =>
              ref.read(pomodoroSettingsProvider.notifier).toggleDefault(v),
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

  Future<void> _editValue({
    required BuildContext context,
    required String title,
    required int initial,
    required int min,
    required int max,
    required void Function(int) onSubmit,
  }) async {
    final controller = TextEditingController(text: initial.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Enter a value'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null) {
                Navigator.of(context).pop();
                return;
              }
              final clamped = parsed.clamp(min, max);
              Navigator.of(context).pop(clamped);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) {
      onSubmit(value);
    }
  }
}
