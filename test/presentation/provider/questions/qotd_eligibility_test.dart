import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_qotd_repository.dart';

final morning = DateTime.utc(2026, 3, 10, 2);
final nextDay = DateTime.utc(2026, 3, 11, 2);

QotdDailyQuestion q(int id) => QotdDailyQuestion(
  questionId: id,
  quizId: 5,
  questionText: 'Question $id',
  choices: [
    QotdChoice(id: id * 10 + 1, text: 'A', isCorrect: true),
    QotdChoice(id: id * 10 + 2, text: 'B', isCorrect: false),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(FakeQotdRepository repository, DateTime now) {
    final container = ProviderContainer(
      overrides: [
        qotdRepositoryProvider.overrideWithValue(repository),
        activeAccountIdProvider.overrideWith((ref) => Stream.value('user-1')),
        taskClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(qotdStateProvider, (_, _) {});
    return container;
  }

  group('QuestionOfTheDayPicker.pickEligibleQuestionId', () {
    Future<Set<int>> allEligible(List<int> ids) async => ids.toSet();

    test('starts at the deterministic index and is stable', () async {
      final ids = [for (var i = 0; i < 50; i++) 100 + i];
      final expected = ids[QuestionOfTheDayPicker.questionIndex(morning, 50)];
      for (var run = 0; run < 3; run++) {
        expect(
          await QuestionOfTheDayPicker.pickEligibleQuestionId(
            now: morning,
            liveIds: ids,
            filterEligible: allEligible,
          ),
          expected,
        );
      }
    });

    test('moves past ineligible questions and wraps around', () async {
      final ids = [10, 20, 30];
      final start = QuestionOfTheDayPicker.questionIndex(morning, 3);
      final blocked = {ids[start], ids[(start + 1) % 3]};
      final picked = await QuestionOfTheDayPicker.pickEligibleQuestionId(
        now: morning,
        liveIds: ids,
        filterEligible: (chunk) async =>
            chunk.where((id) => !blocked.contains(id)).toSet(),
      );
      expect(picked, ids[(start + 2) % 3]);
    });

    test('returns null when nothing is eligible', () async {
      expect(
        await QuestionOfTheDayPicker.pickEligibleQuestionId(
          now: morning,
          liveIds: [1, 2, 3],
          filterEligible: (_) async => <int>{},
        ),
        isNull,
      );
      expect(
        await QuestionOfTheDayPicker.pickEligibleQuestionId(
          now: morning,
          liveIds: const [],
          filterEligible: allEligible,
        ),
        isNull,
      );
    });
  });

  group('daily selection with deleted or malformed questions', () {
    test("the day's malformed question hands over to the next one", () async {
      final ids = [10, 20, 30];
      final start = QuestionOfTheDayPicker.questionIndex(morning, 3);
      final repository = FakeQotdRepository()
        ..ineligibleQuestionIds.add(ids[start]);

      final state = await containerFor(
        repository,
        morning,
      ).read(qotdStateProvider.future);

      expect(state.questionId, isNot(ids[start]));
      expect(state.questionId, ids[(start + 1) % 3]);
    });

    test('a subject with only malformed questions is skipped', () async {
      final repository = FakeQotdRepository(
        subjects: const [
          QotdSubject(id: 1, title: 'Broken subject'),
          QotdSubject(id: 2, title: 'Hematology'),
        ],
        eligibleQuestionIds: const {
          1: [10],
          2: [20],
        },
        questions: {10: q(10), 20: q(20)},
      )..ineligibleQuestionIds.add(10);

      for (final day in [morning, nextDay]) {
        final state = await containerFor(
          repository,
          day,
        ).read(qotdStateProvider.future);
        expect(state.questionId, 20);
        expect(state.subjectTitle, 'Hematology');
      }
    });

    test('fails visibly when every question is malformed', () async {
      final repository = FakeQotdRepository()
        ..ineligibleQuestionIds.addAll([10, 20, 30]);
      final container = containerFor(repository, morning);

      await expectLater(
        container.read(qotdStateProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test('a large subject is never downloaded in full', () async {
      final ids = [for (var i = 0; i < 2000; i++) 1000 + i];
      final repository = FakeQotdRepository(
        eligibleQuestionIds: {1: ids},
        questions: {for (final id in ids) id: q(id)},
      );

      final state = await containerFor(
        repository,
        morning,
      ).read(qotdStateProvider.future);

      expect(ids, contains(state.questionId));
      expect(repository.eligibilityChecks, 1);
      expect(repository.checkedChunkSizes.single, lessThanOrEqualTo(25));
    });

    test('the same day and data always give the same question', () async {
      final ids = [for (var i = 0; i < 300; i++) 1000 + i];
      FakeQotdRepository fresh() =>
          FakeQotdRepository(
              eligibleQuestionIds: {1: ids},
              questions: {for (final id in ids) id: q(id)},
            )
            ..ineligibleQuestionIds.add(
              ids[QuestionOfTheDayPicker.questionIndex(morning, 300)],
            );

      final a = await containerFor(
        fresh(),
        morning,
      ).read(qotdStateProvider.future);
      final b = await containerFor(
        fresh(),
        morning,
      ).read(qotdStateProvider.future);
      expect(a.questionId, b.questionId);
    });
  });
}
