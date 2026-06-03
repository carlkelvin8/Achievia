import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class EditMantraDialog extends StatefulWidget {
  final String initialText;

  const EditMantraDialog({
    super.key,
    required this.initialText,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialText,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => EditMantraDialog(initialText: initialText),
    );
  }

  @override
  State<EditMantraDialog> createState() => _EditMantraDialogState();
}

class _EditMantraDialogState extends State<EditMantraDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.spa_outlined,
            color: AppColors.primaryVariant,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            'My Achievian Mantra',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 4,
            textAlign: TextAlign.center,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'input your own mantra',
              errorText: _errorText,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () {
                  final trimmed = _controller.text.trim();
                  if (trimmed.isEmpty) {
                    setState(() {
                      _errorText = 'Mantra is required';
                    });
                    return;
                  }

                  Navigator.of(context).pop(trimmed);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}