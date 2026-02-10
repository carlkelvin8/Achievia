import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/widgets/reminder_entity.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  late Map<String, List<ReminderEntity>> _completedGroups;

  @override
  void initState() {
    super.initState();
    _completedGroups = Map.from(demoCompletedGroups).map((key, value) {
      return MapEntry(key, List<ReminderEntity>.from(value));
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
          'Completed',
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
            icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _completedGroups.entries.map((entry) {
              final groupTitle = entry.key.trim(); // Trim the hacky space
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      groupTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant, // Muted color for date header
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // For completed screen, items are implicitly completed.
                      // Toggle might un-complete them, but for visual match initially true.
                      return ReminderCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        dueDateLabel: item.dueDateLabel,
                        isCompleted: item.isCompleted,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
