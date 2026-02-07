// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/network/offline_caching.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';

final getQuestions = Provider<QuestionsUseCase>((ref) {
  return sl.get<QuestionsUseCase>();
});

final getHive = Provider<OfflineCaching>((ref) {
  return sl.get<OfflineCaching>();
});

final getQuestionsProviderState =
    FutureProvider.family<List<QuestionsEntity>, ({String token, String id})>((
      ref,
      params,
    ) async {
      final gtQuestions = ref.read(getQuestions);
      try {
        final result = await gtQuestions.getQuestions(params.token, params.id);
        return result;
      } catch (e) {
        rethrow;
      }
    });

final getResultsProviderState = FutureProvider<QuizScoreEntity?>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final result = await gtQuestions.getGWA();
    return result;
  } catch (e) {
    rethrow;
  }
});

final getQoty = FutureProvider<QotyEntity>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  return await gtQuestions.getQotQueston();
});

final getRandomQ = FutureProvider<List<QuestionsEntity>>((ref) async {
  final gtQuestions = ref.read(getHive);
  try {
    final result = await gtQuestions.getDataFromCache();
    return result.map((e) => e.toEntity()).toList();
  } catch (e) {
    rethrow;
  }
});

final getGeneratedQuestions = FutureProvider<List<QotyEntity>>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final results = await gtQuestions.getGeneratedQuestions();
    return results;
  } catch (e) {
    rethrow;
  }
});

final answeredQuestionsProvider =
    NotifierProvider<ShowUnansweredQuestionsProvider, List<int>>(
      ShowUnansweredQuestionsProvider.new,
    );
final showModalNotifier = NotifierProvider<ShowModalProvider, bool>(
  ShowModalProvider.new,
);
final answerQotProvider =
    NotifierProvider<QuestionsProvider, AnswerQuestionNotifier>(
      QuestionsProvider.new,
    );
final pageController =
    NotifierProvider.autoDispose<PageControllerProvider, PageController>(
      PageControllerProvider.new,
    );
final changeIndexProvider = NotifierProvider.autoDispose<IndexProvider, int>(
  IndexProvider.new,
);

class PageControllerProvider extends Notifier<PageController> {
  @override
  PageController build() {
    return PageController();
  }

  Future<void> next(BuildContext context) async {
    if (state.page == 99) {
      Navigator.pushNamed(context, '/attempt-screen');
    }
    state.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  Future<void> prev() async {
    state.previousPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> navigateToPage(int index) async {
    state.animateToPage(
      index,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class ShowUnansweredQuestionsProvider extends Notifier<List<int>> {
  late final bool isShown;
  @override
  List<int> build() => [];

  Future<void> isAnswered(int index) async {
    state.add(index);
    print(state);
  }
}

class ShowModalProvider extends Notifier<bool> {
  @override
  bool build() => false;

  void showModal() {
    state = !state;
  }
}

class IndexProvider extends Notifier<int> {
  @override
  int build() => 0;

  void changeIndex(int index) {
    state = index;
  }
}

class QuestionsProvider extends Notifier<AnswerQuestionNotifier> {
  late final QuestionsUseCase useCase;
  @override
  AnswerQuestionNotifier build() {
    useCase = ref.read(getQuestions);
    return AnswerQuestionNotifier(
      quiz_id: '',
      student_id: '',
      chosen_answer: '',
    );
  }

  Future<void> answerQuestion(String chosenAnswer) async {
    final entity = QotyEntityPost(
      chosen_ans: chosenAnswer,
      quiz_id: 1,
      student_id: 1,
    );
    await useCase.answerQuestion(entity);
  }

  Future<void> randomizeQuestion() async {
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
