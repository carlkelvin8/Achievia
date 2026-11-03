// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/core/utils/inline_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:html_unescape/html_unescape.dart';

class QuestionOfTheDayCard extends ConsumerWidget {
  const QuestionOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncState = ref.watch(qotdStateProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: asyncState.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              key: ValueKey('qotd-progress'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to load today\'s question.',
              key: const ValueKey('qotd-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('qotd-retry'),
              onPressed: () => ref.invalidate(qotdStateProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (state) => _QuestionContent(state: state, theme: theme, ref: ref),
      ),
    );
  }
}

class _QuestionContent extends ConsumerWidget {
  final QuestionOfTheDayState state;
  final ThemeData theme;
  final WidgetRef ref;

  const _QuestionContent({
    required this.state,
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final theme = Theme.of(context);
    final green = Colors.green.shade700;
    final red = Colors.red.shade700;

    if (state.choices.isEmpty) {
      return Text(
        'No question available today.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final enabled = !state.isAnswered && !state.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.subjectTitle.isNotEmpty) ...[
          Text(
            state.subjectTitle.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
        ],
        InlineHtmlText(
          HtmlUnescape().convert(state.questionText),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (state.imagePath.trim().isNotEmpty) ...[
          QuestionImage(imagePath: state.imagePath),
          const SizedBox(height: 8),
        ],
        ...List.generate(state.choices.length, (index) {
          final choice = state.choices[index];
          final isSelected = state.selectedIndex == index;

          Color? textColor;
          Color? fillColor;
          Color? borderColor;
          var showLogo = false;
          if (state.isAnswered) {
            if (choice.isCorrect) {
              textColor = green;
              fillColor = green.withValues(alpha: 0.10);
              borderColor = green;
            } else if (isSelected) {
              textColor = red;
              fillColor = red.withValues(alpha: 0.10);
              borderColor = red;
            }
            // Selected answer, plus the actual correct answer after a miss.
            showLogo = isSelected || choice.isCorrect;
          } else if (state.isSaving && isSelected) {
            textColor = theme.colorScheme.onSurfaceVariant;
          }

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: state.isAnswered && !isSelected && !choice.isCorrect
                ? 0.65
                : 1,
            child: AnimatedContainer(
              key: ValueKey('qotd-option-$index'),
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor ?? Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: RadioGroup<int>(
                groupValue: state.selectedIndex,
                onChanged: (value) {
                  if (enabled && value != null) {
                    widgetRef
                        .read(qotdStateProvider.notifier)
                        .answerOption(value);
                  }
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: enabled
                      ? () => widgetRef
                            .read(qotdStateProvider.notifier)
                            .answerOption(index)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // The same slot holds the selection circle before
                        // answering and the Achievia check / X after, so the
                        // four choices never shift or change size.
                        SizedBox(
                          width: 44,
                          height: 30,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: state.isAnswered
                                ? (showLogo
                                      ? InlineStyleSvg(
                                          assetPath: choice.isCorrect
                                              ? correctAnswerIcon
                                              : incorrectAnswerIcon,
                                          key: ValueKey('qotd-logo-$index'),
                                          semanticsLabel: choice.isCorrect
                                              ? 'Correct answer'
                                              : 'Incorrect answer',
                                          height: 30,
                                          width: 30,
                                        )
                                      : null)
                                : Radio<int>(
                                    value: index,
                                    enabled: enabled,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: InlineHtmlText(
                            HtmlUnescape().convert(choice.text),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
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
        }),
        if (state.isSaving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            key: ValueKey('qotd-progress'),
            minHeight: 2,
          ),
        ],
        if (state.isAnswered && state.rationale.isNotEmpty) ...[
          const SizedBox(height: 8),
          _RationalePanel(
            key: ValueKey('qotd-rationale-${state.dayKey}-${state.questionId}'),
            rationale: state.rationale,
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            key: const ValueKey('qotd-error'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _RationalePanel extends StatefulWidget {
  final String rationale;

  const _RationalePanel({super.key, required this.rationale});

  @override
  State<_RationalePanel> createState() => _RationalePanelState();
}

class _RationalePanelState extends State<_RationalePanel>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.16),
      base,
    );
    final pulse = TweenSequence<Color?>([
      for (var i = 0; i < 2; i++) ...[
        TweenSequenceItem(
          tween: ColorTween(begin: base, end: highlight),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: highlight, end: base),
          weight: 1,
        ),
      ],
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Container(
        key: const ValueKey('qotd-rationale'),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pulse.value,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rationale',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.rationale.contains(RegExp(r'<[a-zA-Z][^>]*>')))
            ContentTextScale(
              child: ScaledHtml(data: HtmlUnescape().convert(widget.rationale)),
            )
          else
            Text(
              widget.rationale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
