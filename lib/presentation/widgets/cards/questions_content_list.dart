// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class QuestionsContentList extends StatelessWidget {
  final String questionText;
  final List choices;
  final int? selectedIndex;

  const QuestionsContentList({
    super.key,
    required this.questionText,
    required this.choices,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
            FontWeight? font;
            if (selectedIndex != null) {
              if (choice['isCorrect'] == true) {
                textColor = Colors.green;
                font = FontWeight.bold;
              } else if (isSelected) {
                textColor = Colors.red;
                font = FontWeight.bold;
              }
            }

            return RadioListTile<int>(
              value: index,
              groupValue: selectedIndex,
              title: Text(
                choice['choiceText'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: font,
                ),
              ),
              onChanged: null,
            );
          }),
        ],
      ),
    );
  }
}
