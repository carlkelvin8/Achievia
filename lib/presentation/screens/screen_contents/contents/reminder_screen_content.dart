import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/domain/entities/widgets/reminder_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';

class ReminderScreenContent extends ConsumerStatefulWidget {
  const ReminderScreenContent({super.key});

  @override
  ConsumerState<ReminderScreenContent> createState() =>
      _ReminderScreenContentState();
}

class _ReminderScreenContentState extends ConsumerState<ReminderScreenContent> {
  late List<ReminderEntity> _reminders;

  @override
  void initState() {
    super.initState();
    // Initialize with demo data
    _reminders = List.from(demoReminderItems);
  }

  void _toggleReminder(int index, bool? value) {
    if (value == null) return;
    setState(() {
      _reminders[index] = _reminders[index].copyWith(isCompleted: value);
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
          'Reminders',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
            onPressed: () {
              // TODO: Show menu options
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final item = _reminders[index];
                  return ReminderCard(
                    title: item.title,
                    subtitle: item.subtitle,
                    dueDateLabel: item.dueDateLabel,
                    isCompleted: item.isCompleted,
                    onStatusChanged: (value) => _toggleReminder(index, value),
                    onTap: () {
                      // TODO: Navigate to reminder detail screen
                    },
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

// Demo items moved to helpers.dart: demoReminderItems
