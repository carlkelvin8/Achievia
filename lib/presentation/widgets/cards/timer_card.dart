import 'package:achievia/presentation/widgets/cards/exam_timer_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/cards/timer_display.dart';

/// Timer controls section with Start, Pause, and Reset buttons
class TimerCard extends ConsumerWidget {
  const TimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    return ExamTimerDisplay(
      phaseLabel: notifier.getPhaseLabel(timer.phase),
      timeDisplay: notifier.formatDuration(timer.remaining),
    );
  }
}
