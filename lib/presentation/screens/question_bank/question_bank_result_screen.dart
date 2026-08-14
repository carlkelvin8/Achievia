import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isRetrying = false;
  Object? _retryError;

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
          );
      if (!mounted) return;
      setState(() {
        _attempt = saved;
        _isSaved = true;
        _isRetrying = false;
      });
      ref.invalidate(recentQuestionBankAttemptsProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _retryError = error;
      });
    }
  }

  void _practiceAgain() {
    ref.invalidate(
      questionBankQuestionsProvider(widget.args.selection.topic.id),
    );
    context.pushReplacement(
      RouteConstants.questionBankPractice,
      extra: QuestionBankPracticeArgs(widget.args.selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Practice Results',
        centerTitle: true,
        onBackPressed: () => context.go(RouteConstants.questionBankSubjects),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 76,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              widget.args.selection.topic.title,
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
                    _ResultMetric(
                      value:
                          '${_attempt.correctAnswers} / ${_attempt.totalQuestions}',
                      label: 'Correct',
                    ),
                    _ResultMetric(
                      value: '${_attempt.score.toStringAsFixed(0)}%',
                      label: 'Score',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSaved ? Icons.cloud_done_outlined : Icons.cloud_off,
                  color: _isSaved ? Colors.green : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(_isSaved ? 'Result saved' : 'Result not saved'),
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
            ReusableButton(
              title: 'PRACTICE AGAIN',
              onPressed: _practiceAgain,
              width: 280,
              height: 50,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(RouteConstants.questionBankSubjects),
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
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
