import 'package:achievia/presentation/widgets/banners/build_banner.dart';
import 'package:achievia/presentation/widgets/cards/question_of_the_day_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/widgets/headers/core/section_label.dart';
import 'package:achievia/presentation/widgets/home/today_goal_section.dart';
import 'package:achievia/presentation/widgets/cards/ranked_profile_card.dart';
import 'package:achievia/presentation/widgets/list_items/horizontal_card_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topMockboards = ref.watch(topMockboardAchieviansProvider);
    final topStudyTime = ref.watch(topStudyTimeAchieviansProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              BuildBanner(),
              const SizedBox(height: 4),
              const MotivationQuoteBanner(),
              const SizedBox(height: 12),
              const SectionLabel(title: 'Question of the day'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const QuestionOfTheDayCard(),
              ),
              const SizedBox(height: 12),
              const SectionLabel(title: "Today's Achievian Goal"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const TodayGoalSection(),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Weekly Achievements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LeaderboardSection(
                title: 'Top 10 Achievians on Mock Boards',
                entries: topMockboards,
              ),
              const SizedBox(height: 8),
              _LeaderboardSection(
                title: 'Top 10 Achievians by Study Time',
                entries: topStudyTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<LeaderboardEntry>> entries;

  const _LeaderboardSection({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title: title),
        entries.when(
          data: (users) {
            if (users.isEmpty) {
              return const _LeaderboardMessage(message: 'No rankings yet');
            }

            return HorizontalCardList(
              // The whole card, plus room for its shadow.
              height: RankedProfileCard.defaultHeight + 8,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
              itemCount: users.length,
              itemBuilder: (context, index) => RankedProfileCard(
                rank: index + 1,
                mockProfile: users[index].profile,
                rankDetail: users[index].detail,
              ),
            );
          },
          loading: () => const _LeaderboardMessage(
            message: 'Loading rankings...',
            showLoader: true,
          ),
          error: (_, __) =>
              const _LeaderboardMessage(message: 'Unable to load rankings'),
        ),
      ],
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  final String message;
  final bool showLoader;

  const _LeaderboardMessage({required this.message, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoader) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
