import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable dialog builder for radio selection lists
/// Perfect for configuration dialogs, option pickers, or any single-choice selection
class RadioSelectionDialog<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T) optionLabel;
  final void Function(T) onSelected;

  const RadioSelectionDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.optionLabel,
    required this.onSelected,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T selectedValue,
    required String Function(T) optionLabel,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<T>(
              title: Text(optionLabel(option)),
              value: option,
              groupValue: selectedValue,
              onChanged: (value) {
                if (value != null) {
                  dialogContext.pop(value);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return RadioListTile<T>(
            title: Text(optionLabel(option)),
            value: option,
            groupValue: selectedValue,
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
                context.pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
      ],
    );
  }
}
