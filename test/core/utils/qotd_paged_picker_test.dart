import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 13, 2);

  test(
    'a large subject loads at most 25 candidate IDs on the usual path',
    () async {
      const count = 100003;
      final pages = <(int, int)>[];
      final selected = await QuestionOfTheDayPicker.pickEligibleQuestionIdPaged(
        now: now,
        questionCount: count,
        loadPage: (start, size) async {
          pages.add((start, size));
          return [
            for (var i = start; i < start + size; i++)
              (id: i + 1, eligible: true),
          ];
        },
      );
      final start = QuestionOfTheDayPicker.questionIndex(now, count);
      expect(selected, start + 1);
      expect(pages, [(start, 25)]);
    },
  );

  test(
    'paged selection matches the existing rotation, including wraparound',
    () async {
      for (final count in [1, 17, 47, 103]) {
        final ids = [for (var i = 0; i < count; i++) i * 3 + 10];
        final start = QuestionOfTheDayPicker.questionIndex(now, count);
        final eligible = {ids[(start + count - 1) % count]};
        final oldResult = await QuestionOfTheDayPicker.pickEligibleQuestionId(
          now: now,
          liveIds: ids,
          filterEligible: (chunk) async => chunk.toSet().intersection(eligible),
        );
        final seen = <int>[];
        final newResult =
            await QuestionOfTheDayPicker.pickEligibleQuestionIdPaged(
              now: now,
              questionCount: count,
              window: 5,
              loadPage: (offset, size) async {
                final page = ids.sublist(offset, offset + size);
                seen.addAll(page);
                return [
                  for (final id in page)
                    (id: id, eligible: eligible.contains(id)),
                ];
              },
            );
        expect(newResult, oldResult);
        expect(seen.toSet().length, seen.length);
        expect(seen.length, count);
      }
    },
  );

  test(
    'empty or entirely malformed subjects return no daily question',
    () async {
      var calls = 0;
      for (final count in [0, 31]) {
        final result = await QuestionOfTheDayPicker.pickEligibleQuestionIdPaged(
          now: now,
          questionCount: count,
          loadPage: (offset, size) async {
            calls++;
            return [
              for (var i = offset; i < offset + size; i++)
                (id: i, eligible: false),
            ];
          },
        );
        expect(result, isNull);
        if (count == 0) expect(calls, 0);
      }
    },
  );
}
