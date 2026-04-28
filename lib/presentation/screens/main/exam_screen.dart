import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/badges/unanswered_questions_badge.dart';
import 'package:achievia/presentation/widgets/builders/exam_pageview_builder.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/cards/unanswered_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  final Map<int, int> selectedAnswers = {};

  bool _isBatchAnswered(QuizItemEntity batch) {
    return batch.questions.every((question) => selectedAnswers[question.id] != null);
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllerNotifier = ref.read(pageController.notifier);
    final pageControllers = ref.watch(pageController);
    final indexs = ref.watch(changeIndexProvider);
    final indexNotider = ref.read(changeIndexProvider.notifier);
    final showModal = ref.read(showModalNotifier.notifier);
    final visible = ref.watch(showModalNotifier);
    final isAnswered = ref.read(answeredQuestionsProvider.notifier);
    final isAnsweredWatch = ref.watch(answeredQuestionsProvider);
    final answerQuestion = ref.read(answerQotProvider.notifier);

    final quizBatches = asyncQuestions.value ?? <QuizItemEntity>[];

    final safeIndex = quizBatches.isEmpty
        ? 0
        : indexs.clamp(0, quizBatches.length - 1);

    return Scaffold(
      appBar: ExamAppBar(
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
          data: (_) => quizBatches.isEmpty
              ? '0 / 0'
              : '${safeIndex + 1} / ${quizBatches.length}',
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
            },
            itemBuilder: (context, batchIndex) {
              final batch = quizBatches[batchIndex];

              return !visible
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(batch.questions.length, (questionIndex) {
                            final question = batch.questions[questionIndex];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: questionIndex == batch.questions.length - 1 ? 0 : 16,
                              ),
                              child: QuestionsContent(
                                questionText: '${questionIndex + 1}. ${question.questionText}',
                                choices: question.choices,
                                selectedIndex: selectedAnswers[question.id],
                                onSelect: (v) async {
                                  if (v != null) {
                                    isAnswered.isAnswered(question.id);
                                    await answerQuestion.answerQuestion(
                                      question.choices[v].choiceText,
                                    );
                                    setState(() {
                                      selectedAnswers[question.id] = v;
                                    });
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                  : UnansweredCard(
                      isShown: () => showModal.showModal(),
                      itemCount: quizBatches.length,
                      itemBuilder: (context, indx) => UnansweredQuestionsBadge(
                        callback: () {
                          pageControllerNotifier.navigateToPage(indx);
                          showModal.showModal();
                        },
                        content: '${indx + 1}',
                        answered: quizBatches[indx].questions.every(
                          (question) => isAnsweredWatch.contains(question.id),
                        ),
                        index: indx,
                      ),
                      totalItems: isAnsweredWatch.length,
                      currentItems: quizBatches.length,
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
                onPressed: () => pageControllerNotifier.prev(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ReusableButton(
                title:
                    quizBatches.isEmpty || !_isBatchAnswered(quizBatches[safeIndex])
                    ? 'UNANSWERED'
                    : 'ANSWERED',
                onPressed: () => showModal.showModal(),
                width: MediaQuery.of(context).size.width == 360 ? 200 : 240,
                height: 50,
              ),
              IconButton(
                onPressed:
                    quizBatches.isEmpty || !_isBatchAnswered(quizBatches[safeIndex])
                    ? null
                    : () {
                        pageControllerNotifier.next(
                          context,
                          quizBatches.length,
                          safeIndex,
                        );
                        if (safeIndex >= quizBatches.length - 1) {
                          isAnswered.resetState();
                          setState(() {
                            selectedAnswers.clear();
                          });
                        }
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
