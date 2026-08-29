import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/reminder/reminder_date_time_section.dart';
import 'package:achievia/presentation/widgets/reminder/reminder_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewReminderScreen extends ConsumerStatefulWidget {
  const NewReminderScreen({super.key});

  @override
  ConsumerState<NewReminderScreen> createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends ConsumerState<NewReminderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isDateEnabled = true;
  bool _isTimeEnabled = true;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty) {
      AppToast.showWarning(context, 'Please enter a title');
      return;
    }

    // Build deadline from selected date + time
    final deadline = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _isTimeEnabled ? _selectedTime.hour : 0,
      _isTimeEnabled ? _selectedTime.minute : 0,
    );

    final entity = TaskEntity(
      tasksName: title,
      description: notes,
      deadline: deadline,
    );

    final success = await ref
        .read(createTaskProvider.notifier)
        .createTask(entity);

    if (!mounted) return;

    if (success) {
      AppToast.showSuccess(context, 'Reminder saved!');
      context.pop();
    } else {
      final error = ref.read(createTaskProvider).error;
      AppToast.showError(
        context,
        error?.toString() ?? 'Failed to save reminder',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskState = ref.watch(createTaskProvider);
    final isLoading = taskState is AsyncLoading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'New Reminder',
        centerTitle: true,
        leadingWidth: 90,
        leading: const BackButtonWithLabel(label: 'Tasks'),
        titleStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          isLoading
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  onPressed: _handleSave,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReminderFormSection(
              titleController: _titleController,
              notesController: _notesController,
            ),
            const SizedBox(height: 24),
            ReminderDateTimeSection(
              isDateEnabled: _isDateEnabled,
              isTimeEnabled: _isTimeEnabled,
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              onDateEnabledChanged: (value) {
                setState(() {
                  _isDateEnabled = value;
                });
              },
              onTimeEnabledChanged: (value) {
                setState(() {
                  _isTimeEnabled = value;
                });
              },
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              onTimeChanged: (dateTime) {
                setState(() {
                  _selectedTime = TimeOfDay.fromDateTime(dateTime);
                });
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
