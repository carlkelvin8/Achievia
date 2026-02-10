import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReminderDateTimeSection extends StatelessWidget {
  final bool isDateEnabled;
  final bool isTimeEnabled;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<bool> onDateEnabledChanged;
  final ValueChanged<bool> onTimeEnabledChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime> onTimeChanged;

  const ReminderDateTimeSection({
    super.key,
    required this.isDateEnabled,
    required this.isTimeEnabled,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateEnabledChanged,
    required this.onTimeEnabledChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date and Time',
          style: TextStyle(
            color: Color(0xFF535B74),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Date Toggle Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2A47),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isDateEnabled,
                        onChanged: onDateEnabledChanged,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDateEnabled)
                Theme(
                  data: theme.copyWith(
                    textTheme: theme.textTheme.copyWith(
                      bodyLarge: const TextStyle(fontSize: 13), // Days
                      bodyMedium: const TextStyle(fontSize: 13), // Weekdays
                      titleSmall: const TextStyle(fontSize: 13), // Month/Year
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                      onDateChanged: onDateChanged,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
              // Time Toggle Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2A47),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isTimeEnabled,
                        onChanged: onTimeEnabledChanged,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTimeEnabled)
                SizedBox(
                  height: 140, // Reduced height
                  child: Transform.scale(
                    scale: 0.9, // Slightly smaller
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      onDateTimeChanged: (dateTime) {
                        onTimeChanged(dateTime);
                      },
                      initialDateTime: DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
