import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/progress/progress_provider.dart';
import 'package:achievia/presentation/widgets/progress/calendar_card.dart';
import 'package:achievia/presentation/widgets/progress/grading_bracket_table.dart';
import 'package:achievia/presentation/widgets/progress/score_graph_card.dart';
import 'package:achievia/presentation/widgets/progress/screentime_card.dart';
import 'package:achievia/presentation/widgets/progress/strength_weakness_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/progress/screentime_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';

class ProgressScreenContent extends ConsumerWidget {
  const ProgressScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(progressProvider);
    final screentime = ref.watch(screentimeProvider);
    final today = ref.watch(localDayProvider);
    final dateKey = today.toIso8601String().split('T').first;

    final progress = progressAsync.value;
    final isLoading = progressAsync.isLoading && progressAsync.value == null;
    final hasError = progressAsync.hasError && progressAsync.value == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(progressProvider);
          try {
            await ref.read(progressProvider.future);
          } catch (e) {
            debugPrint('Progress refresh failed: $e');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Unable to load quiz progress. Pull down to retry.',
                          ),
                        ),
                      if (progress == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No progress data is available yet.'),
                        ),
                      if (progress != null) ...[
                        // Strength and Weakness Section
                        StrengthWeaknessCard(data: progress.strengthWeakness),
                        const SizedBox(height: 20),

                        // Score Percentage Graph
                        ScoreGraphCard(progress: progress),
                        const SizedBox(height: 20),

                        // Daily Screentime Section
                        screentime.when(
                          data: (seconds) => ScreentimeCard(
                            data: screentimeFromSeconds(seconds),
                            todaySeconds: seconds[dateKey] ?? 0,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const Text(
                            'Unable to load screentime on this device.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        CalendarCard(calendarData: progress.calendarData),
                        const SizedBox(height: 20),
                        GradingBracketTable(
                          brackets: ref.watch(gradingBracketsProvider),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
