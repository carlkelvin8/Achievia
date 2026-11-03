// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';

/// The question number is prepended to HTML that usually starts with a block
/// `<p>`, which pushes the text onto its own line and leaves a gap. Moves the
/// number inside the first block and drops trailing empty blocks, so the
/// question reads "18. A trichrome-stained..." with the image right below it.
String _tightenQuestionHtml(String html) {
  var out = html.trim();
  final lead = RegExp(
    r'^(\d+\.\s*)(?:<br\s*/?>|\s)*(<(?:p|div|h[1-6])(?=[\s>/])[^>]*>)',
    caseSensitive: false,
  ).firstMatch(out);
  if (lead != null) {
    out = '${lead.group(2)}${lead.group(1)}${out.substring(lead.end)}';
  }
  final trailingEmpty = RegExp(
    r'(?:\s|&nbsp;|<br\s*/?>|<p[^>]*>(?:\s|&nbsp;|<br\s*/?>)*</p>)+$',
    caseSensitive: false,
  );
  return out.replaceFirst(trailingEmpty, '');
}

class QuestionsContent extends StatefulWidget {
  final String questionText;
  final String imagePath;
  final List<ChoiceEntity> choices;
  final int? selectedIndex;
  final FutureOr<void> Function(int?) onSelect;

  /// Subject exam style: only the chosen answer is colored (green when
  /// correct, red when wrong) and marked with a tinted Achievia logo.
  final bool logoFeedback;

  /// Mock Boards: the picked answer is only highlighted in blue with the
  /// Achievia mark. Nothing reveals whether it is correct, and the student can
  /// change it any time until the subject is submitted.
  final bool selectionOnly;

  const QuestionsContent({
    super.key,
    required this.questionText,
    this.imagePath = '',
    required this.choices,
    required this.selectedIndex,
    required this.onSelect,
    this.logoFeedback = false,
    this.selectionOnly = false,
  });

  @override
  State<QuestionsContent> createState() => _QuestionsContentState();
}

class _QuestionsContentState extends State<QuestionsContent> {
  static const double _iconSize = 36;
  static const double _iconSlot = 46;

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
    if (value == null) return;
    if (widget.selectionOnly) {
      if (value == _effectiveSelectedIndex) return;
    } else if (_effectiveSelectedIndex != null) {
      return;
    }
    setState(() {
      _pendingSelection = value;
    });
    await widget.onSelect(value);
  }

  Widget _choiceTile(
    BuildContext context,
    HtmlUnescape unescape, {
    required int index,
    required int? selectedIndex,
  }) {
    final theme = Theme.of(context);
    final choice = widget.choices[index];
    final answered = selectedIndex != null;
    final isSelected = selectedIndex == index;

    Color? color;
    String? iconAsset;
    String? iconLabel;
    if (widget.selectionOnly) {
      if (isSelected) {
        color = theme.colorScheme.primary;
        iconAsset = selectedAnswerIcon;
        iconLabel = 'Selected answer';
      }
    } else if (answered) {
      if (choice.isCorrect) {
        color = Colors.green.shade700;
        iconAsset = correctAnswerIcon;
        iconLabel = 'Correct answer';
      } else if (isSelected) {
        color = Colors.red.shade700;
        iconAsset = incorrectAnswerIcon;
        iconLabel = 'Incorrect answer';
      }
    }
    // Selection-only choices stay tappable (answers can be changed) and
    // always reserve the icon slot so all four line up.
    final locked = answered && !widget.selectionOnly;
    final reserveIconSlot = answered || widget.selectionOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        key: ValueKey('choice-feedback-$index'),
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color ?? theme.dividerColor.withValues(alpha: 0.5),
            // Same border width marked or not, so every tile is the same size.
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('choice-$index'),
            borderRadius: BorderRadius.circular(10),
            onTap: locked ? null : () => _handleSelect(index),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Once answered, every choice reserves the same icon slot
                  // (and a minimum height), so the four choices stay
                  // perfectly aligned and equally sized whether or not a
                  // given one shows the check or the X.
                  if (reserveIconSlot)
                    SizedBox(
                      width: _iconSlot,
                      height: _iconSize,
                      child: iconAsset == null
                          ? null
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: InlineStyleSvg(
                                key: ValueKey('answer-logo-$index'),
                                assetPath: iconAsset,
                                width: _iconSize,
                                height: _iconSize,
                                semanticsLabel: iconLabel,
                              ),
                            ),
                    ),
                  Expanded(
                    child: ContentTextScale(
                      child: ScaledHtml(
                        data: unescape.convert(choice.choiceText),
                        style: {'*': Style(margin: Margins.zero, color: color)},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    final selectedIndex = _effectiveSelectedIndex;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentTextScale(
            child: ScaledHtml(
              data: _tightenQuestionHtml(unescape.convert(widget.questionText)),
              style: {
                'body': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                'p': Style(margin: Margins.zero),
              },
            ),
          ),
          const SizedBox(height: 12),
          if (widget.imagePath.trim().isNotEmpty) ...[
            QuestionImage(imagePath: widget.imagePath),
            const SizedBox(height: 12),
          ],

          // Study Deck style tiles: no selection circles; after answering the
          // correct choice is green with the Achievia check, a wrong pick is
          // red with the Achievia X. Choices lock after the first answer.
          for (var index = 0; index < widget.choices.length; index++)
            _choiceTile(
              context,
              unescape,
              index: index,
              selectedIndex: selectedIndex,
            ),
        ],
      ),
    );
  }
}
