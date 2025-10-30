import 'package:flutter/material.dart';

class PdfBadge extends StatelessWidget {
  final String text;
  final String tabType;
  const PdfBadge({super.key, required this.text, required this.tabType});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme.labelSmall;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tabType == 'mother notes' ? Icon(Icons.picture_as_pdf, size: 60, color: themeColor.primary) : Icon(Icons.file_copy, size: 60, color: themeColor.primary),
          Text(text,
          textAlign: TextAlign.center,
          style: textTheme?.copyWith(
            color: themeColor.primary
          ),
          )
        ],
      ),
    );
  }
}