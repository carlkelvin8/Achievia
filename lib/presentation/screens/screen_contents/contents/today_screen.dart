import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';

import 'package:achievia/domain/entities/widgets/reminder_entity.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late List<ReminderEntity> _todayItems;

  @override
  void initState() {
    super.initState();
    _todayItems = List.from(demoTodayItems);
  }

  void _toggleItem(int index, bool? val) {
    if (val == null) return;
    setState(() {
      _todayItems[index] = _todayItems[index].copyWith(isCompleted: val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90,
        leading: const BackButtonWithLabel(label: 'Tasks'),
        title: Text(
          'Today',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _todayItems.any((item) => item.isCompleted)
                  ? Icons.check_circle
                  : Icons.more_vert,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Handle action (e.g., clear completed)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Achievian Goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayItems.length,
                itemBuilder: (context, index) {
                  final item = _todayItems[index];
                  return ReminderCard(
                    title: item.title,
                    subtitle: item.subtitle,
                    dueDateLabel: item.dueDateLabel,
                    isCompleted: item.isCompleted,
                    onStatusChanged: (val) => _toggleItem(index, val),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
