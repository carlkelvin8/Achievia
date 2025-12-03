import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_state_entity.dart';

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
              _HeaderCard(theme: theme),
              const SizedBox(height: 16),
              _TimerCard(theme: theme, timer: timer, ref: ref),
              const SizedBox(height: 16),
              _CustomizeCard(theme: theme, ref: ref, settings: settings),
              const SizedBox(height: 16),
              _ComfortMusicCard(theme: theme, ref: ref, settings: settings),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ThemeData theme;
  const _HeaderCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'Pomodoro Timer',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pomodoro Timer is a time-management tool that helps break your study into focused sessions with short breaks in between.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final ThemeData theme;
  final dynamic timer; // PomodoroStateEntity
  final WidgetRef ref;

  const _TimerCard({
    required this.theme,
    required this.timer,
    required this.ref,
  });

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) {
      return '${hh.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  String _phaseLabel(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            _phaseLabel(timer.phase),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _format(timer.remaining),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          ),
        ],
      ),
    );
  }
}

class _CustomizeCard extends ConsumerWidget {
  final ThemeData theme;
  final dynamic settings; // PomodoroSettingsEntity
  final WidgetRef ref;
  const _CustomizeCard({
    required this.theme,
    required this.ref,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SettingTile(
            label: 'Review duration',
            valueLabel: '${settings.focusDuration.inMinutes} mins',
            onTap: () => _editValue(
              context: context,
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
          _SettingTile(
            label: 'Short break duration',
            valueLabel: '${settings.shortBreakDuration.inMinutes} mins',
            onTap: () => _editValue(
              context: context,
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
          _SettingTile(
            label: 'Long break duration',
            valueLabel: '${settings.longBreakDuration.inMinutes} mins',
            onTap: () => _editValue(
              context: context,
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
          _SettingTile(
            label: 'Sessions before long break',
            valueLabel: '${settings.sessionsBeforeLongBreak} sessions',
            onTap: () => _editValue(
              context: context,
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
      ),
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

class _ComfortMusicCard extends ConsumerWidget {
  final ThemeData theme;
  final dynamic settings; // PomodoroSettingsEntity
  final WidgetRef ref;
  const _ComfortMusicCard({
    required this.theme,
    required this.ref,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comfort music',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
            onChanged: (v) =>
                ref.read(pomodoroSettingsProvider.notifier).toggleBreakMusic(v),
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
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTap;
  const _SettingTile({
    required this.label,
    required this.valueLabel,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          SizedBox(
            width: 150,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          valueLabel,
                          style: theme.textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    _RoundIconButton(icon: Icons.add, onPressed: onIncrement),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
