import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/presentation/provider/questions/mock_board_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

MockBoardSession _session(int questionId) => MockBoardSession(
  clientAttemptId: 'attempt-$questionId',
  board: [
    {
      'id': 1,
      'title': 'Clinical Chemistry',
      'description': '',
      'createdAt': '',
      'subjectId': 9,
      'questions': [
        {
          'id': questionId,
          'questionText': 'Full question text that is not stored',
          'choices': [
            {'id': 11, 'choiceText': 'A', 'isCorrect': true},
            {'id': 12, 'choiceText': 'B', 'isCorrect': false},
          ],
        },
      ],
    },
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps the ids and picks of an attempt, per user', () async {
    const store = MockBoardReviewStore();
    await store.save('u1', 7, _session(500), {'1:500': 1});

    final kept = await store.load('u1', 7);
    expect(kept, isNotNull);
    expect(kept!.answers, {'1:500': 1});
    final question =
        ((kept.compact['sections'] as List).single as Map)['questions'] as List;
    expect(question.single, {
      'id': 500,
      'choices': [11, 12],
    });
    // Only ids: the content is downloaded again when the Summary opens.
    expect(kept.compact.toString(), isNot(contains('Full question text')));

    expect(await store.load('u2', 7), isNull);
    expect(await store.load('u1', 8), isNull);
  });

  test('keeps only the newest attempts', () async {
    const store = MockBoardReviewStore();
    for (var no = 1; no <= MockBoardReviewStore.keep + 2; no++) {
      await store.save('u1', no, _session(no), {'1:$no': 0});
    }
    expect(await store.load('u1', 1), isNull);
    expect(await store.load('u1', 2), isNull);
    expect(await store.load('u1', 3), isNotNull);
    expect(await store.load('u1', MockBoardReviewStore.keep + 2), isNotNull);
  });
}
