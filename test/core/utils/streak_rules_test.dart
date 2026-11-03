import 'package:achievia/core/utils/streak_rules.dart';
import 'package:achievia/data/models/progress/progress_day_dto.dart';
import 'package:flutter_test/flutter_test.dart';

ProgressDayDto _day(int id, DateTime date) =>
    ProgressDayDto(id: id, userId: 'u', activityDate: date, isActive: true);

void main() {
  final today = DateTime(2026, 10, 20);

  test('only 60 minutes or more of use turns the day blue', () {
    for (final minutes in [0, 5, 30, 59]) {
      expect(metDailyStreak(minutes * 60), isFalse, reason: '$minutes min');
    }
    expect(metDailyStreak(59 * 60 + 59), isFalse);
    for (final minutes in [60, 90]) {
      expect(metDailyStreak(minutes * 60), isTrue, reason: '$minutes min');
    }
  });

  test('usage added up over several sessions counts (20 min + 40 min)', () {
    expect(metDailyStreak((20 + 40) * 60), isTrue);
  });

  test('today stays white below 60 minutes, even with a stored row', () {
    final days = applyDailyUsageRule(
      days: [_day(1, today)],
      today: today,
      todaySeconds: 59 * 60,
    );
    expect(days, isEmpty);
  });

  test('today turns blue at 60 minutes, with or without a stored row', () {
    final fresh = applyDailyUsageRule(
      days: const [],
      today: today,
      todaySeconds: 60 * 60,
    );
    expect(fresh.single.activityDate, today);
    expect(fresh.single.isActive, isTrue);

    final stored = applyDailyUsageRule(
      days: [_day(7, today)],
      today: today,
      todaySeconds: 90 * 60,
    );
    expect(stored.single.id, 7);
  });

  test('earlier days keep their blue icon and missed days stay white', () {
    final yesterday = DateTime(2026, 10, 19);
    final days = applyDailyUsageRule(
      days: [_day(1, yesterday)],
      today: today,
      todaySeconds: 5 * 60,
    );
    expect(days.map((day) => day.activityDate), [yesterday]);
  });

  test('a new day starts again from zero', () {
    final tomorrow = DateTime(2026, 10, 21);
    final days = applyDailyUsageRule(
      days: [_day(1, today)],
      today: tomorrow,
      todaySeconds: 0,
    );
    expect(days.map((day) => day.activityDate), [today]);
  });
}
