import 'package:achievia/presentation/widgets/cards/exam_timer_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
/// Timer controls section with Start, Pause, and Reset buttons
class TimerCard extends ConsumerWidget {
  const TimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);

    return ExamTimerDisplay(
      phaseLabel: notifier.getPhaseLabel(timer.phase),
      timeDisplay: notifier.formatDuration(timer.remaining),
    );
  }
}
