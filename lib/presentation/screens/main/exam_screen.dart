import 'package:achievia/presentation/provider/questions/questions_provider.dart';
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
  int _currentIndex = 0;

  /// questionIndex -> selectedChoiceIndex
  final Map<int, int> selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllerProvider = ref.read(pageController.notifier);
    final pageControllers = ref.watch(pageController);

    return Scaffold(
      appBar: const ExamAppBar(
        title: 'Clinical Chemistry',
        toolbarheight: 150,
      ),
      persistentFooterAlignment: AlignmentDirectional.center,

      body: asyncQuestions.when(
        data: (questions) {
          return PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageControllers,
            itemCount: questions.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
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
            pageControllerProvider.prev();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).primaryColor,
          ),
        ),

        ReusableButton(
          title: selectedAnswers[_currentIndex] == null
              ? 'UNANSWERED'
              : 'ANSWERED',
          onPressed: () {},
          width: 240,
          height: 50,
        ),

        IconButton(
          onPressed: () {
            pageControllerProvider.next();
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
