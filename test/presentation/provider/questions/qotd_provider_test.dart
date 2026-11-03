import 'dart:async';

import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_qotd_repository.dart';

/// 10:00 in UTC+8 on 2026-03-10, a later instant the same day, and the next day.
final morning = DateTime.utc(2026, 3, 10, 2);
final laterSameDay = DateTime.utc(2026, 3, 10, 15, 59);
final nextDay = DateTime.utc(2026, 3, 11, 2);

const dailyQuestionIds = [10, 20, 30];

QotdDailyQuestion dailyQuestionFor(DateTime now) =>
    FakeQotdRepository
        .defaultQuestions[dailyQuestionIds[QuestionOfTheDayPicker.questionIndex(
      now,
      dailyQuestionIds.length,
    )]]!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer buildContainer({
    required FakeQotdRepository repository,
    required DateTime Function() clock,
    Stream<String?>? accounts,
  }) {
    final container = ProviderContainer(
      overrides: [
        qotdRepositoryProvider.overrideWithValue(repository),
        activeAccountIdProvider.overrideWith(
          (ref) => accounts ?? Stream.value('user-1'),
        ),
        taskClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 pauses an unlistened async provider, so its account
    // dependency would never resolve; the card keeps it alive the same way.
    container.listen(qotdStateProvider, (_, __) {});
    return container;
  }

  /// Completes with the next emitted data state, so tests never race the
  /// provider's rebuild.
  Future<QuestionOfTheDayState> nextDataState(
    ProviderContainer container, {
    bool Function(QuestionOfTheDayState)? where,
  }) {
    final completer = Completer<QuestionOfTheDayState>();
    container.listen(qotdStateProvider, (previous, next) {
      final value = next.value;
      if (value == null) return;
      if (where != null && !where(value)) return;
      if (!completer.isCompleted) completer.complete(value);
    });
    return completer.future;
  }

  group('daily selection', () {
    test(
      'resolves the same question for every instant of the same day',
      () async {
        final repository = FakeQotdRepository();
        final first = buildContainer(
          repository: repository,
          clock: () => morning,
        );
        final second = buildContainer(
          repository: repository,
          clock: () => laterSameDay,
        );

        final a = await first.read(qotdStateProvider.future);
        final b = await second.read(qotdStateProvider.future);

        expect(a.questionId, b.questionId);
        expect(a.questionText, b.questionText);
        expect(a.dayKey, '2026-03-10');
      },
    );

    test(
      'a new day resolves the next question and resets the answer state',
      () async {
        final repository = FakeQotdRepository();
        final today = buildContainer(
          repository: repository,
          clock: () => morning,
        );
        final tomorrow = buildContainer(
          repository: repository,
          clock: () => nextDay,
        );

        final a = await today.read(qotdStateProvider.future);
        final b = await tomorrow.read(qotdStateProvider.future);

        expect(a.dayKey, '2026-03-10');
        expect(b.dayKey, '2026-03-11');
        expect(b.questionId, isNot(a.questionId));
        expect(b.isAnswered, isFalse);
        expect(b.selectedIndex, isNull);
      },
    );

    test(
      'cycles through every subject in order, then wraps to the first',
      () async {
        QotdDailyQuestion q(int id) => QotdDailyQuestion(
          questionId: id,
          quizId: 1,
          questionText: 'Q$id',
          choices: [
            QotdChoice(id: id * 10, text: 'A', isCorrect: true),
            QotdChoice(id: id * 10 + 1, text: 'B', isCorrect: false),
          ],
        );
        final repository = FakeQotdRepository(
          subjects: const [
            QotdSubject(id: 1, title: 'Clinical Chemistry'),
            QotdSubject(id: 2, title: 'Bacteriology'),
            QotdSubject(id: 3, title: 'Parasitology'),
          ],
          eligibleQuestionIds: const {
            1: [1],
            2: [2],
            3: [3],
          },
          questions: {1: q(1), 2: q(2), 3: q(3)},
        );
        final titles = <String>[];
        for (var day = 0; day < 6; day++) {
          final at = morning.add(Duration(days: day));
          final container = buildContainer(
            repository: repository,
            clock: () => at,
          );
          titles.add(
            (await container.read(qotdStateProvider.future)).subjectTitle,
          );
        }
        expect(titles.sublist(0, 3).toSet(), hasLength(3));
        expect(titles.sublist(3), titles.sublist(0, 3));
      },
    );

    test('rotates the subject deterministically across days', () async {
      final repository = FakeQotdRepository(
        subjects: const [
          QotdSubject(id: 1, title: 'Clinical Chemistry'),
          QotdSubject(id: 2, title: 'Hematology'),
        ],
        eligibleQuestionIds: const {
          1: [10],
          2: [20],
        },
        questions: const {
          10: QotdDailyQuestion(
            questionId: 10,
            quizId: 5,
            questionText: 'Chemistry question',
            choices: [QotdChoice(id: 101, text: 'A', isCorrect: true)],
          ),
          20: QotdDailyQuestion(
            questionId: 20,
            quizId: 6,
            questionText: 'Hematology question',
            choices: [QotdChoice(id: 201, text: 'B', isCorrect: true)],
          ),
        },
      );

      final today = buildContainer(
        repository: repository,
        clock: () => morning,
      );
      final tomorrow = buildContainer(
        repository: repository,
        clock: () => nextDay,
      );
      final a = await today.read(qotdStateProvider.future);
      final b = await tomorrow.read(qotdStateProvider.future);

      expect(a.questionId, isNot(b.questionId));
      expect({a.questionId, b.questionId}, {10, 20});
    });

    test('skips subjects without eligible questions', () async {
      final repository = FakeQotdRepository(
        subjects: const [
          QotdSubject(id: 1, title: 'Empty subject'),
          QotdSubject(id: 2, title: 'Hematology'),
        ],
        eligibleQuestionIds: const {
          2: [20],
        },
        questions: const {
          20: QotdDailyQuestion(
            questionId: 20,
            quizId: 6,
            questionText: 'Hematology question',
            choices: [QotdChoice(id: 201, text: 'B', isCorrect: true)],
          ),
        },
      );
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );

      final state = await container.read(qotdStateProvider.future);

      expect(state.subjectTitle, 'Hematology');
      expect(state.questionId, 20);
    });

    test('fails visibly when no subject has an eligible question', () async {
      final repository = FakeQotdRepository(
        subjects: const [QotdSubject(id: 1, title: 'Empty subject')],
        eligibleQuestionIds: const {},
      );
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );

      await expectLater(
        container.read(qotdStateProvider.future),
        throwsA(anything),
      );
    });

    test('fails visibly when the signed-in account is gone', () async {
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
        accounts: Stream.value(null),
      );

      await expectLater(
        container.read(qotdStateProvider.future),
        throwsA(anything),
      );
    });
  });

  group('answer state', () {
    test('restores the persisted answer for the current cycle', () async {
      final repository = FakeQotdRepository();
      final question = dailyQuestionFor(morning);
      repository.seedAnswer(
        questionId: question.questionId,
        userId: 'user-1',
        choiceId: question.choices.first.id,
        isCorrect: false,
        answeredAt: DateTime.utc(2026, 3, 10, 4),
      );
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );

      final state = await container.read(qotdStateProvider.future);

      expect(state.isAnswered, isTrue);
      expect(state.selectedIndex, 0);
      expect(state.isCorrect, isFalse);
    });

    test('ignores an answer stored on a previous day', () async {
      final repository = FakeQotdRepository();
      final question = dailyQuestionFor(morning);
      repository.seedAnswer(
        questionId: question.questionId,
        userId: 'user-1',
        choiceId: question.choices.first.id,
        isCorrect: true,
        answeredAt: DateTime.utc(2026, 3, 9, 4),
      );
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );

      final state = await container.read(qotdStateProvider.future);

      expect(state.isAnswered, isFalse);
      expect(state.selectedIndex, isNull);
    });

    test('scopes the answer lookup to the current UTC+8 day', () async {
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );

      await container.read(qotdStateProvider.future);

      expect(repository.lastDayStartUtc, DateTime.utc(2026, 3, 9, 16));
      expect(repository.lastDayEndUtc, DateTime.utc(2026, 3, 10, 16));
    });
  });

  group('answering', () {
    test('persists the answer once and locks every option', () async {
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );
      final question = await container.read(qotdStateProvider.future);

      final correct = question.choices.indexWhere((c) => c.isCorrect);
      final wrong = correct == 0 ? 1 : 0;
      final notifier = container.read(qotdStateProvider.notifier);
      await notifier.answerOption(correct);
      await notifier.answerOption(wrong);
      await notifier.answerOption(wrong);

      final state = container.read(qotdStateProvider).requireValue;
      expect(state.isAnswered, isTrue);
      expect(state.selectedIndex, correct);
      expect(state.isCorrect, isTrue);
      expect(repository.submitted, hasLength(1));
      expect(repository.submitted.single.userId, 'user-1');
      expect(repository.submitted.single.questionId, question.questionId);
      expect(
        repository.submitted.single.choiceId,
        question.choices[correct].id,
      );
    });

    test('marks a wrong answer as incorrect and keeps it locked', () async {
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );
      await container.read(qotdStateProvider.future);
      final question = dailyQuestionFor(morning);
      final wrongIndex = question.choices.indexWhere((c) => !c.isCorrect);

      await container.read(qotdStateProvider.notifier).answerOption(wrongIndex);

      final state = container.read(qotdStateProvider).requireValue;
      expect(state.isAnswered, isTrue);
      expect(state.isCorrect, isFalse);
      expect(state.selectedIndex, wrongIndex);
    });

    test(
      'a failed save restores the unanswered state with a retry message',
      () async {
        final repository = FakeQotdRepository()..failOnSubmit = true;
        final container = buildContainer(
          repository: repository,
          clock: () => morning,
        );
        await container.read(qotdStateProvider.future);

        await container.read(qotdStateProvider.notifier).answerOption(0);

        final state = container.read(qotdStateProvider).requireValue;
        expect(state.isAnswered, isFalse);
        expect(state.isSaving, isFalse);
        expect(state.selectedIndex, isNull);
        expect(state.errorMessage, isNotNull);
      },
    );

    test('an out-of-range index is ignored', () async {
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );
      await container.read(qotdStateProvider.future);

      await container.read(qotdStateProvider.notifier).answerOption(99);

      expect(repository.submitted, isEmpty);
      expect(
        container.read(qotdStateProvider).requireValue.isAnswered,
        isFalse,
      );
    });

    test(
      'a new container (app restart) restores the answer just saved',
      () async {
        final repository = FakeQotdRepository();
        final first = buildContainer(
          repository: repository,
          clock: () => morning,
        );
        final loaded = await first.read(qotdStateProvider.future);
        final wrongIndex = loaded.choices.indexWhere((c) => !c.isCorrect);
        await first.read(qotdStateProvider.notifier).answerOption(wrongIndex);
        final saved = repository.submitted.single;
        // Simulate the row the database now holds.
        repository.seedAnswer(
          questionId: saved.questionId,
          userId: saved.userId,
          choiceId: saved.choiceId,
          isCorrect: saved.isCorrect,
          answeredAt: morning,
        );

        final restarted = buildContainer(
          repository: repository,
          clock: () => laterSameDay,
        );
        final restored = await restarted.read(qotdStateProvider.future);

        expect(restored.questionId, loaded.questionId);
        expect(restored.isAnswered, isTrue);
        expect(restored.isCorrect, isFalse);
        expect(restored.selectedIndex, wrongIndex);
        await restarted.read(qotdStateProvider.notifier).answerOption(0);
        expect(repository.submitted, hasLength(1));
      },
    );

    test('a restored answer cannot be re-submitted', () async {
      final repository = FakeQotdRepository();
      final question = dailyQuestionFor(morning);
      repository.seedAnswer(
        questionId: question.questionId,
        userId: 'user-1',
        choiceId: question.choices.first.id,
        isCorrect: true,
        answeredAt: DateTime.utc(2026, 3, 10, 4),
      );
      final container = buildContainer(
        repository: repository,
        clock: () => morning,
      );
      await container.read(qotdStateProvider.future);

      await container.read(qotdStateProvider.notifier).answerOption(0);

      expect(repository.submitted, isEmpty);
    });
  });

  group('lifecycle', () {
    test(
      'the same day does not refetch when the provider is read again',
      () async {
        final repository = FakeQotdRepository();
        final container = buildContainer(
          repository: repository,
          clock: () => morning,
        );

        final first = await container.read(qotdStateProvider.future);
        final second = await container.read(qotdStateProvider.future);

        expect(repository.subjectFetches, 1);
        expect(first.questionId, second.questionId);
      },
    );

    test(
      'resuming into a new day reloads the question and clears the answer',
      () async {
        var now = morning;
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        final repository = FakeQotdRepository();
        final container = buildContainer(
          repository: repository,
          clock: () => now,
        );

        final today = await container.read(qotdStateProvider.future);
        await container.read(qotdStateProvider.notifier).answerOption(1);
        expect(
          container.read(qotdStateProvider).requireValue.isAnswered,
          isTrue,
        );

        final reloaded = nextDataState(
          container,
          where: (state) => state.dayKey != today.dayKey,
        );
        now = nextDay;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final tomorrow = await reloaded;

        expect(tomorrow.dayKey, '2026-03-11');
        expect(tomorrow.questionId, isNot(today.questionId));
        expect(tomorrow.isAnswered, isFalse);
        expect(tomorrow.selectedIndex, isNull);
        expect(repository.subjectFetches, greaterThan(1));
      },
    );

    test('resuming on the same day does not reload', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final repository = FakeQotdRepository();
      final container = buildContainer(
        repository: repository,
        clock: () => laterSameDay,
      );

      final today = await container.read(qotdStateProvider.future);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(repository.subjectFetches, 1);
      expect(
        container.read(qotdStateProvider).requireValue.questionId,
        today.questionId,
      );
    });

    test(
      'switching accounts keeps the question and reloads the answer',
      () async {
        final accounts = StreamController<String?>();
        addTearDown(accounts.close);
        accounts.add('user-1');
        final repository = FakeQotdRepository();
        final container = buildContainer(
          repository: repository,
          clock: () => morning,
          accounts: accounts.stream,
        );

        final first = await container.read(qotdStateProvider.future);
        await container.read(qotdStateProvider.notifier).answerOption(1);
        expect(
          container.read(qotdStateProvider).requireValue.isAnswered,
          isTrue,
        );

        // The second account has not answered today's question.
        repository.currentUser = 'user-2';
        final reloaded = nextDataState(
          container,
          where: (state) => !state.isAnswered,
        );
        accounts.add('user-2');
        final second = await reloaded;

        expect(second.questionId, first.questionId);
        expect(second.isAnswered, isFalse);
        expect(second.selectedIndex, isNull);
      },
    );
  });
}
