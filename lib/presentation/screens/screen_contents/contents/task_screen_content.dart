import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/grids/grid_cards.dart';
import 'package:achievia/presentation/widgets/list_items/list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskScreenContent extends ConsumerStatefulWidget {
  const TaskScreenContent({super.key});

  @override
  ConsumerState<TaskScreenContent> createState() => _TaskScreenContentState();
}

class _TaskScreenContentState extends ConsumerState<TaskScreenContent> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final remindersCount = tasksAsync.whenData(
      (tasks) => tasks.where((t) => !t.isDone).length,
    ).value ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridCards(),
              SizedBox(height: 20),
              Text(
                'My Achievian Goal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              ListItemCard(
                icon: Icons.list_alt,
                label: 'Reminders',
                trailingText: '$remindersCount',
                onTap: () {
                  NavigationService.pushNamed(RouteConstants.reminder);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

