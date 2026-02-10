import 'package:achievia/presentation/widgets/reminder/reminder_date_time_section.dart';
import 'package:achievia/presentation/widgets/reminder/reminder_form_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  State<NewReminderScreen> createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: theme.primaryColor,
              size: 24, // Reduced from 28 to standard size
            ),
            onPressed: () {
              // TODO: Implement save logic
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8), // Adjusted spacing
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
