import 'package:achievia/data/models/progress/progress_day_dto.dart';

/// A day counts toward the Daily Streak only after this much active (foreground)
/// app use, added up across the whole day.
const int kStreakRequiredSeconds = 60 * 60;

bool metDailyStreak(int activeSeconds) =>
    activeSeconds >= kStreakRequiredSeconds;

String streakDayKey(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).toIso8601String().split('T').first;

/// The stored active days with today decided by the 60-minute rule.
///
/// Earlier days are kept exactly as stored, so a streak already earned stays
/// blue. Today is blue once [todaySeconds] reaches the requirement and white
/// until then, whatever a stored row for today says.
List<ProgressDayDto> applyDailyUsageRule({
  required List<ProgressDayDto> days,
  required DateTime today,
  required int todaySeconds,
}) {
  final todayKey = streakDayKey(today);
  final others = days.where(
    (day) => streakDayKey(day.activityDate) != todayKey,
  );
  if (!metDailyStreak(todaySeconds)) return others.toList();
  final stored = days.where(
    (day) => streakDayKey(day.activityDate) == todayKey,
  );
  return [
    ...others,
    stored.isNotEmpty
        ? stored.first
        : ProgressDayDto(
            id: 0,
            userId: '',
            activityDate: DateTime(today.year, today.month, today.day),
            isActive: true,
          ),
  ];
}
