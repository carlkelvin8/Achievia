import 'package:achievia/core/constants/app_paddings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';

class ReminderScreenContent extends ConsumerWidget {
  const ReminderScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = demoReminderItems; // Replace with provider-backed list when ready

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
              ...items.map(
                (item) => ReminderCard(
                  title: item.title,
                  subtitle: item.subtitle,
                  dueDateLabel: item.dueDateLabel,
                  progress: item.progress,
                  onTap: () {
                    // TODO: Navigate to reminder detail screen
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Demo items moved to helpers.dart: demoReminderItems
