import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/cards/reusable_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GridCards extends ConsumerWidget {
  const GridCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayCount = 0;
    int scheduledCount = 0;
    int completedCount = 0;

    tasksAsync.whenData((tasks) {
      for (final t in tasks) {
        if (t.isDone) {
          completedCount++;
        } else {
          final d = t.deadline.toLocal();
          final deadlineDay = DateTime(d.year, d.month, d.day);
          if (deadlineDay == today) {
            todayCount++;
          } else if (deadlineDay.isAfter(today)) {
            scheduledCount++;
          }
        }
      }
    });

    final cards = [
      _CardData(
        icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
        label: 'Today',
        count: todayCount,
        route: RouteConstants.today,
      ),
      _CardData(
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: 'Scheduled',
        count: scheduledCount,
        route: RouteConstants.scheduled,
      ),
      _CardData(
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: 'Completed',
        count: completedCount,
        route: RouteConstants.completed,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReminder(context),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return ReusableCard(
              icon: card.icon,
              label: card.label,
              count: card.count,
              onTap: () => context.push(card.route),
            );
          },
        ),
      ],
    );
  }
}

class _CardData {
  final Widget icon;
  final String label;
  final int count;
  final String route;
  const _CardData({
    required this.icon,
    required this.label,
    required this.count,
    required this.route,
  });
}

Widget _buildReminder(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;

  return InkWell(
    onTap: () {
      context.push(RouteConstants.newReminder);
    },
    child: Row(
      children: [
        Icon(Icons.add_box, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          'New Reminder',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
