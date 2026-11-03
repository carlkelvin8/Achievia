import 'dart:async';
import 'dart:math';

import 'package:achievia/core/utils/study_deck.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/reviewer/study_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/study_mode_fakes.dart';

const keyA = (subjectId: 1, quizId: 10);
const keyB = (subjectId: 1, quizId: 20);

final testUser = StateProvider<String?>((ref) => 'user-a');

class Rig {
  Rig({int a = 5, int b = 4}) {
    repo = FakeStudyRepo({
      10: studyQuestions(a, base: 1),
      20: studyQuestions(b, base: 100),
    });
  }

  late final FakeStudyRepo repo;
  final store = MemoryStudyStore();
  final containers = <ProviderContainer>[];

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        studyDeckRepositoryProvider.overrideWithValue(repo),
        studyProgressStoreProvider.overrideWithValue(store),
        studyRandomProvider.overrideWithValue(Random(7)),
        activeAccountIdProvider.overrideWith(
          (ref) => Stream.value(ref.watch(testUser)),
        ),
      ],
    );
    containers.add(c);
    addTearDown(c.dispose);
    return c;
  }

  Future<StudyModeState> open(ProviderContainer c, StudyModeKey key) async {
    c.listen(studyModeProvider(key), (_, _) {});
    return c.read(studyModeProvider(key).future);
  }
}

StudyModeState stateOf(ProviderContainer c, StudyModeKey key) =>
    c.read(studyModeProvider(key)).requireValue;

StudyModeNotifier notifierOf(ProviderContainer c, StudyModeKey key) =>
    c.read(studyModeProvider(key).notifier);

