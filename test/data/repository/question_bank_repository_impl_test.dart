import 'dart:math';

import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/questions/question_bank_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository preserves the requested course filter', () async {
    final dataSource = _FakeQuestionBankDataSource();
    final repository = QuestionBankRepositoryImpl(dataSource);

    final subjects = await repository.getSubjectsForCourse(9);

    expect(dataSource.requestedCourseId, 9);
    expect(subjects, hasLength(1));
    expect(subjects.single.title, 'Hematology');
  });
}

class _FakeQuestionBankDataSource implements QuestionBankDataSource {
  int? requestedCourseId;

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async {
    requestedCourseId = courseId;
    return const [
      QuestionBankSubject(
        id: 2,
        courseId: 9,
        title: 'Hematology',
        description: '',
        image: '',
      ),
    ];
  }

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [];

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => const [];

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5}) async =>
      const [];
}
