// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/data_source/cache/cache_data_source_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
final getQuestions = Provider<QuestionsUseCase>((ref){
  return sl.get<QuestionsUseCase>();
});

final getHive = Provider<CacheDataSourceImpl>((ref){
  return sl.get<CacheDataSourceImpl>();
});

final getQuestionsProviderState = FutureProvider.family<List<QuestionsEntity>, ({String token, String id})>((ref, params) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final result = await gtQuestions.getQuestions(params.token, params.id);
    return result;
  } catch (e) {
    rethrow;
  }
});

final getQoty = FutureProvider<QotyEntity>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  return await gtQuestions.getQotQueston();
});

final getRandomQ = FutureProvider<List<QuestionsEntity>>((ref)async{
  final gtQuestions = ref.read(getHive);
  try {
    final result = await gtQuestions.getCacheQuestions();
    return result.map((e)=>e.toEntity()).toList();
  } catch (e) {
    rethrow;
  }
});

final answerQotProvider = NotifierProvider<QuestionsProvider, AnswerQuestionNotifier>(QuestionsProvider.new);


class QuestionsProvider extends Notifier<AnswerQuestionNotifier>{
  late final QuestionsUseCase useCase;
  @override
  AnswerQuestionNotifier build() {
    useCase = ref.read(getQuestions);
    return AnswerQuestionNotifier(quiz_id: '', student_id: '', chosen_answer: '');
  }
  
  Future<void> answerQuestion(String chosenAnswer)async{
    final entity =  QotyEntityPost(chosen_ans: chosenAnswer, quiz_id: 1, student_id: 1);
    await useCase.answerQuestion(entity);
    print('chosen answer: $chosenAnswer');
  }

  Future<void> randomizeQuestion()async{
    await useCase.randomizeQuestions();
  }
}



class AnswerQuestionNotifier {
  final String quiz_id;
  final String student_id;
  final String chosen_answer;
  AnswerQuestionNotifier({
    required this.quiz_id,
    required this.student_id,
    required this.chosen_answer,
  });
  

  AnswerQuestionNotifier copyWith({
    String? quiz_id,
    String? student_id,
    String? chosen_answer,
  }) {
    return AnswerQuestionNotifier(
      quiz_id: quiz_id ?? this.quiz_id,
      student_id: student_id ?? this.student_id,
      chosen_answer: chosen_answer ?? this.chosen_answer,
    );
  }
}
