import 'package:achievia/data/models/quiz/quiz_dto.dart';
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

    final flattenedQuestions =
        asyncQuestions.value
            ?.expand(
              (quiz) => quiz.questions.map(
                (q) => (title: quiz.title, quizId: quiz.id, question: q),
              ),
            )
            .toList() ??
        <FlattenedQuestion>[];

    final safeIndex = flattenedQuestions.isEmpty
        ? 0
        : indexs.clamp(0, flattenedQuestions.length - 1);

    return Scaffold(
      appBar: ExamAppBar(
        callback: () {},
        title: asyncQuestions.when(
          data: (_) {
            if (flattenedQuestions.isEmpty) return 'No questions';
            return flattenedQuestions[safeIndex].title;
          },
          error: (_, _) => 'Err',
          loading: () => 'Loading',
        ),
        toolbarheight: 150,
        page: asyncQuestions.when(
          data: (_) => flattenedQuestions.isEmpty
              ? '0 / 0'
              : '${safeIndex + 1} / ${flattenedQuestions.length}',
          loading: () => '0 / 0',
          error: (_, __) => '0 / 0',
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      body: asyncQuestions.when(
        data: (_) {
          if (flattenedQuestions.isEmpty) {
            return const Center(child: Text('No questions available'));
          }

          return ExamPageviewBuilder(
            visible: visible,
            controller: pageControllers,
            itemCount: flattenedQuestions.length,
            onPageChanged: (innerIndex) {
              indexNotider.changeIndex(innerIndex);
            },
            itemBuilder: (context, innerIndex) {
              final item = flattenedQuestions[innerIndex];

              return !visible
                  ? QuestionsContent(
                      questionText: item.question.questionText,
                      choices: item.question.choices,
                      selectedIndex: selectedAnswers[innerIndex],
                      onSelect: (v) async {
                        if (v != null) {
                          isAnswered.isAnswered(item.question.id);
                          await answerQuestion.answerQuestion(
                            item.question.choices[v].choiceText,
                          );
                          debugPrint(selectedAnswers.toString());
                          setState(() {
                            selectedAnswers[innerIndex] = v;
                          });
                        }
                      },
                    )
                  : UnansweredCard(
                      isShown: () => showModal.showModal(),
                      itemCount: flattenedQuestions.length,
                      itemBuilder: (context, indx) => UnansweredQuestionsBadge(
                        callback: () {
                          pageControllerNotifier.navigateToPage(indx);
                          showModal.showModal();
                        },
                        content: '${indx + 1}',
                        answered: isAnsweredWatch.contains(
                          flattenedQuestions[indx].question.id,
                        ),
                        index: indx,
                      ),
                      totalItems: isAnsweredWatch.length,
                      currentItems: flattenedQuestions.length,
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
                    flattenedQuestions.isEmpty ||
                        selectedAnswers[safeIndex] == null
                    ? 'UNANSWERED'
                    : 'ANSWERED',
                onPressed: () => showModal.showModal(),
                width: MediaQuery.of(context).size.width == 360 ? 200 : 240,
                height: 50,
              ),
              IconButton(
                onPressed:
                    flattenedQuestions.isEmpty ||
                        selectedAnswers[safeIndex] == null
                    ? null
                    : () {
                        pageControllerNotifier.next(
                          context,
                          flattenedQuestions.length,
                          safeIndex,
                        );
                        print(pageControllers.page);
                        if (pageControllers.page == 3 &&
                            safeIndex >= flattenedQuestions.length - 1) {
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
