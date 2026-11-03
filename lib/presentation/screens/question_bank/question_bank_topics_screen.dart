import 'package:achievia/core/utils/duration_labels.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuestionBankTopicsScreen extends ConsumerStatefulWidget {
  final QuestionBankSubject subject;

  const QuestionBankTopicsScreen({super.key, required this.subject});

  @override
  ConsumerState<QuestionBankTopicsScreen> createState() =>
      _QuestionBankTopicsScreenState();
}

class _QuestionBankTopicsScreenState
    extends ConsumerState<QuestionBankTopicsScreen> {
  bool _startingExam = false;

  QuestionBankSubject get _subject => widget.subject;

  void _message(String text) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Picks the random 100 questions once, then opens the exam with that fixed
  /// list. The flag blocks rapid double taps from starting two exams.
  Future<void> _startExam() async {
    if (_startingExam) return;
    setState(() => _startingExam = true);
    try {
      final questions = await ref
          .read(questionBankRepositoryProvider)
          .getSubjectExamQuestions(_subject.id);
      if (!mounted) return;
      if (questions.length < subjectExamQuestionCount) {
        _message(
          'This subject does not have enough questions for a '
          '$subjectExamQuestionCount-item exam yet.',
        );
        return;
      }
      await context.push(
        RouteConstants.questionBankPractice,
        extra: QuestionBankPracticeArgs(
          QuestionBankSelection(subject: _subject),
          examQuestions: questions,
        ),
      );
    } catch (error) {
      debugPrint('Subject exam load failed: $error');
      if (mounted) _message('We could not start the exam. Please try again.');
    } finally {
      if (mounted) setState(() => _startingExam = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(questionBankTopicsProvider(_subject.id));

    return Scaffold(
      appBar: CustomAppBar(title: _subject.title, centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: topics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => QuestionBankStatusView(
                icon: Icons.cloud_off_outlined,
                message: 'We could not load the topics for this subject.',
                actionLabel: 'Retry',
                onAction: () =>
                    ref.invalidate(questionBankTopicsProvider(_subject.id)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const QuestionBankStatusView(
                    icon: Icons.quiz_outlined,
                    message:
                        'No practice topics are available for this subject yet.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(questionBankTopicsProvider(_subject.id));
                    await ref.read(
                      questionBankTopicsProvider(_subject.id).future,
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final topic = items[index];
                      return SizedBox(
                        height: 104,
                        child: ReviewerCategoryCard(
                          title: topic.title,
                          subtitle: '',
                          onTap: () => context.push(
                            RouteConstants.questionBankStudy,
                            extra: StudyModeArgs(_subject, topic),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$subjectExamQuestionCount items · '
                    '${formatMinutes(subjectExamDuration.inMinutes)} · all topics',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ReusableButton(
                    title: 'TAKE AN EXAM',
                    onPressed: _startingExam ? null : _startExam,
                    width: 280,
                    height: 50,
                    isLoading: _startingExam,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
