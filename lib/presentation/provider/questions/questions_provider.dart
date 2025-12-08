// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/widgets/qotd_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final getQuestions = Provider<QuestionsUseCase>((ref){
  return sl.get<QuestionsUseCase>();
});

final getQuestionsProviderState = FutureProvider.family<List<QuestionsEntity>, ({String token})>((ref, params) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final result = await gtQuestions.getQuestions(params.token);
    return result;
  } catch (e) {
    rethrow;
  }
});

final getQoty = FutureProvider<QotyEntity>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  return await gtQuestions.getQotQueston();
});
