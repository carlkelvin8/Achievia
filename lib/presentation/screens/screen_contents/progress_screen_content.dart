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
    final progressAsync = ref.watch(progressProvider);
    final gradingBrackets = ref.watch(gradingBracketsProvider);

    final progress = progressAsync.value;
    final isLoading = progressAsync.isLoading && progressAsync.value == null;
    final hasError = progressAsync.hasError && progressAsync.value == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Unable to fetch latest progress. Showing fallback data.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    if (progress == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No progress data is available yet.'),
                      ),
                    if (progress != null) ...[
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
                  ],
                ),
        ),
      ),
    );
  }
}
