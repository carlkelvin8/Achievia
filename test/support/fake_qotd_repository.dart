import 'dart:async';

import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';

/// In-memory [QotdRepository] so the daily resolver, answer locking and
/// persistence paths can be tested without Supabase.
class FakeQotdRepository implements QotdRepository {
  FakeQotdRepository({
    List<QotdSubject>? subjects,
    Map<int, List<int>>? eligibleQuestionIds,
    Map<int, QotdDailyQuestion>? questions,
  }) : subjects =
           subjects ?? [const QotdSubject(id: 1, title: 'Clinical Chemistry')],
       eligibleQuestionIds =
           eligibleQuestionIds ??
           const {
             1: [10, 20, 30],
           },
       questions = questions ?? defaultQuestions;

  final List<QotdSubject> subjects;
  final Map<int, List<int>> eligibleQuestionIds;
  final Map<int, QotdDailyQuestion> questions;

  /// The signed-in user the fake repository answers for.
  String currentUser = 'user-1';

  /// Persisted answers keyed by question id, then by user id.
  final Map<int, Map<String, QotdUserAnswer>> answers = {};
  final List<({String userId, int questionId, int choiceId, bool isCorrect})>
  submitted = [];

  int subjectFetches = 0;
  int answerLookups = 0;
  DateTime? lastDayStartUtc;
  DateTime? lastDayEndUtc;
  bool failOnSubmit = false;
  bool failOnLoad = false;

  /// When set, `submitAnswer` blocks until the completer completes, which lets
  /// tests exercise the in-flight window.
  Completer<void>? submitGate;

  void seedAnswer({
    required int questionId,
    required String userId,
    required int choiceId,
    required bool isCorrect,
    required DateTime answeredAt,
  }) {
    answers.putIfAbsent(questionId, () => {})[userId] = QotdUserAnswer(
      choiceId: choiceId,
      isCorrect: isCorrect,
      answeredAt: answeredAt,
    );
  }

  @override
  Future<List<QotdSubject>> getSubjects() async {
    if (failOnLoad) throw Exception('network down');
    subjectFetches++;
    return subjects;
  }

  /// Live questions that are malformed or soft-deleted (not eligible).
  final Set<int> ineligibleQuestionIds = {};
  int eligibilityChecks = 0;
  final List<int> checkedChunkSizes = [];

  @override
  Future<Set<int>> getSubjectIdsWithQuestions() async {
    if (failOnLoad) throw Exception('network down');
    return {
      for (final entry in eligibleQuestionIds.entries)
        if (entry.value.isNotEmpty) entry.key,
    };
  }

  @override
  Future<List<int>> getLiveQuestionIds(int subjectId) async {
    if (failOnLoad) throw Exception('network down');
    return [...(eligibleQuestionIds[subjectId] ?? const <int>[])]..sort();
  }

  @override
  Future<Set<int>> filterEligibleQuestionIds(List<int> ids) async {
    if (failOnLoad) throw Exception('network down');
    eligibilityChecks++;
    checkedChunkSizes.add(ids.length);
    return ids.where((id) => !ineligibleQuestionIds.contains(id)).toSet();
  }

  @override
  Future<QotdDailyQuestion> getQuestion(int questionId) async {
    if (failOnLoad) throw Exception('network down');
    final question = questions[questionId];
    if (question == null) {
      throw StateError('Daily question $questionId was not found');
    }
    return question;
  }

  /// Mirrors the day window the real datasource applies to `answered_at`, so a
  /// stale answer from a previous cycle is never restored.
  @override
  Future<QotdUserAnswer?> getTodaysAnswer({
    required int questionId,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  }) async {
    answerLookups++;
    lastDayStartUtc = dayStartUtc;
    lastDayEndUtc = dayEndUtc;
    final answer = answers[questionId]?[currentUser];
    if (answer == null) return null;
    if (answer.answeredAt.isBefore(dayStartUtc) ||
        !answer.answeredAt.isBefore(dayEndUtc)) {
      return null;
    }
    return answer;
  }

  @override
  Future<void> submitAnswer({
    required String userId,
    required int questionId,
    required int quizId,
    required int choiceId,
    required bool isCorrect,
  }) async {
    if (failOnSubmit) throw Exception('insert failed');
    final gate = submitGate;
    if (gate != null) await gate.future;
    submitted.add((
      userId: userId,
      questionId: questionId,
      choiceId: choiceId,
      isCorrect: isCorrect,
    ));
  }

  static const defaultQuestions = <int, QotdDailyQuestion>{
    10: QotdDailyQuestion(
      questionId: 10,
      quizId: 5,
      questionText: 'Which answer is correct?',
      choices: [
        QotdChoice(id: 101, text: 'Choice A', isCorrect: false),
        QotdChoice(id: 102, text: 'Choice B', isCorrect: true),
      ],
    ),
    20: QotdDailyQuestion(
      questionId: 20,
      quizId: 5,
      questionText: 'Second question?',
      choices: [
        QotdChoice(id: 201, text: 'Choice C', isCorrect: true),
        QotdChoice(id: 202, text: 'Choice D', isCorrect: false),
      ],
    ),
    30: QotdDailyQuestion(
      questionId: 30,
      quizId: 5,
      questionText: 'Third question?',
      choices: [
        QotdChoice(id: 301, text: 'Choice E', isCorrect: true),
        QotdChoice(id: 302, text: 'Choice F', isCorrect: false),
      ],
    ),
  };
}
