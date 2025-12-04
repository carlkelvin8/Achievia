// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final getQuestions = Provider<QuestionsUseCase>((ref){
  return sl.get<QuestionsUseCase>();
});

final getQuestionsProviderState = FutureProvider.family<List<QuestionsEntity>, ({String token, String id})>((ref, params) async {
  final gtQuestions = ref.read(getQuestions);
  print('Fetching questions with params: $params');
  try {
    final result = await gtQuestions.getQuestions(params.token, params.id);
    print('Provider result: $result');
    return result;
  } catch (e, st) {
    print('Provider error: $e');
    print('StackTrace: $st');
    rethrow;
  }
});
