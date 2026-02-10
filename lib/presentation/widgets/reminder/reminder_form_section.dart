import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';

class ReminderFormSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController notesController;

  const ReminderFormSection({
    super.key,
    required this.titleController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title',
            style: TextStyle(
              color: Color(0xFF535B74),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ReusableField(controller: titleController, hintText: 'Buy groceries'),
          const SizedBox(height: 16),
          const Text(
            'Notes',
            style: TextStyle(
              color: Color(0xFF535B74),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ReusableField(
            controller: notesController,
            hintText: 'Don\'t forget the milk!',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
