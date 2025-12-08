import 'package:achievia/core/utils/formatters.dart';
import 'package:achievia/presentation/widgets/banners/build_banner.dart';
import 'package:achievia/presentation/widgets/cards/question_of_the_day_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';

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
              const SizedBox(height: 12),
              const _SectionLabel(title: 'Question of the day'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: QuestionOfTheDayCard(selectedIndex: qotd.selectedIndex,),
              ),
              const SizedBox(height: 12),
              const _SectionLabel(title: "Today's Achievian Goal"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTodaysGoal(
                  context,
                  ref,
                  goal.date,
                  goal.title,
                  goal.details,
                  goal.isChecked,
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
              _buildTopListTitle(context, 'Top 10 Achievans on Mock Boards'),
              _buildHorizontalCards(context),
              const SizedBox(height: 8),
              _buildTopListTitle(context, "July's Top 10 Streak Achievans"),
              _buildHorizontalCards(context),
            ],
          ),
        ),
      ),
    );
  }


  // Today's goal card
  Widget _buildTodaysGoal(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    String title,
    String details,
    bool isChecked,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                Formatters().formatDate(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: isChecked,
            onChanged: (_) => ref.read(goalProvider.notifier).toggleChecked(),
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTopListTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Horizontal list showing compact ProfileStatusCard with rank badge
  Widget _buildHorizontalCards(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 260,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 360,
                          child: const ProfileStatusCard(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 6,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
