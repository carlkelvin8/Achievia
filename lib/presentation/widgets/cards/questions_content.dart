// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class QuestionsContent extends StatelessWidget {
  final String questionText;
  final List choices;
  final int? selectedIndex;
  final void Function(int?) onSelect;

  const QuestionsContent({
    super.key,
    required this.questionText,
    required this.choices,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAnswered = selectedIndex != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(choices.length, (index) {
            final choice = choices[index];
            final isSelected = selectedIndex == index;

            Color? textColor;
            if (selectedIndex != null) {
              if (choice['isCorrect'] == true) {
                textColor = Colors.green;
              } else if (isSelected) {
                textColor = Colors.red;
              }
            }

            return RadioListTile<int>(
              value: index,
              groupValue: selectedIndex,
              onChanged: isAnswered ? null : onSelect,
              title: Text(
                choice['choiceText'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
