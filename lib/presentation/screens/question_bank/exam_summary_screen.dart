import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/builders/question_jump_list.dart';
import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only review of every question of one completed Take an Exam attempt.
///
/// A persisted summary is loaded by attempt id from the saved snapshots (never
/// from the live Question Bank). An in-memory summary is only shown for an
/// attempt that was not persisted, with an explicit notice.
class ExamSummaryScreen extends ConsumerWidget {
  final ExamSummaryArgs args;

  const ExamSummaryScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    if (args.attemptId != null && !args.hasValidId) {
      // Present but unusable: never query, never fall back to another attempt.
      body = const _SummaryError(
        error: ExamSummaryException(ExamSummaryFailure.invalidId),
      );
    } else if (args.isPersisted) {
      final id = args.attemptId!;
      body = ref
          .watch(examSummaryProvider(id))
          .when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                key: ValueKey('summary-loading'),
              ),
            ),
            error: (error, _) => _SummaryError(
              error: error,
              onRetry: () => ref.invalidate(examSummaryProvider(id)),
            ),
            data: (summary) => ExamSummaryList(summary: summary),
          );
    } else if (args.inMemory != null) {
      body = ExamSummaryList(summary: args.inMemory!);
    } else {
      body = const _SummaryError(error: null);
    }
    return Scaffold(
      appBar: const CustomAppBar(title: 'Exam Summary', centerTitle: true),
      body: body,
    );
  }
}

class _SummaryError extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const _SummaryError({required this.error, this.onRetry});

  /// Why the saved summary was rejected (counts, order, score); empty for
  /// every other failure. Shown small so a report can name the exact cause.
  List<String> get _issues {
    final e = error;
    if (e is ExamSummaryException &&
        e.failure == ExamSummaryFailure.malformed) {
      return e.issues;
    }
    return const [];
  }

  String get _message {
    final e = error;
    if (e is ExamSummaryException) {
      switch (e.failure) {
        case ExamSummaryFailure.notFound:
          return 'This exam attempt could not be found.';
        case ExamSummaryFailure.unavailable:
          return 'Detailed summary is unavailable for this older exam result.';
        case ExamSummaryFailure.invalidId:
          return 'This exam result could not be opened.';
        case ExamSummaryFailure.denied:
          return 'You do not have access to this exam summary.';
        case ExamSummaryFailure.malformed:
          return 'The saved summary looks inconsistent, so it is not shown.';
      }
    }
    return 'Unable to load the exam summary. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final retryable = onRetry != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _message,
              key: const ValueKey('summary-error'),
              textAlign: TextAlign.center,
            ),
            if (_issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _issues.take(2).join('\n'),
                key: const ValueKey('summary-error-detail'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (retryable) ...[
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('summary-retry'),
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header counts plus a lazily built list of every exam item in order.
class ExamSummaryList extends StatelessWidget {
  final ExamAttemptSummary summary;

  const ExamSummaryList({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = summary.items;
    return Column(
      children: [
        if (!summary.isPersisted)
          Container(
            key: const ValueKey('summary-not-saved'),
            width: double.infinity,
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.all(10),
            child: Text(
              'This summary was not saved. It is only available until you '
              'leave this screen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            key: const ValueKey('summary-counts'),
            spacing: 12,
            runSpacing: 4,
            children: [
              _Count('Correct', summary.correct, Colors.green.shade700),
              _Count('Incorrect', summary.incorrect, Colors.red.shade700),
              _Count(
                'Unanswered',
                summary.unanswered,
                theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (summary.unanswered > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Unanswered questions are counted as incorrect.',
              key: const ValueKey('summary-unanswered-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: QuestionJumpList(
            key: const ValueKey('summary-list'),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                ExamSummaryItemCard(item: items[index], total: items.length),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Count(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Text(
    '$label: $value',
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
  );
}

/// One read-only question. Has no tap handlers at all.
class ExamSummaryItemCard extends StatelessWidget {
  final ExamSummaryItem item;
  final int total;

  const ExamSummaryItemCard({
    super.key,
    required this.item,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = Colors.green.shade700;
    final red = Colors.red.shade700;
    final (statusLabel, statusColor) = switch (item.status) {
      ExamItemStatus.correct => ('Correct', green),
      ExamItemStatus.incorrect => ('Incorrect', red),
      // An unanswered question (skipped or left when time ran out) scores as
      // wrong, so it is shown as both.
      ExamItemStatus.unanswered => ('Unanswered · Incorrect', red),
    };

    return Card(
      key: ValueKey('exam-summary-item-${item.position}'),
      // Generous gap so consecutive questions read as separate blocks.
      margin: const EdgeInsets.only(bottom: 40),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${item.position} of $total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  statusLabel,
                  key: ValueKey('exam-summary-status-${item.position}'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ContentTextScale(
              // Keeps the admin formatting (italic organism names,
              // sub/superscripts) exactly as shown during the exam.
              child: InlineHtmlText(
                item.questionText.trim(),
                style: theme.textTheme.bodyMedium,
                ignoreBold: true,
              ),
            ),
            if (item.imagePath.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              QuestionImage(
                key: ValueKey('exam-summary-image-${item.position}'),
                imagePath: item.imagePath,
              ),
            ],
            if (!item.isAnswered) ...[
              const SizedBox(height: 6),
              Text(
                'No answer selected',
                key: ValueKey('exam-summary-unanswered-${item.position}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            for (var i = 0; i < item.choices.length; i++)
              _ChoiceRow(item: item, index: i, green: green, red: red),
            if (item.rationale.trim().isNotEmpty) ...[
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
                  key: ValueKey('exam-summary-rationale-${item.position}'),
                  data: HtmlUnescape().convert(item.rationale),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final ExamSummaryItem item;
  final int index;
  final Color green;
  final Color red;

  static const double _logoSize = 28;

  const _ChoiceRow({
    required this.item,
    required this.index,
    required this.green,
    required this.red,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choice = item.choices[index];
    final selected = item.selectedIndex == index;
    final isCorrectChoice = choice.isCorrect;

    // Green / red color coding plus the Achievia check or X; no text label.
    Color? color;
    String? logoLabel;
    if (selected && isCorrectChoice) {
      color = green;
      logoLabel = 'Correct answer';
    } else if (selected) {
      color = red;
      logoLabel = 'Incorrect answer';
    } else if (isCorrectChoice) {
      color = green;
      logoLabel = 'Correct answer';
    }

    return Container(
      key: ValueKey('exam-summary-choice-${item.position}-$index'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color ?? theme.dividerColor.withValues(alpha: 0.4),
          width: color == null ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Every choice reserves the same icon slot, so the text of A-D
          // starts at one indent whether or not a row shows the logo.
          SizedBox(
            width: _logoSize,
            height: _logoSize,
            child: color == null
                ? null
                : InlineStyleSvg(
                    key: ValueKey('exam-summary-logo-${item.position}-$index'),
                    assetPath: logoLabel == 'Incorrect answer'
                        ? incorrectAnswerIcon
                        : correctAnswerIcon,
                    width: _logoSize,
                    height: _logoSize,
                    semanticsLabel: logoLabel,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ContentTextScale(
              child: InlineHtmlText(
                choice.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ignoreBold: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Question and choice text may carry HTML from the Question Bank; the summary
/// shows it as plain text so tags such as `<em>` never appear literally.
String plainExamText(String text) {
  return text
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\/?[a-zA-Z][^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .trim();
}
