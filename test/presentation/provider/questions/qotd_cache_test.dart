import 'package:achievia/core/utils/qotd_cache.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_qotd_repository.dart';

final morning = DateTime.utc(2026, 3, 10, 2);
final nextDay = DateTime.utc(2026, 3, 11, 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer build(
    FakeQotdRepository repository,
    DateTime Function() clock, {
    String account = 'user-1',
  }) {
    final container = ProviderContainer(
      overrides: [
        qotdRepositoryProvider.overrideWithValue(repository),
        qotdCacheStoreProvider.overrideWithValue(QotdCacheStore(prefs)),
        activeAccountIdProvider.overrideWith((ref) => Stream.value(account)),
        taskClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    container.listen(qotdStateProvider, (_, __) {});
    return container;
  }

  test(
    'a second launch the same day shows the question without lookups',
    () async {
      final repo = FakeQotdRepository();
      final first = await build(
        repo,
        () => morning,
      ).read(qotdStateProvider.future);
      expect(repo.subjectFetches, 1);

      final repo2 = FakeQotdRepository();
      final second = await build(
        repo2,
        () => morning,
      ).read(qotdStateProvider.future);

      expect(second.questionId, first.questionId);
      expect(second.questionText, first.questionText);
      expect(second.choices.length, first.choices.length);
      expect(repo2.subjectFetches, 0, reason: 'no subject lookup when cached');
      expect(repo2.eligibilityChecks, 0);
    },
  );

  test('a new day ignores yesterday cache', () async {
    final repo = FakeQotdRepository();
    await build(repo, () => morning).read(qotdStateProvider.future);

    final repo2 = FakeQotdRepository();
    final tomorrow = await build(
      repo2,
      () => nextDay,
    ).read(qotdStateProvider.future);
    expect(tomorrow.dayKey, '2026-03-11');
    expect(repo2.subjectFetches, 1);
  });

  test('another account never sees this account cache', () async {
    final repo = FakeQotdRepository();
    await build(repo, () => morning).read(qotdStateProvider.future);

    final repo2 = FakeQotdRepository();
    await build(
      repo2,
      () => morning,
      account: 'user-2',
    ).read(qotdStateProvider.future);
    expect(repo2.subjectFetches, 1);
  });

  test('an answer given is cached and restored instantly', () async {
    final repo = FakeQotdRepository();
    final container = build(repo, () => morning);
    final loaded = await container.read(qotdStateProvider.future);
    await container.read(qotdStateProvider.notifier).answerOption(0);
    expect(container.read(qotdStateProvider).value!.isAnswered, isTrue);

    final repo2 = FakeQotdRepository(); // backend knows nothing yet
    final restored = await build(
      repo2,
      () => morning,
    ).read(qotdStateProvider.future);
    expect(restored.questionId, loaded.questionId);
    expect(restored.isAnswered, isTrue);
    expect(restored.selectedIndex, 0);
  });

  test('the saved answer is re-checked in the background', () async {
    final repo = FakeQotdRepository();
    final loaded = await build(
      repo,
      () => morning,
    ).read(qotdStateProvider.future);
    expect(loaded.isAnswered, isFalse);

    // Answered elsewhere after the cache was written.
    final repo2 = FakeQotdRepository();
    repo2.seedAnswer(
      questionId: loaded.questionId,
      userId: 'user-1',
      choiceId: loaded.choices[1].id,
      isCorrect: loaded.choices[1].isCorrect,
      answeredAt: morning,
    );
    final container = build(repo2, () => morning);
    final first = await container.read(qotdStateProvider.future);
    expect(first.isAnswered, isFalse, reason: 'cache first');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final refreshed = container.read(qotdStateProvider).value!;
    expect(refreshed.isAnswered, isTrue);
    expect(refreshed.selectedIndex, 1);
    expect(repo2.answerLookups, 1);
  });

  test('a corrupt cache falls back to the normal load', () async {
    await prefs.setString(QotdCacheStore.keyFor('user-1'), '{not json');
    final repo = FakeQotdRepository();
    final state = await build(
      repo,
      () => morning,
    ).read(qotdStateProvider.future);
    expect(state.questionText, isNotEmpty);
    expect(repo.subjectFetches, 1);
  });

  test('attachment survives answering and a cached offline launch', () async {
    const question = QotdDailyQuestion(
      questionId: 10,
      quizId: 5,
      questionText: 'Identify the picture',
      imagePath: 'questions/picture.png',
      choices: [
        QotdChoice(id: 101, text: 'A', isCorrect: true),
        QotdChoice(id: 102, text: 'B', isCorrect: false),
      ],
    );
    final repo = FakeQotdRepository(
      eligibleQuestionIds: {
        1: [10],
      },
      questions: {10: question},
    );
    final first = build(repo, () => morning);
    expect(
      (await first.read(qotdStateProvider.future)).imagePath,
      question.imagePath,
    );
    await first.read(qotdStateProvider.notifier).answerOption(0);
    final offline = FakeQotdRepository()..failOnLoad = true;
    final restored = await build(
      offline,
      () => morning,
    ).read(qotdStateProvider.future);
    expect(restored.imagePath, question.imagePath);
    expect(restored.isAnswered, isTrue);
    expect(offline.subjectFetches, 0);
  });
}
