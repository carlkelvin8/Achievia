import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {

  /// questionIndex -> selectedChoiceIndex
  final Map<int, int> selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllerNotifier = ref.read(pageController.notifier);
    final pageControllers = ref.watch(pageController);
    final indexs = ref.watch(changeIndexProvider);
    final indexNotider = ref.read(changeIndexProvider.notifier);

    return Scaffold(
      appBar: ExamAppBar(
      title: asyncQuestions.when(data: (q){
        return q[indexs].quiz?['title'];
      }, 
      error: (_,_)=>'Err', 
      loading: ()=>'Loading'),
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
          return PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageControllers,
            itemCount: questions.length,
            onPageChanged: (index) {
              indexNotider.changeIndex(index);
            },
            itemBuilder: (context, index) {
              final question = questions[index];

              return QuestionsContent(
                questionText: question.questionText,
                choices: question.choices,
                selectedIndex: selectedAnswers[index],
                onSelect: (v) {
                  if (v != null) {
                    setState(() {
                      selectedAnswers[index] = v;
                    });
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      persistentFooterButtons: [
        IconButton(
          onPressed: () {
            pageControllerNotifier.prev();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).primaryColor,
          ),
        ),
        ReusableButton(
          title: selectedAnswers[indexs] == null ? 'UNANSWERED' : 'ANSWERED',
          onPressed: () {},
          width: 240,
          height: 50,
        ),
        IconButton(
          onPressed:selectedAnswers[indexs] == null ? null : () {
            pageControllerNotifier.next();
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
