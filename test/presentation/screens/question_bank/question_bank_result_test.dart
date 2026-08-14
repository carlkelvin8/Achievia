import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('result shows score and save confirmation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: QuestionBankResultScreen(
            args: QuestionBankResultArgs(
              selection: _selection,
              attempt: _savedAttempt,
              isSaved: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Result saved'), findsOneWidget);
  });

  testWidgets('unsaved result can retry its Supabase write', (tester) async {
    final repository = _FakeQuestionBankRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: QuestionBankResultScreen(
            args: QuestionBankResultArgs(
              selection: _selection,
              attempt: _unsavedAttempt,
              isSaved: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Result not saved'), findsOneWidget);
    await tester.tap(find.text('RETRY SAVE'));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(find.text('Result saved'), findsOneWidget);
  });
}

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 4,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);
const _topic = QuestionBankTopic(
  id: 8,
  subjectId: 1,
  title: 'Enzymes',
  description: '',
);
const _selection = QuestionBankSelection(subject: _subject, topic: _topic);
final _savedAttempt = QuestionBankAttempt(
  id: 'attempt-1',
  userId: 'user-1',
  subjectId: 1,
  topicId: 8,
  subjectTitle: 'Clinical Chemistry',
  topicTitle: 'Enzymes',
  correctAnswers: 1,
  totalQuestions: 2,
  score: 50,
  completedAt: DateTime.utc(2026, 8, 14),
);
final _unsavedAttempt = QuestionBankAttempt(
  id: '',
  userId: '',
  subjectId: 1,
  topicId: 8,
  subjectTitle: 'Clinical Chemistry',
  topicTitle: 'Enzymes',
  correctAnswers: 1,
  totalQuestions: 2,
  score: 50,
  completedAt: DateTime.utc(2026, 8, 14),
);

class _FakeQuestionBankRepository implements QuestionBankRepository {
  int saveCount = 0;

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    saveCount += 1;
    return _savedAttempt;
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5}) async =>
      const [];

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => const [];

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async =>
      const [];

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [];
}
