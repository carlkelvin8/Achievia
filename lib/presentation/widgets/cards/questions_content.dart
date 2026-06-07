// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';

class QuestionsContent extends StatefulWidget {
  final String questionText;
  final List<ChoiceEntity> choices;
  final int? selectedIndex;
  final FutureOr<void> Function(int?) onSelect;

  const QuestionsContent({
    super.key,
    required this.questionText,
    required this.choices,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<QuestionsContent> createState() => _QuestionsContentState();
}

class _QuestionsContentState extends State<QuestionsContent> {
  int? _pendingSelection;

  int? get _effectiveSelectedIndex => widget.selectedIndex ?? _pendingSelection;

  @override
  void didUpdateWidget(covariant QuestionsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionText != widget.questionText ||
        oldWidget.choices.map((choice) => choice.id).join(',') !=
            widget.choices.map((choice) => choice.id).join(',')) {
      _pendingSelection = null;
    }
  }

  Future<void> _handleSelect(int? value) async {
    if (value == null || _effectiveSelectedIndex != null) return;
    setState(() {
      _pendingSelection = value;
    });
    await widget.onSelect(value);
  }

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    final selectedIndex = _effectiveSelectedIndex;
    final bool isAnswered = selectedIndex != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Html(
            data: unescape.convert(widget.questionText),
            style: {'p': Style(fontWeight: FontWeight.w600)},
          ),
          const SizedBox(height: 12),

          ...List.generate(widget.choices.length, (index) {
            final choice = widget.choices[index];
            final isSelected = selectedIndex == index;

            Color? textColor;
            FontWeight? font;
            if (selectedIndex != null) {
              if (choice.isCorrect) {
                textColor = Colors.green;
                font = FontWeight.bold;
              } else if (isSelected) {
                textColor = Colors.red;
                font = FontWeight.bold;
              }
            }

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isAnswered && !isSelected ? 0.65 : 1,
              child: RadioListTile<int>(
                value: index,
                // ignore: deprecated_member_use
                groupValue: selectedIndex,
                // ignore: deprecated_member_use
                onChanged: isAnswered ? null : _handleSelect,
                title: Html(
                  data: unescape.convert(choice.choiceText),
                  style: {'p': Style(fontWeight: font, color: textColor)},
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
