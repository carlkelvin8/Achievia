import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuestionBankPracticeScreen extends ConsumerStatefulWidget {
  final QuestionBankSelection selection;

  const QuestionBankPracticeScreen({super.key, required this.selection});

  @override
  ConsumerState<QuestionBankPracticeScreen> createState() =>
      _QuestionBankPracticeScreenState();
}

class _QuestionBankPracticeScreenState
    extends ConsumerState<QuestionBankPracticeScreen> {
  bool _sessionInitializationScheduled = false;
  bool _allowPop = false;

  Future<void> _confirmQuit() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave practice?'),
        content: const Text('Your answers in this session will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldQuit == true && mounted) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _advanceOrComplete() async {
    final notifier = ref.read(questionBankSessionProvider.notifier);
    final state = ref.read(questionBankSessionProvider);
    if (state.currentIndex < state.questions.length - 1) {
      notifier.next();
      return;
    }

    final completion = await notifier.complete();
    if (!mounted) return;
    context.pushReplacement(
      RouteConstants.questionBankResults,
      extra: QuestionBankResultArgs(
        selection: widget.selection,
        attempt: completion.attempt,
        isSaved: completion.isSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(
      questionBankQuestionsProvider(widget.selection.topic.id),
    );

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.selection.topic.title,
          centerTitle: true,
          onBackPressed: _confirmQuit,
        ),
        body: questions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => QuestionBankStatusView(
            icon: Icons.cloud_off_outlined,
            message: 'We could not load questions for this topic.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(
              questionBankQuestionsProvider(widget.selection.topic.id),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const QuestionBankStatusView(
                icon: Icons.quiz_outlined,
                message: 'This topic does not have usable questions yet.',
              );
            }

            final session = ref.watch(questionBankSessionProvider);
            final hasCurrentSession =
                session.selection?.topic.id == widget.selection.topic.id &&
                session.questions.isNotEmpty;
            if (!hasCurrentSession) {
              if (!_sessionInitializationScheduled) {
                _sessionInitializationScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref
                      .read(questionBankSessionProvider.notifier)
                      .start(selection: widget.selection, questions: items);
                });
              }
              return const Center(child: CircularProgressIndicator());
            }

            final question = session.questions[session.currentIndex];
            final selectedIndex = session.selectedAnswers[question.id];
            final isLast = session.currentIndex == session.questions.length - 1;
            final progress =
                (session.currentIndex + 1) / session.questions.length;

            return Column(
              children: [
                LinearProgressIndicator(value: progress),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.selection.subject.title),
                      Text(
                        '${session.currentIndex + 1} / ${session.questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: QuestionsContent(
                      key: ValueKey('question-bank-question-${question.id}'),
                      questionText:
                          '${session.currentIndex + 1}. ${question.questionText}',
                      choices: question.choices,
                      selectedIndex: selectedIndex,
                      onSelect: (index) {
                        if (index != null) {
                          ref
                              .read(questionBankSessionProvider.notifier)
                              .answer(index);
                        }
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: ReusableButton(
                      title: isLast ? 'VIEW RESULTS' : 'NEXT',
                      onPressed: selectedIndex == null || session.isSubmitting
                          ? null
                          : _advanceOrComplete,
                      width: 280,
                      height: 50,
                      isLoading: session.isSubmitting,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
