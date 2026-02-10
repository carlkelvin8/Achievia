import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/widgets/reminder_entity.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';

class ScheduledScreen extends StatefulWidget {
  const ScheduledScreen({super.key});

  @override
  State<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends State<ScheduledScreen> {
  late Map<String, List<ReminderEntity>> _scheduledGroups;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the map and its lists
    _scheduledGroups = Map.from(demoScheduledGroups).map((key, value) {
      return MapEntry(key, List<ReminderEntity>.from(value));
    });
  }

  void _toggleItem(String groupKey, int index, bool? val) {
    if (val == null) return;
    setState(() {
      final list = _scheduledGroups[groupKey]!;
      list[index] = list[index].copyWith(isCompleted: val);
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
          'Scheduled',
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
              _scheduledGroups.values.any(
                    (list) => list.any((item) => item.isCompleted),
                  )
                  ? Icons.check_circle
                  : Icons.more_vert,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _scheduledGroups.entries.map((entry) {
              final groupTitle = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      groupTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    const SizedBox(height: 8), // Placeholder spacing

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ReminderCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        dueDateLabel: item.dueDateLabel,
                        isCompleted: item.isCompleted,
                        onStatusChanged: (val) =>
                            _toggleItem(groupTitle, index, val),
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
