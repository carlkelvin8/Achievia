import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/badges/unanswered_questions_badge.dart';
import 'package:achievia/presentation/widgets/builders/exam_pageview_builder.dart';
import 'package:achievia/presentation/widgets/builders/queueing_pageview_builder.dart';
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
  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllerNotifier = ref.read(pageController.notifier);
    final pageControllers = ref.watch(pageController);
    final outerControllerState = ref.watch(pageControllerOuter);
    final outerControllerEvent = ref.read(pageControllerOuter.notifier);
    final indexs = ref.watch(changeIndexProvider);
    final indexNotider = ref.read(changeIndexProvider.notifier);
    final indexOuter = ref.watch(changeIndexProviderOuter);
    final indexOuterNotifier = ref.read(changeIndexProviderOuter.notifier);
    final showModal = ref.read(showModalNotifier.notifier);
    final visible = ref.watch(showModalNotifier);
    final isAnswered = ref.read(answeredQuestionsProvider.notifier);
    final isAnsweredWatch = ref.watch(answeredQuestionsProvider);
    final getGenerated = ref.watch(getGeneratedQuestions);
    final answerQuestion = ref.read(answerQotProvider.notifier);
    return Scaffold(
      appBar: ExamAppBar(
        callback: () => outerControllerEvent.nextAsOuter(
          context,
          "outer ${asyncQuestions.value?[indexOuter].title.length}",
        ),
        title: asyncQuestions.when(
          data: (q) {
            return q[indexs].title;
          },
          error: (_, _) => 'Err',
          loading: () => 'Loading',
        ),
        toolbarheight: 150,
        page: asyncQuestions.when(
          data: (questions) => '${indexs + 1} / ${questions.length}',
          loading: () => '0 / 0',
          error: (_, __) => '0 / 0',
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      body: asyncQuestions.when(
        data: (questions) {
          return QueueingPageViewBuilder(
            onPageChanged: (index) {
              indexOuterNotifier.changeIndex(index);
            },
            controller: outerControllerState,
            itemCount: questions.length /*questions[indexs].title.length,*/,
            itemBuilder: (context, index) {
              return ExamPageviewBuilder(
                visible: visible,
                controller: pageControllers,
                itemCount: questions.length,
                onPageChanged: (index) {
                  indexNotider.changeIndex(index);
                },
                itemBuilder: (context, index) {
                  final question = questions[index];

                  return !visible
                      ? QuestionsContent(
                          questionText: question.questions[index].questionText,
                          choices: question.questions[index].choices,
                          selectedIndex: selectedAnswers[index],
                          onSelect: (v) async {
                            if (v != null) {
                              isAnswered.isAnswered(question.id);
                              await answerQuestion.answerQuestion(
                                question.questions[index].choices[v].id.toString(),
                              );
                              print(selectedAnswers);
                              setState(() {
                                selectedAnswers[index] = v;
                              });
                            }
                          },
                        )
                      : UnansweredCard(
                          isShown: () => showModal.showModal(),
                          itemCount: questions.length,
                          itemBuilder: (context, indx) =>
                              UnansweredQuestionsBadge(
                                callback: () {
                                  pageControllerNotifier.navigateToPage(indx);
                                  showModal.showModal();
                                },
                                content: '${indx + 1}',
                                answered: isAnsweredWatch.contains(
                                  questions[indx].id,
                                ),
                                index: indx,
                              ),
                          totalItems: isAnsweredWatch.length,
                          currentItems: questions.length,
                        );
                },
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
                title: selectedAnswers[indexs] == null
                    ? 'UNANSWERED'
                    : 'ANSWERED',
                onPressed: () => showModal.showModal(),
                width: MediaQuery.of(context).size.width == 360 ? 200 : 240,
                height: 50,
              ),
              IconButton(
                onPressed: selectedAnswers[indexs] == null
                    ? null
                    : () {
                        pageControllerNotifier.next(
                          context,
                          questions.length,
                          indexs,
                        );
                        print(pageControllers.page);
                        if (pageControllers.page == 3 &&
                            indexs >= questions.length - 1) {
                          isAnswered.resetState();
                          setState(() {
                            selectedAnswers.clear();
                            print(selectedAnswers);
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
