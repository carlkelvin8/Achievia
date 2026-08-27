// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/questions/questions_state.dart';
import 'package:achievia/presentation/widgets/dialogs/loading_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

final getQuestions = Provider<QuestionsUseCase>((ref) {
  return sl.get<QuestionsUseCase>();
});

final useCase = Provider<QuestionsUseCase>((ref) => sl<QuestionsUseCase>());

final getQuestionsProviderState = FutureProvider<List<QuestionsEntity>>((
  ref,
) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final result = await gtQuestions.getQuestions();
    return result;
  } catch (e) {
    rethrow;
  }
});

final getResultsProviderState = FutureProvider.family<QuizScoreEntity?, int>((
  ref,
  attemptNo,
) async {
  final gtQuestions = ref.read(getQuestions);
  debugPrint('from $attemptNo');
  try {
    final result = await gtQuestions.getGWA(attemptNo);
    return result;
  } catch (e) {
    rethrow;
  }
});

final recentMockBoardResultsProvider = FutureProvider<List<ExaminationResult>>((
  ref,
) {
  return ref.read(getQuestions).getRecentAttemptResults();
});

final getQoty = FutureProvider<QotyEntity>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  debugPrint((await gtQuestions.getQotQueston()).toString());
  return await gtQuestions.getQotQueston();
});

final getGeneratedQuestions = FutureProvider<List<QuizItemEntity>>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final results = await gtQuestions.getGeneratedQuestions();
    debugPrint(results.toString());
    return results;
  } catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
});
final attemptIdProvider = StateProvider<int?>((ref) => null);

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
final pageControllerOuter =
    NotifierProvider.autoDispose<OuterPageControllerProvider, PageController>(
      OuterPageControllerProvider.new,
    );
final changeIndexProvider = NotifierProvider.autoDispose<IndexProvider, int>(
  IndexProvider.new,
);

final changeIndexProviderOuter =
    NotifierProvider.autoDispose<IndexProviderOuter, int>(
      IndexProviderOuter.new,
    );

class OuterPageControllerProvider extends Notifier<PageController> {
  late final QuestionsUseCase useCases;
  @override
  PageController build() {
    useCases = ref.read(getQuestions);
    return PageController();
  }

  bool get _isAttached => state.hasClients;

  Future<void> nextAsOuter(BuildContext context, String debugValue) async {
    if (!_isAttached) return;
    debugPrint("${state.page}");
    debugPrint(debugValue);
    await state.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> prev() async {
    if (!_isAttached) return;
    await state.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> navigateToPage(int index) async {
    if (!_isAttached) return;
    await state.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class ResumeExam extends Notifier<ResumeQuestionState> {
  late final QuestionsUseCase _useCase;
  @override
  ResumeQuestionState build() {
    _useCase = ref.read(useCase);
    return ResumeQuestionState(
      isLoading: false,
      isFetching: false,
      currentPage: 0,
    );
  }

  Future<void> resumeExam(int quizId, double currentPage) async {
    try {
      final entity = MockboardPausedEntity(
        id: '',
        user_id: '',
        quiz_id: quizId,
        current_page: currentPage,
        created_at: '',
        updated_at: '',
      );

      await _useCase.upsertContinueExam(entity);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class PageControllerProvider extends Notifier<PageController> {
  late final QuestionsUseCase useCases;
  bool _isSubmitting = false;
  @override
  PageController build() {
    useCases = ref.read(getQuestions);
    return PageController();
  }

  bool get _isAttached => state.hasClients;

  Future<void> next(BuildContext context, int length, int currentIndex) async {
    if (currentIndex >= length - 1) {
      if (_isSubmitting) return;
      _isSubmitting = true;
      try {
        final attemptId = await useCases.submitQuiz();
        await useCases.getGWA(attemptId);
        ref.read(attemptIdProvider.notifier).state = attemptId;
        if (!context.mounted) return;
        context.go(RouteConstants.attemptScreen, extra: attemptId);
      } finally {
        _isSubmitting = false;
      }
      return;
    }
    if (!_isAttached) return;
    await state.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> prev() async {
    if (!_isAttached) return;
    await state.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> navigateToPage(int index) async {
    if (!_isAttached) return;
    await state.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class ShowUnansweredQuestionsProvider extends Notifier<List<int>> {
  late final bool isShown;
  @override
  List<int> build() => [];

  Future<void> isAnswered(int index) async {
    if (state.contains(index)) return;
    state = [...state, index];
    debugPrint(state.toString());
  }

  Future<void> resetState() async {
    state = [];
    debugPrint(state.toString());
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

class IndexProviderOuter extends Notifier<int> {
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
      isLoading: false,
    );
  }

  Future<void> answerQuestion(String chosenAnswer) async {
    final entity = QotyEntityPost(
      chosen_ans: chosenAnswer,
      quiz_id: 1,
      student_id: state.student_id,
    );
    await useCase.answerQuestion(entity);
  }

  void recordMockBoardAnswer({
    required String subjectName,
    required bool isCorrect,
  }) {
    recordAnswer(subjectName, isCorrect);
  }

  Future<void> randomizeQuestion(int index, BuildContext context) async {
    state = state.copyWith(isLoading: true);
    await showDialog(context, false);
    await useCase.randomizeQuestions(index);
    ref.invalidate(getGeneratedQuestions);
    if (context.mounted) context.pop();
    state = state.copyWith(isLoading: false);
  }

  Future<void> showDialog(BuildContext context, bool isLoading) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: isLoading,
      builder: (context) => const LoadingDialog(),
    );
  }
}
