import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-03-10 15:59 UTC is 23:59 in UTC+8; 16:00 UTC is the next app day.
  final lastMinuteOfDay = DateTime.utc(2026, 3, 10, 15, 59);
  final firstMinuteOfNextDay = DateTime.utc(2026, 3, 10, 16);

  group('day cycle is shared with Daily Motivation', () {
    test('dayKey matches DailyMotivationPicker', () {
      expect(
        QuestionOfTheDayPicker.dayKey(lastMinuteOfDay),
        DailyMotivationPicker.dayKey(lastMinuteOfDay),
      );
      expect(
        QuestionOfTheDayPicker.dayKey(firstMinuteOfNextDay),
        DailyMotivationPicker.dayKey(firstMinuteOfNextDay),
      );
    });

    test('dayKey rolls over at midnight UTC+8, not at device midnight', () {
      expect(QuestionOfTheDayPicker.dayKey(lastMinuteOfDay), '2026-03-10');
      expect(QuestionOfTheDayPicker.dayKey(firstMinuteOfNextDay), '2026-03-11');
    });

    test('a device-local midnight does not change the app day', () {
      final utcMidnight = DateTime.utc(2026, 3, 10, 0);
      expect(QuestionOfTheDayPicker.dayKey(utcMidnight), '2026-03-10');
    });

    test('dayNumber is stable within a day and increments the next day', () {
      final morning = DateTime.utc(2026, 3, 10, 1);
      expect(
        QuestionOfTheDayPicker.dayNumber(morning),
        QuestionOfTheDayPicker.dayNumber(lastMinuteOfDay),
      );
      expect(
        QuestionOfTheDayPicker.dayNumber(firstMinuteOfNextDay),
        QuestionOfTheDayPicker.dayNumber(morning) + 1,
      );
    });
  });

  group('deterministic indexes', () {
    test('subjectIndex is stable for the whole day', () {
      final morning = DateTime.utc(2026, 3, 10, 1);
      expect(
        QuestionOfTheDayPicker.subjectIndex(morning, 3),
        QuestionOfTheDayPicker.subjectIndex(lastMinuteOfDay, 3),
      );
    });

    test('subjectIndex rotates to the next subject the next day', () {
      expect(
        QuestionOfTheDayPicker.subjectIndex(firstMinuteOfNextDay, 3),
        (QuestionOfTheDayPicker.subjectIndex(lastMinuteOfDay, 3) + 1) % 3,
      );
    });

    test('subjectIndex with a single subject always returns 0', () {
      expect(QuestionOfTheDayPicker.subjectIndex(lastMinuteOfDay, 1), 0);
    });

    test('questionIndex is stable for the whole day', () {
      final morning = DateTime.utc(2026, 3, 10, 1);
      expect(
        QuestionOfTheDayPicker.questionIndex(morning, 7),
        QuestionOfTheDayPicker.questionIndex(lastMinuteOfDay, 7),
      );
    });

    test('questionIndex rotates the next day', () {
      expect(
        QuestionOfTheDayPicker.questionIndex(firstMinuteOfNextDay, 7),
        (QuestionOfTheDayPicker.questionIndex(lastMinuteOfDay, 7) + 1) % 7,
      );
    });

    test('empty and single-element lists never divide by zero', () {
      expect(QuestionOfTheDayPicker.subjectIndex(lastMinuteOfDay, 0), 0);
      expect(QuestionOfTheDayPicker.questionIndex(lastMinuteOfDay, 0), 0);
      expect(QuestionOfTheDayPicker.subjectIndex(lastMinuteOfDay, -1), 0);
      expect(QuestionOfTheDayPicker.questionIndex(lastMinuteOfDay, -1), 0);
    });
  });

  group('day window used to scope the persisted answer', () {
    test('dayStartUtc is midnight UTC+8 expressed in UTC', () {
      expect(
        QuestionOfTheDayPicker.dayStartUtc(lastMinuteOfDay),
        DateTime.utc(2026, 3, 9, 16),
      );
    });

    test('the window covers exactly one app day', () {
      final start = QuestionOfTheDayPicker.dayStartUtc(lastMinuteOfDay);
      final end = QuestionOfTheDayPicker.dayEndUtc(lastMinuteOfDay);
      expect(end.difference(start), const Duration(days: 1));
    });

    test('the next app day starts a new window', () {
      expect(
        QuestionOfTheDayPicker.dayStartUtc(firstMinuteOfNextDay),
        DateTime.utc(2026, 3, 10, 16),
      );
    });

    test('an answer from the previous day falls outside today\'s window', () {
      final start = QuestionOfTheDayPicker.dayStartUtc(lastMinuteOfDay);
      final end = QuestionOfTheDayPicker.dayEndUtc(lastMinuteOfDay);
      expect(start.isBefore(lastMinuteOfDay), isTrue);
      expect(lastMinuteOfDay.isBefore(end), isTrue);
      // The next app day starts exactly when this window closes.
      expect(firstMinuteOfNextDay.isBefore(end), isFalse);
    });
  });
}
