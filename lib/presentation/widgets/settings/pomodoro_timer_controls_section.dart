import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/cards/timer_display.dart';

/// Timer controls section with Start, Pause, and Reset buttons
class PomodoroTimerControlsSection extends ConsumerWidget {
  const PomodoroTimerControlsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    return TimerDisplay(
      phaseLabel: notifier.getPhaseLabel(timer.phase),
      timeDisplay: notifier.formatDuration(timer.remaining),
      actions: [
        FilledButton(
          onPressed: () => notifier.start(),
          child: const Text('Start'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => notifier.pause(),
          child: const Text('Pause'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => notifier.reset(),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
