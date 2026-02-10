import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/cards/reusable_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GridCards extends ConsumerWidget {
  const GridCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReminder(context),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: reminders.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ReusableCard(
              icon: reminder.icon,
              label: reminder.title,
              count: int.tryParse(reminder.status) ?? 0,
              onTap: () {
                if (index == 0) {
                  NavigationService.pushNamed(RouteConstants.today);
                } else if (index == 1) {
                  NavigationService.pushNamed(RouteConstants.scheduled);
                } else if (index == 2) {
                  NavigationService.pushNamed(RouteConstants.completed);
                }
              },
            );
          },
        ),
      ],
    );
  }
}

Widget _buildReminder(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;

  return InkWell(
    onTap: () {
      NavigationService.pushNamed(RouteConstants.newReminder);
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
