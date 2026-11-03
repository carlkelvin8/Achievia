import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/achievia_grading.dart';
import 'package:achievia/core/utils/question_bank_navigation.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:achievia/presentation/provider/progress/progress_provider.dart';

class QuestionBankResultScreen extends ConsumerStatefulWidget {
  final QuestionBankResultArgs args;

  const QuestionBankResultScreen({super.key, required this.args});

  @override
  ConsumerState<QuestionBankResultScreen> createState() =>
      _QuestionBankResultScreenState();
}

class _QuestionBankResultScreenState
    extends ConsumerState<QuestionBankResultScreen> {
  late QuestionBankAttempt _attempt = widget.args.attempt;
  late bool _isSaved = widget.args.isSaved;

  /// Saved by the server. A completed attempt without an id was accepted by
  /// the app but deliberately not stored (incomplete exam).
  bool get _isRecorded =>
      _isSaved &&
      (_attempt.id.isNotEmpty ||
          _attempt.attemptType != QuestionBankAttempt.subjectExamType);
  bool _isRetrying = false;
  Object? _retryError;

  bool get _isExam => widget.args.selection.isSubjectExam;

  Future<void> _retrySave() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _retryError = null;
    });
    try {
      final saved = await ref
          .read(questionBankRepositoryProvider)
          .saveAttempt(
            selection: widget.args.selection,
            correctAnswers: _attempt.correctAnswers,
            totalQuestions: _attempt.totalQuestions,
            snapshot: widget.args.snapshot,
          );
      if (!mounted) return;
      setState(() {
        _attempt = saved;
        _isSaved = true;
        _isRetrying = false;
      });
      ref.invalidate(recentQuestionBankAttemptsProvider);
      ref.invalidate(recentSubjectExamAttemptsProvider);
      ref.invalidate(progressProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _retryError = error;
      });
    }
  }

  /// Persisted summaries are opened by attempt id. Only when nothing was
  /// persisted is the exact in-memory snapshot shown (flagged as not saved).
  bool get _summaryPersisted =>
      _isSaved && _attempt.hasSummary && _attempt.id.isNotEmpty;

  bool get _canViewSummary =>
      _isExam && (_summaryPersisted || widget.args.snapshot != null);

  void _viewSummary() {
    final snapshot = widget.args.snapshot;
    context.push(
      RouteConstants.questionBankExamSummary,
      extra: _summaryPersisted
          ? ExamSummaryArgs(attemptId: _attempt.id)
          : ExamSummaryArgs(inMemory: snapshot?.toSummary()),
    );
  }

  void _practiceAgain() {
    final topic = widget.args.selection.topic;
    if (topic == null) return;
    ref.invalidate(questionBankQuestionsProvider(topic.id));
    context.pushReplacement(
      RouteConstants.questionBankPractice,
      extra: QuestionBankPracticeArgs(widget.args.selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grading = gradePercentage(_attempt.score);
    return Scaffold(
      appBar: CustomAppBar(
        title: _isExam ? 'Exam Results' : 'Practice Results',
        centerTitle: true,
        onBackPressed: () => returnToQuestionBankSubjects(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const InlineStyleSvg(
              key: ValueKey('result-logo'),
              assetPath: logo,
              width: 96,
              height: 96,
              semanticsLabel: 'Achievia logo',
            ),
            const SizedBox(height: 14),
            Text(
              widget.args.selection.topic?.title ?? 'Subject Exam',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.args.selection.subject.title),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        value:
                            '${_attempt.correctAnswers} / ${_attempt.totalQuestions}',
                        label: 'Correct',
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        value: '${grading.percentage.toStringAsFixed(0)}%',
                        label: 'Score',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExam) ...[
              const SizedBox(height: 12),
              _ResultStatus(grading: grading),
              const SizedBox(height: 12),
              _GradingInterpretation(
                level: grading.level,
                message: grading.message,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecorded ? Icons.cloud_done_outlined : Icons.cloud_off,
                  color: _isRecorded
                      ? Colors.green
                      : _isSaved
                      ? theme.disabledColor
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _isRecorded
                        ? 'Result saved'
                        : _isSaved
                        ? 'Result not recorded: an exam needs 100 questions to count'
                        : 'Result not saved',
                  ),
                ),
              ],
            ),
            if (_retryError != null) ...[
              const SizedBox(height: 8),
              Text(
                'The result still could not be saved. Please try again.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (!_isSaved) ...[
              const SizedBox(height: 14),
              ReusableButton(
                title: 'RETRY SAVE',
                onPressed: _retrySave,
                width: 280,
                height: 50,
                isLoading: _isRetrying,
              ),
            ],
            const SizedBox(height: 20),
            if (_canViewSummary) ...[
              ReusableButton(
                key: const ValueKey('view-summary'),
                title: 'VIEW SUMMARY',
                onPressed: _viewSummary,
                width: 280,
                height: 50,
              ),
              const SizedBox(height: 12),
            ],
            if (!_isExam) ...[
              ReusableButton(
                title: 'PRACTICE AGAIN',
                onPressed: _practiceAgain,
                width: 280,
                height: 50,
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () => returnToQuestionBankSubjects(context),
              child: const Text('BACK TO SUBJECTS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ResultMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Passed / Failed chip for a finished subject exam, backed by the shared
/// grading rule (raw percentage vs. the passing boundary).
class _ResultStatus extends StatelessWidget {
  final GradingResult grading;

  const _ResultStatus({required this.grading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = grading.passed
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        grading.statusLabel,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Remark + interpretation shown for a finished subject exam, sourced from the
/// shared grading bracket so the wording stays identical to the Progress
/// screen's grading table.
class _GradingInterpretation extends StatelessWidget {
  final String level;
  final String message;

  const _GradingInterpretation({required this.level, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              level,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
