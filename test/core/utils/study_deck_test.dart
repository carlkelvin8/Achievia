import 'dart:math';

import 'package:achievia/core/utils/study_deck.dart';
import 'package:achievia/core/utils/study_questions_builder.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/study_mode_fakes.dart';

void expectInvariant(StudyProgress p, int deckSize) {
  expect(p.remaining + p.repeat + p.done, deckSize);
  expect(p.queue.toSet().length, p.queue.length, reason: 'duplicate in queue');
  expect(p.known.toSet().length, p.known.length);
  expect(p.queue.toSet().intersection(p.known.toSet()), isEmpty);
}

void main() {
  final questions = studyQuestions(6);
  final ids = [for (final q in questions) q.id];

  group('creation', () {
    test('canonical order and initial counters', () {
      final p = StudyDeck.create(questions, random: Random(1));
      expect(p.queue, ids);
      expect(p.remaining, 6);
      expect(p.repeat, 0);
      expect(p.done, 0);
      expect(p.currentId, ids.first);
      expect(p.choiceOrders, isEmpty);
      expectInvariant(p, 6);
    });

    test('shuffled questions are a stable permutation for a seed', () {
      final a = StudyDeck.create(
        questions,
        random: Random(5),
        shuffleQuestions: true,
      );
      final b = StudyDeck.create(
        questions,
        random: Random(5),
        shuffleQuestions: true,
      );
      expect(a.queue, b.queue);
      expect([...a.queue]..sort(), ids);
      expectInvariant(a, 6);
    });

    test('shuffled choices keep exactly the same ids per question', () {
      final p = StudyDeck.create(
        questions,
        random: Random(9),
        shuffleChoices: true,
      );
      for (final q in questions) {
        final order = p.choiceOrders[q.id]!;
        expect([...order]..sort(), q.choices.map((c) => c.id).toList());
        final shown = StudyDeck.orderedChoices(q, p);
        expect(shown.map((c) => c.id), order);
        // Correctness travels with the choice, not the position.
        expect(shown.where((c) => c.isCorrect).single.id, correctChoiceId(q));
      }
    });

    test('canonical choices are ordered by id when not shuffled', () {
      final q = QuestionItemEntity(
        id: 1,
        questionText: 'q',
        choices: [
          ChoiceEntity(
            id: 30,
            questiondId: 1,
            choiceText: 'c',
            isCorrect: false,
          ),
          ChoiceEntity(
            id: 10,
            questiondId: 1,
            choiceText: 'a',
            isCorrect: true,
          ),
          ChoiceEntity(
            id: 20,
            questiondId: 1,
            choiceText: 'b',
            isCorrect: false,
          ),
        ],
      );
      final shown = StudyDeck.orderedChoices(q, const StudyProgress());
      expect(shown.map((c) => c.id), [10, 20, 30]);
    });
  });

  group('transitions', () {
    late StudyProgress p;
    setUp(() => p = StudyDeck.create(questions, random: Random(1)));

    test('Study Again: remaining -1, repeat +1, requeued at back', () {
      final next = StudyDeck.studyAgain(p);
      expect(next.repeat, 1);
      expect(next.remaining, 5);
      expect(next.done, 0);
      expect(next.queue, [...ids.skip(1), ids.first]);
      expect(next.currentId, isNot(ids.first));
      expectInvariant(next, 6);
    });

    test('a repeated question returns only after every other active one', () {
      var cur = p;
      final seen = <int>[];
      for (var i = 0; i < 12; i++) {
        seen.add(cur.currentId!);
        cur = StudyDeck.studyAgain(cur);
      }
      // Fair round robin: no starvation, each id every 6 steps.
      expect(seen.sublist(0, 6), ids);
      expect(seen.sublist(6), ids);
      // Pressing Study Again twice on a question never counts it twice.
      expect(cur.repeat, 6);
      expect(cur.remaining, 0);
    });

    test('with one active question Study Again keeps it current', () {
      final single = StudyDeck.create(studyQuestions(1), random: Random(1));
      final next = StudyDeck.studyAgain(single);
      expect(next.queue, single.queue);
      expect(next.repeat, 1);
    });

    test('Already Know on a Remaining question: remaining -1, done +1', () {
      final next = StudyDeck.alreadyKnow(p);
      expect(next.remaining, 5);
      expect(next.repeat, 0);
      expect(next.done, 1);
      expect(next.queue.contains(ids.first), isFalse);
      expectInvariant(next, 6);
    });

    test('a Repeat question marked Already Know leaves Repeat for Done', () {
      var cur = StudyDeck.studyAgain(p); // ids[0] -> Repeat, back of queue
      expect(cur.repeat, 1);
      expect(cur.remaining, 5);
      for (var i = 0; i < 5; i++) {
        cur = StudyDeck.alreadyKnow(cur);
      }
      expect(cur.currentId, ids.first, reason: 'the repeated one is back');
      expect(cur.repeat, 1);
      expect(cur.remaining, 0);
      expect(cur.done, 5);

      cur = StudyDeck.alreadyKnow(cur);
      expect(cur.repeat, 0, reason: 'removed from Repeat');
      expect(cur.done, 6, reason: 'moved to Done');
      expect(cur.remaining, 0);
      expect(cur.known.contains(ids.first), isTrue);
      expect(cur.repeatIds, isEmpty);
      expectInvariant(cur, 6);
    });

    test('a question is never in two categories at once', () {
      var cur = p;
      final random = Random(7);
      for (var i = 0; i < 200 && !cur.isComplete; i++) {
        cur = random.nextBool()
            ? StudyDeck.studyAgain(cur)
            : StudyDeck.alreadyKnow(cur);
        expect(cur.remaining + cur.repeat + cur.done, 6);
        expect(cur.known.toSet().intersection(cur.repeatIds.toSet()), isEmpty);
        expect(cur.repeatIds.toSet().difference(cur.queue.toSet()), isEmpty);
      }
    });

    test('a repeated question can later be marked Already Know', () {
      var cur = StudyDeck.studyAgain(p); // ids[0] to the back
      for (var i = 0; i < 5; i++) {
        cur = StudyDeck.alreadyKnow(cur);
      }
      expect(cur.currentId, ids.first);
      cur = StudyDeck.alreadyKnow(cur);
      expect(cur.isComplete, isTrue);
      expect(cur.remaining, 0);
      expect(cur.done, 6);
      expect(cur.repeat, 0);
      expect(cur.currentId, isNull);
      expectInvariant(cur, 6);
    });

    test('actions on an empty queue change nothing', () {
      var cur = p;
      for (var i = 0; i < 6; i++) {
        cur = StudyDeck.alreadyKnow(cur);
      }
      expect(StudyDeck.alreadyKnow(cur).done, 6);
      expect(StudyDeck.studyAgain(cur).repeat, cur.repeat);
    });

    test('invariant holds after any mixed sequence', () {
      var cur = p;
      final random = Random(3);
      for (var i = 0; i < 200 && cur.remaining > 0; i++) {
        cur = random.nextBool()
            ? StudyDeck.studyAgain(cur)
            : StudyDeck.alreadyKnow(cur);
        expectInvariant(cur, 6);
      }
    });

    test('reset restores the whole deck and clears every counter', () {
      var cur = StudyDeck.studyAgain(p);
      cur = StudyDeck.alreadyKnow(cur);
      cur = cur.copyWith(shuffleQuestions: true, shuffleChoices: true);
      final reset = StudyDeck.reset(cur, questions, random: Random(4));
      expect(reset.remaining, 6);
      expect(reset.done, 0);
      expect(reset.repeat, 0);
      expect(reset.known, isEmpty);
      expect([...reset.queue]..sort(), ids);
      // Settings survive and are applied to the rebuilt deck.
      expect(reset.shuffleQuestions, isTrue);
      expect(reset.choiceOrders, hasLength(6));
      expectInvariant(reset, 6);
    });

    test('shuffle questions keeps the current card and all counters', () {
      final progress = StudyDeck.alreadyKnow(StudyDeck.studyAgain(p));
      final on = StudyDeck.setShuffleQuestions(
        progress,
        true,
        questions,
        random: Random(2),
      );
      expect(on.currentId, progress.currentId);
      expect([...on.queue]..sort(), [...progress.queue]..sort());
      expect(on.known, progress.known);
      expect(on.repeat, progress.repeat);
      expect(on.remaining, progress.remaining);
      final off = StudyDeck.setShuffleQuestions(
        on,
        false,
        questions,
        random: Random(2),
      );
      expect(off.queue.skip(1).toList(), [...off.queue.skip(1)]..sort());
    });

    test('shuffle choices protects the answered current question', () {
      final on = StudyDeck.setShuffleChoices(
        p,
        true,
        questions,
        random: Random(2),
      );
      final keep = on.currentId;
      final before = on.choiceOrders[keep]!;
      final off = StudyDeck.setShuffleChoices(
        on,
        false,
        questions,
        random: Random(8),
        keepId: keep,
      );
      expect(off.choiceOrders.keys, [keep]);
      expect(off.choiceOrders[keep], before);
      expect(off.shuffleChoices, isFalse);
    });

    test('a requeued question keeps its choice order', () {
      final shuffled = StudyDeck.create(
        questions,
        random: Random(11),
        shuffleChoices: true,
      );
      final id = shuffled.currentId!;
      final order = shuffled.choiceOrders[id];
      final again = StudyDeck.studyAgain(shuffled);
      expect(again.choiceOrders[id], order);
    });
  });

  group('reconciliation', () {
    test('drops removed ids from queue and known, keeps repeat', () {
      var p = StudyDeck.create(questions, random: Random(1));
      p = StudyDeck.alreadyKnow(p); // 1 known
      p = StudyDeck.studyAgain(p); // 2 is Repeat
      final fewer = questions.where((q) => q.id != 1 && q.id != 3).toList();
      final r = StudyDeck.reconcile(p, fewer, random: Random(1));
      expect(r.queue.contains(3), isFalse);
      expect(r.known.contains(1), isFalse);
      expect(r.repeat, 1, reason: 'question 2 is still active and in Repeat');
      expectInvariant(r, 4);
    });

    test('new questions join the end of the active queue, never Done', () {
      var p = StudyDeck.create(questions, random: Random(1));
      p = StudyDeck.alreadyKnow(p);
      final more = [...questions, ...studyQuestions(2, base: 100)];
      final r = StudyDeck.reconcile(p, more, random: Random(1));
      expect(r.queue.take(5), p.queue);
      expect(r.queue.skip(5), [100, 101]);
      expect(r.done, 1);
      expect(r.remaining, 7);
      expectInvariant(r, 8);
    });

    test('unknown persisted ids are ignored without error', () {
      const stale = StudyProgress(
        queue: [999, 1],
        known: [888],
        repeatIds: [999, 1],
      );
      final r = StudyDeck.reconcile(stale, questions, random: Random(1));
      expect(r.queue.first, 1);
      expect(r.known, isEmpty);
      expect(r.repeatIds, [1], reason: 'only still-active ids stay in Repeat');
      expectInvariant(r, 6);
    });

    test('a changed choice set regenerates or drops that order', () {
      final stored = StudyDeck.create(
        questions,
        random: Random(1),
        shuffleChoices: true,
      );
      final edited = [
        for (final q in questions)
          if (q.id == 1)
            QuestionItemEntity(
              id: 1,
              questionText: q.questionText,
              choices: q.choices.take(2).toList(),
            )
          else
            q,
      ];
      final r = StudyDeck.reconcile(stored, edited, random: Random(1));
      expect(r.choiceOrders[1]!.length, 2);
      expect(r.choiceOrders[2], stored.choiceOrders[2]);
    });

    test('no stored progress creates a fresh deck', () {
      final r = StudyDeck.reconcile(null, questions, random: Random(1));
      expect(r.queue, ids);
    });
  });

  group('serialization', () {
    test('round trips', () {
      var p = StudyDeck.create(
        questions,
        random: Random(1),
        shuffleQuestions: true,
        shuffleChoices: true,
      );
      p = StudyDeck.alreadyKnow(StudyDeck.studyAgain(p));
      final back = StudyProgress.tryParse(p.toJsonString())!;
      expect(back.queue, p.queue);
      expect(back.known, p.known);
      expect(back.repeat, p.repeat);
      expect(back.shuffleQuestions, isTrue);
      expect(back.shuffleChoices, isTrue);
      expect(back.choiceOrders, p.choiceOrders);
    });

    test('corrupt or inconsistent data is rejected, not thrown', () {
      for (final raw in [
        null,
        '',
        'not json',
        '[]',
        '{"v":2}',
        '{"v":1,"queue":"x","known":[],"repeat":0,"choiceOrders":{}}',
        '{"v":1,"queue":[1,1],"known":[],"repeat":0,"choiceOrders":{}}',
        '{"v":1,"queue":[1],"known":[1],"repeat":0,"choiceOrders":{}}',
        '{"v":1,"queue":[1],"known":[],"choiceOrders":"x"}',
      ]) {
        expect(StudyProgress.tryParse(raw), isNull, reason: '$raw');
      }
    });
  });

  group('eligible question builder', () {
    List<Map<String, dynamic>> qrows(List<int> ids) => [
      for (final id in ids) {'id': id, 'question_text': 'q$id'},
    ];

    test(
      'keeps only questions with text and a correct choice, sorted by id',
      () {
        final built = buildStudyQuestions(
          questionRows: [
            ...qrows([3, 1, 2, 4]),
            {'id': 5, 'question_text': '  '},
          ],
          choiceRows: [
            {
              'id': 12,
              'question_id': 1,
              'choice_text': 'b',
              'is_correct': false,
            },
            {
              'id': 11,
              'question_id': 1,
              'choice_text': 'a',
              'is_correct': true,
            },
            {
              'id': 21,
              'question_id': 2,
              'choice_text': 'a',
              'is_correct': false,
            },
            {
              'id': 31,
              'question_id': 3,
              'choice_text': 'a',
              'is_correct': true,
            },
            {
              'id': 51,
              'question_id': 5,
              'choice_text': 'a',
              'is_correct': true,
            },
          ],
        );
        expect(built.map((q) => q.id), [1, 3]); // 2 no correct, 4 no choices
        expect(built.first.choices.map((c) => c.id), [11, 12]);
      },
    );

    test(
      'duplicate ids collapse and the stored rationale is read verbatim',
      () {
        final built = buildStudyQuestions(
          questionRows: [
            {'id': 1, 'question_text': 'a', 'rationale': 'Real explanation'},
            {'id': 1, 'question_text': 'dup'},
            {
              'id': 2,
              'question_text': 'b',
              'explanation': 'Ignored legacy column',
            },
            {'id': 3, 'question_text': 'c'},
          ],
          choiceRows: [
            for (final id in [1, 2, 3])
              {
                'id': id * 10,
                'question_id': id,
                'choice_text': 'x',
                'is_correct': true,
              },
          ],
        );
        expect(built.map((q) => q.id), [1, 2, 3]);
        expect(built[0].questionText, 'a');
        expect(built[0].rationale, 'Real explanation');
        // `rationale` is the only authoritative field.
        expect(built[1].rationale, isEmpty);
        expect(built[2].rationale, isEmpty);
      },
    );
  });
}
