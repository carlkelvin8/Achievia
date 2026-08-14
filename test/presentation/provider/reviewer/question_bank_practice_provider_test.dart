import 'dart:math';

import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subjects provider uses the signed-in profile course id', () async {
    final repository = _FakeQuestionBankRepository();
    final container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(
          (ref) async => const ProfileEntity(courseId: 4),
        ),
        questionBankRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final subjects = await container.read(questionBankSubjectsProvider.future);

    expect(repository.requestedCourseId, 4);
    expect(subjects.single.title, 'Clinical Chemistry');
  });

  test(
    'subjects provider uses the sole available course when profile course is missing',
    () async {
      final repository = _FakeQuestionBankRepository(
        allSubjects: const [_subject],
      );
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => const ProfileEntity()),
          questionBankRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final subjects = await container.read(
        questionBankSubjectsProvider.future,
      );

      expect(repository.allSubjectsRequested, isTrue);
      expect(subjects.single.title, 'Clinical Chemistry');
    },
  );

  test('session locks the first answer and advances only after answering', () {
    final repository = _FakeQuestionBankRepository();
    final container = ProviderContainer(
      overrides: [questionBankRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(questionBankSessionProvider.notifier);

    notifier.start(selection: _selection, questions: _questions);
    expect(notifier.next(), isFalse);

    notifier.answer(1);
    notifier.answer(0);

    final answered = container.read(questionBankSessionProvider);
    expect(answered.selectedAnswers[101], 1);
    expect(answered.correctAnswers, 1);
    expect(notifier.next(), isTrue);
    expect(container.read(questionBankSessionProvider).currentIndex, 1);
  });

  test('completion persists one attempt even when submitted twice', () async {
    final repository = _FakeQuestionBankRepository();
    final container = ProviderContainer(
      overrides: [questionBankRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(questionBankSessionProvider.notifier);

    notifier.start(selection: _selection, questions: [_questions.first]);
    notifier.answer(1);
    final first = await notifier.complete();
    final second = await notifier.complete();

    expect(repository.saveCount, 1);
    expect(first.isSaved, isTrue);
    expect(second.attempt.id, first.attempt.id);
    expect(first.attempt.correctAnswers, 1);
    expect(first.attempt.totalQuestions, 1);
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

final _questions = [
  QuestionItemEntity(
    id: 101,
    questionText: 'Question one',
    choices: [
      ChoiceEntity(
        id: 1,
        questiondId: 101,
        choiceText: 'Wrong',
        isCorrect: false,
      ),
      ChoiceEntity(
        id: 2,
        questiondId: 101,
        choiceText: 'Correct',
        isCorrect: true,
      ),
    ],
  ),
  QuestionItemEntity(
    id: 102,
    questionText: 'Question two',
    choices: [
      ChoiceEntity(
        id: 3,
        questiondId: 102,
        choiceText: 'Correct',
        isCorrect: true,
      ),
    ],
  ),
];

class _FakeQuestionBankRepository implements QuestionBankRepository {
  final List<QuestionBankSubject> allSubjects;
  int? requestedCourseId;
  bool allSubjectsRequested = false;
  int saveCount = 0;

  _FakeQuestionBankRepository({this.allSubjects = const [_subject]});

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async {
    allSubjectsRequested = true;
    return allSubjects;
  }

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async {
    requestedCourseId = courseId;
    return const [_subject];
  }

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [
    _topic,
  ];

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => _questions;

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    saveCount += 1;
    return QuestionBankAttempt(
      id: 'attempt-$saveCount',
      userId: 'user-1',
      subjectId: selection.subject.id,
      topicId: selection.topic.id,
      subjectTitle: selection.subject.title,
      topicTitle: selection.topic.title,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      score: 100,
      completedAt: DateTime.utc(2026, 8, 14),
    );
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5}) async =>
      const [];
}
