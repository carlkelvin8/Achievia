import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/progress/progress_provider.dart';
import 'package:achievia/presentation/widgets/progress/calendar_card.dart';
import 'package:achievia/presentation/widgets/progress/grading_bracket_table.dart';
import 'package:achievia/presentation/widgets/progress/score_graph_card.dart';
import 'package:achievia/presentation/widgets/progress/screentime_card.dart';
import 'package:achievia/presentation/widgets/progress/strength_weakness_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressScreenContent extends ConsumerWidget {
  const ProgressScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider);
    final gradingBrackets = ref.watch(gradingBracketsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Section
              CalendarCard(calendarData: progress.calendarData),
              const SizedBox(height: 20),

              // Grading Bracket Table
              GradingBracketTable(brackets: gradingBrackets),
              const SizedBox(height: 20),

              // Strength and Weakness Section
              StrengthWeaknessCard(data: progress.strengthWeakness),
              const SizedBox(height: 20),

              // Score Percentage Graph
              ScoreGraphCard(progress: progress),
              const SizedBox(height: 20),

              // Daily Screentime Section
              ScreentimeCard(data: progress.screentimeData),
            ],
          ),
        ),
      ),
    );
  }
}
