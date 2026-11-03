// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

/// One read-only question of the Mock Boards summary.
///
/// Question and choices keep the admin formatting (`<em>`, `<sub>`, `<sup>`,
/// bold, entities), the question's image is shown under its text, and the
/// answers are marked with the Achievia check (correct) or X (wrong pick).
class QuestionsContentList extends StatelessWidget {
  final String questionText;
  final String imagePath;

  /// Explanation of the answer, shown under the choices ('' hides it).
  final String rationale;
  final List<ChoiceEntity> choices;
  final int? selectedIndex;

  const QuestionsContentList({
    super.key,
    required this.questionText,
    this.imagePath = '',
    this.rationale = '',
    required this.choices,
    required this.selectedIndex,
  });

  static const double _iconSize = 24;
  static final _unescape = HtmlUnescape();

  /// Content may arrive with its tags escaped (`&lt;em&gt;`); turn them back
  /// into tags so they are rendered, never shown literally.
  static String _html(String text) => _unescape.convert(text).trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('mock-summary-item-card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContentTextScale(
              child: InlineHtmlText(
                _html(questionText),
                style: theme.textTheme.bodyMedium,
                ignoreBold: true,
              ),
            ),
            if (imagePath.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              QuestionImage(imagePath: imagePath),
            ],
            const SizedBox(height: 12),

            ...List.generate(choices.length, (index) {
              final choice = choices[index];
              final isSelected = selectedIndex == index;

              Color? textColor;
              String? icon;
              String? iconLabel;
              // The correct answer is always shown (also for skipped
              // questions); a wrong pick is marked red.
              if (choice.isCorrect) {
                textColor = Colors.green;
                icon = correctAnswerIcon;
                iconLabel = 'Correct answer';
              } else if (isSelected) {
                textColor = Colors.red;
                icon = incorrectAnswerIcon;
                iconLabel = 'Incorrect answer';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Every choice reserves the same icon slot, so all choice
                    // texts start at one indent whether or not a row has an icon.
                    SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: icon == null
                          ? null
                          : InlineStyleSvg(
                              key: ValueKey('mock-summary-icon-$index'),
                              assetPath: icon,
                              width: _iconSize,
                              height: _iconSize,
                              semanticsLabel: iconLabel,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ContentTextScale(
                        child: InlineHtmlText(
                          _html(choice.choiceText),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                          ignoreBold: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (rationale.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Rationale',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ContentTextScale(
                child: ScaledHtml(
                  key: const ValueKey('mock-summary-rationale'),
                  data: _html(rationale),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
