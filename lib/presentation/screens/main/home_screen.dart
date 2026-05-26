import 'package:achievia/core/utils/formatters.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/banners/build_banner.dart';
import 'package:achievia/presentation/widgets/cards/question_of_the_day_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/widgets/headers/section_label.dart';
import 'package:achievia/presentation/widgets/cards/goal_card.dart';
import 'package:achievia/presentation/widgets/cards/ranked_profile_card.dart';
import 'package:achievia/presentation/widgets/list_items/horizontal_card_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qotd = ref.watch(qotdProvider);
    final goal = ref.watch(goalProvider);

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
                child: QuestionOfTheDayCard(selectedIndex: qotd.selectedIndex),
              ),
              const SizedBox(height: 12),
              const SectionLabel(title: "Today's Achievian Goal"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GoalCard(
                  date: Formatters().formatDate(goal.date),
                  title: goal.title,
                  details: goal.details,
                  isChecked: goal.isChecked,
                  onToggle: () =>
                      ref.read(goalProvider.notifier).toggleChecked(),
                ),
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
              const SectionLabel(title: 'Top 10 Achievans on Mock Boards'),
              HorizontalCardList(
                itemCount: mockTopAchievians.length,
                itemBuilder: (context, index) => RankedProfileCard(
                  rank: index + 1,
                  mockProfile: mockTopAchievians[index],
                ),
              ),
              const SizedBox(height: 8),
              const SectionLabel(title: "July's Top 10 Streak Achievans"),
              HorizontalCardList(
                itemCount: mockTopStreakAchievians.length,
                itemBuilder: (context, index) => RankedProfileCard(
                  rank: index + 1,
                  mockProfile: mockTopStreakAchievians[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