void main() {
  test('opens only its own subtopic deck with initial counters', () async {
    final rig = Rig();
    final c = rig.container();
    final s = await rig.open(c, keyA);
    expect(s.deckSize, 5);
    expect(s.remaining, 5);
    expect(s.repeat, 0);
    expect(s.done, 0);
    expect(s.questions.map((q) => q.id), [1, 2, 3, 4, 5]);
    expect(s.current!.id, 1);
    expect(s.answered, isFalse);
    expect(rig.repo.requested, [10]);
  });

  group('answering', () {
    test('first answer locks; later taps are ignored', () async {
      final rig = Rig();
      final c = rig.container();
      final s = await rig.open(c, keyA);
      final q = s.current!;
      final n = notifierOf(c, keyA);

      n.answer(wrongChoiceId(q));
      n.answer(correctChoiceId(q));
      n.answer(wrongChoiceId(q));
      final after = stateOf(c, keyA);
      expect(after.selectedChoiceId, wrongChoiceId(q));
      expect(after.selectedIsCorrect, isFalse);
      // An answer never moves any counter.
      expect([after.remaining, after.repeat, after.done], [5, 0, 0]);
    });

    test('correct answer is judged by choice id', () async {
      final rig = Rig();
      final c = rig.container();
      final q = (await rig.open(c, keyA)).current!;
      notifierOf(c, keyA).answer(correctChoiceId(q));
      expect(stateOf(c, keyA).selectedIsCorrect, isTrue);
    });

    test('a choice that is not on the current card is ignored', () async {
      final rig = Rig();
      final c = rig.container();
      await rig.open(c, keyA);
      notifierOf(c, keyA).answer(999999);
      expect(stateOf(c, keyA).answered, isFalse);
    });

    test('correctness survives shuffled choices', () async {
      final rig = Rig();
      final c = rig.container();
      await rig.open(c, keyA);
      final n = notifierOf(c, keyA)..setShuffleChoices(true);
      final s = stateOf(c, keyA);
      final shown = s.currentChoices;
      final correct = shown.firstWhere((x) => x.isCorrect);
      n.answer(correct.id);
      expect(stateOf(c, keyA).selectedIsCorrect, isTrue);
    });

    test('actions need an answered card', () async {
      final rig = Rig();
      final c = rig.container();
      await rig.open(c, keyA);
      final n = notifierOf(c, keyA);
      n.studyAgain();
      n.alreadyKnow();
      n.toggleRationale();
      final s = stateOf(c, keyA);
      expect([s.remaining, s.repeat, s.done], [5, 0, 0]);
      expect(s.rationaleOpen, isFalse);
    });
  });

  group('deck actions', () {
    test('Study Again: remaining -1, repeat +1, clears the answer', () async {
      final rig = Rig();
      final c = rig.container();
      final first = (await rig.open(c, keyA)).current!;
      final n = notifierOf(c, keyA);
      n.answer(wrongChoiceId(first));
      n.studyAgain();
      final s = stateOf(c, keyA);
      expect([s.remaining, s.repeat, s.done], [4, 1, 0]);
      expect(s.answered, isFalse);
      expect(s.rationaleOpen, isFalse);
      expect(s.current!.id, isNot(first.id));
    });

    test('Already Know: remaining -1, done +1, never returns', () async {
      final rig = Rig(a: 3);
      final c = rig.container();
      final first = (await rig.open(c, keyA)).current!;
      final n = notifierOf(c, keyA);
      n.answer(correctChoiceId(first));
      n.alreadyKnow();
      var s = stateOf(c, keyA);
      expect([s.remaining, s.repeat, s.done], [2, 0, 1]);
      // Rapid double tap: the second press has no answered card to act on.
      n.alreadyKnow();
      n.alreadyKnow();
      s = stateOf(c, keyA);
      expect([s.remaining, s.done], [2, 1]);
      for (var i = 0; i < 20; i++) {
        s = stateOf(c, keyA);
        if (s.isComplete) break;
        n.answer(correctChoiceId(s.current!));
        n.studyAgain();
        expect(stateOf(c, keyA).current!.id, isNot(first.id));
      }
    });

    test('Study Again then double tap counts once', () async {
      final rig = Rig();
      final c = rig.container();
      final q = (await rig.open(c, keyA)).current!;
      final n = notifierOf(c, keyA)..answer(correctChoiceId(q));
      n
        ..studyAgain()
        ..studyAgain();
      expect(stateOf(c, keyA).repeat, 1);
    });

    test(
      'Study Again and Already Know together resolve to one action',
      () async {
        final rig = Rig();
        final c = rig.container();
        final q = (await rig.open(c, keyA)).current!;
        final n = notifierOf(c, keyA)..answer(correctChoiceId(q));
        n
          ..studyAgain()
          ..alreadyKnow();
        final s = stateOf(c, keyA);
        expect([s.repeat, s.done], [1, 0]);
        expect(s.remaining + s.repeat + s.done, s.deckSize);
      },
    );

    test('completing the deck, then Reset Deck', () async {
      final rig = Rig(a: 3);
      final c = rig.container();
      await rig.open(c, keyA);
      final n = notifierOf(c, keyA);
      n.answer(correctChoiceId(stateOf(c, keyA).current!));
      n.studyAgain();
      for (var i = 0; i < 3; i++) {
        n.answer(correctChoiceId(stateOf(c, keyA).current!));
        n.alreadyKnow();
      }
      var s = stateOf(c, keyA);
      expect(s.isComplete, isTrue);
      // The repeated question was finally marked Already Know: it left
      // Repeat for Done, so nothing is counted twice.
      expect([s.remaining, s.repeat, s.done], [0, 0, 3]);
      expect(s.current, isNull);

      n.resetDeck();
      n.resetDeck(); // double tap cannot corrupt anything
      s = stateOf(c, keyA);
      expect([s.remaining, s.repeat, s.done], [3, 0, 0]);
      expect(s.answered, isFalse);
      expect(s.isComplete, isFalse);
    });

    test('rationale toggles without touching anything else', () async {
      final rig = Rig();
      final c = rig.container();
      // Question 2 has a stored rationale.
      var s = await rig.open(c, keyA);
      final n = notifierOf(c, keyA);
      n.answer(correctChoiceId(s.current!));
      n.alreadyKnow(); // now question 2 is current
      s = stateOf(c, keyA);
      expect(s.current!.id, 2);
      n.answer(wrongChoiceId(s.current!));
      final before = stateOf(c, keyA);
      n.toggleRationale();
      final open = stateOf(c, keyA);
      expect(open.rationaleOpen, isTrue);
      expect(open.current!.rationale, 'Because reason 2');
      expect(open.selectedChoiceId, before.selectedChoiceId);
      expect(open.progress.queue, before.progress.queue);
      expect(
        [open.remaining, open.repeat, open.done],
        [before.remaining, before.repeat, before.done],
      );
      n.toggleRationale();
      expect(stateOf(c, keyA).rationaleOpen, isFalse);
    });
  });

  group('shuffle settings', () {
    test('toggling keeps the current card, its answer and counters', () async {
      final rig = Rig(a: 8);
      final c = rig.container();
      final first = (await rig.open(c, keyA)).current!;
      final n = notifierOf(c, keyA);
      n.answer(wrongChoiceId(first));
      n.setShuffleQuestions(true);
      n.setShuffleChoices(true);
      final s = stateOf(c, keyA);
      expect(s.current!.id, first.id);
      expect(s.selectedChoiceId, wrongChoiceId(first));
      expect([s.remaining, s.repeat, s.done], [8, 0, 0]);
      expect(s.progress.shuffleQuestions, isTrue);
      expect(s.progress.shuffleChoices, isTrue);
    });

    test('the order stays stable until Reset Deck', () async {
      final rig = Rig(a: 8);
      final c = rig.container();
      await rig.open(c, keyA);
      final n = notifierOf(c, keyA)..setShuffleQuestions(true);
      final order = stateOf(c, keyA).progress.queue;
      // Answering, opening the rationale and re-reading never reshuffle.
      n.answer(correctChoiceId(stateOf(c, keyA).current!));
      n.toggleRationale();
      c.read(studyModeProvider(keyA));
      expect(stateOf(c, keyA).progress.queue, order);
    });
  });

  group('persistence', () {
    test('progress survives a new container (app restart)', () async {
      final rig = Rig();
      final c1 = rig.container();
      await rig.open(c1, keyA);
      final n = notifierOf(c1, keyA);
      n.setShuffleQuestions(true);
      n.setShuffleChoices(true);
      n.answer(correctChoiceId(stateOf(c1, keyA).current!));
      n.alreadyKnow();
      n.answer(correctChoiceId(stateOf(c1, keyA).current!));
      n.studyAgain();
      final saved = stateOf(c1, keyA);
      await pumpEventQueue();

      final c2 = rig.container();
      final restored = await rig.open(c2, keyA);
      expect(restored.progress.queue, saved.progress.queue);
      expect(restored.progress.known, saved.progress.known);
      expect(restored.repeat, 1);
      expect(restored.done, 1);
      expect(restored.remaining, 3);
      expect(restored.remaining + restored.repeat + restored.done, 5);
      expect(restored.progress.shuffleQuestions, isTrue);
      expect(restored.progress.shuffleChoices, isTrue);
      expect(restored.progress.choiceOrders, saved.progress.choiceOrders);
      // The current card is the same, unanswered again after a restart.
      expect(restored.current!.id, saved.current!.id);
      expect(restored.answered, isFalse);
    });

    test('users are isolated and each gets their own progress back', () async {
      final rig = Rig();
      final c = rig.container();
      await rig.open(c, keyA);
      var n = notifierOf(c, keyA);
      n.answer(correctChoiceId(stateOf(c, keyA).current!));
      n.alreadyKnow();
      await pumpEventQueue();
      expect(stateOf(c, keyA).done, 1);

      // Account switch: the previous user's state must not leak.
      c.read(testUser.notifier).state = 'user-b';
      await pumpEventQueue();
      var s = await c.read(studyModeProvider(keyA).future);
      expect([s.remaining, s.repeat, s.done], [5, 0, 0]);
      n = notifierOf(c, keyA);
      n.answer(wrongChoiceId(s.current!));
      n.studyAgain();
      await pumpEventQueue();

      // Back to user A: their own progress returns.
      c.read(testUser.notifier).state = 'user-a';
      await pumpEventQueue();
      s = await c.read(studyModeProvider(keyA).future);
      expect([s.remaining, s.repeat, s.done], [4, 0, 1]);
      expect(rig.store.peek('user-b', 10)!.repeat, 1);
      expect(rig.store.peek('user-a', 10)!.repeat, 0);
    });

    test('subtopics are independent, including Reset Deck', () async {
      final rig = Rig();
      final c = rig.container();
      await rig.open(c, keyA);
      await rig.open(c, keyB);
      final a = notifierOf(c, keyA);
      final b = notifierOf(c, keyB);
      a.answer(correctChoiceId(stateOf(c, keyA).current!));
      a.alreadyKnow();
      b.answer(correctChoiceId(stateOf(c, keyB).current!));
      b.studyAgain();
      b.setShuffleQuestions(true);

      a.resetDeck();
      final sb = stateOf(c, keyB);
      expect([sb.remaining, sb.repeat, sb.done], [3, 1, 0]);
      expect(sb.progress.shuffleQuestions, isTrue);
      final sa = stateOf(c, keyA);
      expect([sa.remaining, sa.repeat, sa.done], [5, 0, 0]);
      expect(sa.progress.shuffleQuestions, isFalse);
      await pumpEventQueue();
      expect(rig.store.peek('user-a', 20)!.repeat, 1);
    });

    test('corrupt stored data falls back to a fresh deck', () async {
      final rig = Rig();
      rig.store.data[MemoryStudyStore.keyOf('user-a', 10)] = '{broken';
      final c = rig.container();
      final s = await rig.open(c, keyA);
      expect([s.remaining, s.repeat, s.done], [5, 0, 0]);
    });

    test('a failing read falls back to a fresh deck, not an error', () async {
      final rig = Rig();
      rig.store.failLoad = true;
      final c = rig.container();
      final s = await rig.open(c, keyA);
      expect(s.deckSize, 5);
    });

    test('a failing write keeps the deck consistent and flags it', () async {
      final rig = Rig();
      final c = rig.container();
      final q = (await rig.open(c, keyA)).current!;
      await pumpEventQueue();
      rig.store.failSave = true;
      final n = notifierOf(c, keyA);
      n.answer(correctChoiceId(q));
      n.alreadyKnow();
      await pumpEventQueue();
      final s = stateOf(c, keyA);
      expect([s.remaining, s.done], [4, 1]);
      expect(s.persistFailed, isTrue);

      rig.store.failSave = false;
      n.answer(correctChoiceId(s.current!));
      n.studyAgain();
      await pumpEventQueue();
      expect(stateOf(c, keyA).persistFailed, isFalse);
      expect(rig.store.peek('user-a', 10)!.done, 1);
    });

    test('changed content is reconciled on the next open', () async {
      final rig = Rig();
      final c1 = rig.container();
      await rig.open(c1, keyA);
      final n = notifierOf(c1, keyA);
      n.answer(correctChoiceId(stateOf(c1, keyA).current!));
      n.alreadyKnow(); // question 1 is Done
      await pumpEventQueue();

      // Question 1 removed, question 6 added.
      rig.repo.byQuiz[10] = [...studyQuestions(5, base: 2)];
      final c2 = rig.container();
      final s = await rig.open(c2, keyA);
      expect(s.deckSize, 5);
      expect(s.done, 0); // the archived question is gone from the deck
      expect(s.questions.map((q) => q.id), [2, 3, 4, 5, 6]);
      expect(s.progress.queue.last, 6);
    });
  });

  group('empty and failing subtopics', () {
    test('an empty subtopic yields an empty deck and writes nothing', () async {
      final rig = Rig(a: 0);
      final c = rig.container();
      final s = await rig.open(c, keyA);
      expect(s.isEmpty, isTrue);
      expect(s.current, isNull);
      notifierOf(c, keyA)
        ..resetDeck()
        ..answer(1)
        ..studyAgain();
      await pumpEventQueue();
      expect(rig.store.saves, 0);
      expect(stateOf(c, keyA).deckSize, 0);
    });

    test('a load failure is an error state that Retry can recover', () async {
      final rig = Rig();
      rig.repo.fail = true;
      final c = rig.container();
      c.listen(studyModeProvider(keyA), (_, _) {});
      await expectLater(
        c.read(studyModeProvider(keyA).future),
        throwsException,
      );
      rig.repo.fail = false;
      c.invalidate(studyModeProvider(keyA));
      expect((await c.read(studyModeProvider(keyA).future)).deckSize, 5);
    });

    test('signed out is an error, never a deck', () async {
      final rig = Rig();
      final c = rig.container();
      c.read(testUser.notifier).state = null;
      c.listen(studyModeProvider(keyA), (_, _) {});
      await expectLater(
        c.read(studyModeProvider(keyA).future),
        throwsA(isA<StateError>()),
      );
      expect(rig.store.saves, 0);
    });
  });

  test('progress is never shared with exam persistence', () {
    // Study Mode's only persistence is its own key namespace.
    final rig = Rig();
    expect(MemoryStudyStore.keyOf('u', 1), startsWith('study_mode_'));
    expect(rig.store.data, isEmpty);
    expect(const StudyProgress().toJsonString(), isNot(contains('score')));
  });
}
