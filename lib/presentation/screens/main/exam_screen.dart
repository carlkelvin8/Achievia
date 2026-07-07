import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/badges/unanswered_questions_badge.dart';
import 'package:achievia/presentation/widgets/builders/exam_pageview_builder.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/cards/unanswered_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  final Map<String, int> selectedAnswers = {};

  String _answerKey(QuizItemEntity batch, QuestionItemEntity question) =>
      '${batch.id}:${question.id}';

  void _resetQuestionPage(
    PageController controller,
    IndexProviderOuter indexNotifier,
  ) {
    indexNotifier.changeIndex(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpToPage(0);
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(timerProvider, (prev, next) async {
      if (prev?.remaining != Duration.zero && next.remaining == Duration.zero) {
        final quizBatches = ref.read(getGeneratedQuestions).value ?? [];
        final safeIndex = ref.read(changeIndexProvider);
        if (quizBatches.isEmpty) return;
        ref.read(pageControllerOuter.notifier);

        final pageControllerNotifier = ref.read(pageController.notifier);

        final timerNotifier = ref.read(timerProvider.notifier);

        final isLastBatch = safeIndex >= quizBatches.length - 1;
        await pageControllerNotifier.next(
          // ignore: use_build_context_synchronously
          context,
          quizBatches.length,
          safeIndex,
        );

        if (isLastBatch) {
          timerNotifier.pause();
          return;
        }

        timerNotifier.reset();
        timerNotifier.start();
      }
      return;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllerNotifier = ref.read(pageController.notifier);
    final pageControllers = ref.watch(pageController);
    final pageControllerOuterNotifier = ref.read(pageControllerOuter.notifier);
    final pageControllerOuterState = ref.watch(pageControllerOuter);
    final indexs = ref.watch(changeIndexProvider);
    final indexNotider = ref.read(changeIndexProvider.notifier);
    final indexOuter = ref.read(changeIndexProviderOuter.notifier);
    final indexOuterState = ref.watch(changeIndexProviderOuter);
    final showModal = ref.read(showModalNotifier.notifier);
    final visible = ref.watch(showModalNotifier);
    final isAnswered = ref.read(answeredQuestionsProvider.notifier);
    final isAnsweredWatch = ref.watch(answeredQuestionsProvider);
    final answerQuestion = ref.read(answerQotProvider.notifier);
    final timerNotifier = ref.read(timerProvider.notifier);
    final quizBatches = asyncQuestions.value ?? <QuizItemEntity>[];
    final safeIndex = quizBatches.isEmpty
        ? 0
        : indexs.clamp(0, quizBatches.length - 1);
    final currentBatch = quizBatches.isEmpty ? null : quizBatches[safeIndex];
    final safeOuterIndex =
        currentBatch == null || currentBatch.questions.isEmpty
        ? 0
        : indexOuterState.clamp(0, currentBatch.questions.length - 1);
    final currentQuestion =
        currentBatch == null || currentBatch.questions.isEmpty
        ? null
        : currentBatch.questions[safeOuterIndex];
    final currentBatchAnsweredCount = currentBatch == null
        ? 0
        : currentBatch.questions
              .where((question) => isAnsweredWatch.contains(question.id))
              .length;
    final currentAnswerKey = currentBatch != null && currentQuestion != null
        ? _answerKey(currentBatch, currentQuestion)
        : null;
    final isCurrentQuestionAnswered =
        currentAnswerKey != null && selectedAnswers[currentAnswerKey] != null;
    return Scaffold(
      appBar: ExamAppBar(
        callBackQuit: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('End Exam'),
              content: const Text('Are you sure you want to end the exam?'),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    dialogContext.pop();
                    context.pop();
                    timerNotifier.pause();
                  },
                  child: const Text('End'),
                ),
              ],
            ),
          );
        },
        callback: () {},
        title: asyncQuestions.when(
          data: (_) {
            if (quizBatches.isEmpty) return 'No questions';
            return quizBatches[safeIndex].title;
          },
          error: (_, _) => 'Err',
          loading: () => 'Loading',
        ),
        toolbarheight: 150,
        page: asyncQuestions.when(
          data: (_) => currentBatch == null || currentBatch.questions.isEmpty
              ? '0 / 0'
              : '${safeOuterIndex + 1} / ${currentBatch.questions.length}',
          loading: () => '0 / 0',
          error: (_, __) => '0 / 0',
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      body: asyncQuestions.when(
        data: (_) {
          if (quizBatches.isEmpty) {
            return const Center(child: Text('No questions available'));
          }

          return ExamPageviewBuilder(
            visible: visible,
            controller: pageControllers,
            itemCount: quizBatches.length,
            onPageChanged: (batchIndex) {
              indexNotider.changeIndex(batchIndex);
              _resetQuestionPage(pageControllerOuterState, indexOuter);
              timerNotifier.reset();
              timerNotifier.start();
            },
            itemBuilder: (context, batchIndex) {
              final batch = quizBatches[batchIndex];
              final isActiveBatch = batchIndex == safeIndex;

              return !visible
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: batch.questions.isEmpty
                          ? const Center(child: Text('No questions available'))
                          : PageView.builder(
                              key: ValueKey('question-page-$batchIndex'),
                              physics: const NeverScrollableScrollPhysics(),
                              controller: isActiveBatch
                                  ? pageControllerOuterState
                                  : null,
                              itemCount: batch.questions.length,
                              onPageChanged: isActiveBatch
                                  ? indexOuter.changeIndex
                                  : null,
                              itemBuilder: (context, questionIndex) {
                                final question = batch.questions[questionIndex];

                                final answerKey = _answerKey(batch, question);

                                return QuestionsContent(
                                  key: ValueKey('question-content-$answerKey'),
                                  questionText:
                                      '${questionIndex + 1}. ${question.questionText}',
                                  choices: question.choices,
                                  selectedIndex: selectedAnswers[answerKey],
                                  onSelect: (v) async {
                                    if (v != null) {
                                      isAnswered.isAnswered(question.id);
                                      setState(() {
                                        selectedAnswers[answerKey] = v;
                                      });
                                      answerQuestion.recordMockBoardAnswer(
                                        subjectName: batch.title,
                                        isCorrect:
                                            question.choices[v].isCorrect,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    )
                  : UnansweredCard(
                      isShown: () => showModal.showModal(),
                      itemCount: currentBatch?.questions.length ?? 0,
                      itemBuilder: (context, indx) => UnansweredQuestionsBadge(
                        callback: () {
                          pageControllerOuterNotifier.navigateToPage(indx);
                          showModal.showModal();
                        },
                        content: '${indx + 1}',
                        answered: currentBatch == null
                            ? false
                            : isAnsweredWatch.contains(
                                currentBatch.questions[indx].id,
                              ),
                        index: indx,
                      ),
                      totalItems: currentBatchAnsweredCount,
                      currentItems: currentBatch?.questions.length ?? 0,
                    );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      persistentFooterButtons: visible
          ? null
          : [
              IconButton(
                onPressed: quizBatches.isEmpty
                    ? null
                    : () {
                        if (currentBatch == null) return;

                        if (safeOuterIndex > 0) {
                          pageControllerOuterNotifier.prev();
                          return;
                        }

                        if (safeIndex > 0) {
                          pageControllerNotifier.prev();
                        }
                      },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ReusableButton(
                title: currentQuestion == null || !isCurrentQuestionAnswered
                    ? 'UNANSWERED'
                    : 'ANSWERED',
                onPressed: () => showModal.showModal(),
                width: MediaQuery.of(context).size.width == 360 ? 200 : 240,
                height: 50,
              ),
              IconButton(
                onPressed: currentQuestion == null || !isCurrentQuestionAnswered
                    ? null
                    : () async {
                        if (currentBatch == null) return;

                        if (safeOuterIndex <
                            currentBatch.questions.length - 1) {
                          await pageControllerOuterNotifier.nextAsOuter(
                            context,
                            currentBatch.title,
                          );
                          return;
                        }

                        final isLastBatch = safeIndex >= quizBatches.length - 1;
                        if (isLastBatch) {
                          timerNotifier.pause();
                        }

                        await pageControllerNotifier.next(
                          context,
                          quizBatches.length,
                          safeIndex,
                        );

                        if (isLastBatch) {
                          isAnswered.resetState();
                          if (mounted) {
                            setState(() {
                              selectedAnswers.clear();
                            });
                          }
                          return;
                        }

                        _resetQuestionPage(
                          pageControllerOuterState,
                          indexOuter,
                        );
                        timerNotifier.reset();
                        timerNotifier.start();
                      },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
    );
  }
}
