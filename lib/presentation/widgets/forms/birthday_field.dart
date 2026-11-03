import 'package:flutter/material.dart';

/// Sign-up "Birthday" field. Looks like the other fields and opens a calendar
/// ("Select your birthday") with Cancel / Confirm. The chosen date is written
/// to [controller] as readable text and reported through [onPicked].
class BirthdayField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<DateTime> onPicked;
  final FormFieldValidator<String>? validator;

  /// Overridable for tests.
  final DateTime? today;

  const BirthdayField({
    super.key,
    required this.controller,
    required this.onPicked,
    this.validator,
    this.today,
  });

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "January 15, 2000".
  static String format(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  Future<void> _open(BuildContext context) async {
    final now = today ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Select your birthday',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked == null) return;
    controller.text = format(picked);
    onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('birthday-field'),
      controller: controller,
      readOnly: true,
      validator: validator,
      onTap: () => _open(context),
      decoration: const InputDecoration(
        fillColor: Colors.white,
        filled: true,
        hintText: 'Birthday',
        hintStyle: TextStyle(color: Colors.grey),
        suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDBDEE4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
          borderSide: BorderSide(color: Colors.black),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 248, 17, 0)),
        ),
      ),
    );
  }
}
