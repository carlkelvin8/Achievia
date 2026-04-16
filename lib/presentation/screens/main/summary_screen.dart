import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/builders/summary_listview.dart';
import 'package:achievia/presentation/widgets/cards/questions_content_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Summary'),
      ),
      body: SingleChildScrollView(
        child: asyncQuestions.when(
        data: (questions) => SummaryListview(
          itemCount: questions.length,
          itemBuilder: (context, index) => QuestionsContentList(questionText: '${index + 1}. ${questions[index].questions[index].questionText}', choices: questions[index].questions[index].choices, selectedIndex: 0),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      ),
    );
  }
}