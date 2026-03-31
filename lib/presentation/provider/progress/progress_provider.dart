import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';

final progressProvider = Provider<ProgressEntity>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    return demoProgressData;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdRaw = profile.createdAt ?? today;
  final createdAt = DateTime(createdRaw.year, createdRaw.month, createdRaw.day);
  final startDate = createdAt.isAfter(today) ? today : createdAt;

  final days = _buildCalendarDays(
    startDate: startDate,
    today: today,
    thisMonthStreak: demoProgressData.calendarData.thisMonthStreak,
  );
  final thisMonthStreak = _calculateCurrentStreak(days, today);
  final longestStreak = _calculateLongestStreak(days);

  return demoProgressData.copyWith(
    calendarData: CalendarData(
      currentMonth: DateTime(today.year, today.month),
      thisMonthStreak: thisMonthStreak,
      longestStreak: longestStreak,
      days: days,
    ),
  );
});

List<CalendarDay> _buildCalendarDays({
  required DateTime startDate,
  required DateTime today,
  required int thisMonthStreak,
}) {
  final days = <CalendarDay>[];
  final completedStart = DateTime(
    today.year,
    today.month,
    (today.day - thisMonthStreak + 1).clamp(1, today.day),
  );

  DateTime cursor = startDate;
  while (!cursor.isAfter(today)) {
    final dayOnly = DateTime(cursor.year, cursor.month, cursor.day);

    final isCurrentMonth =
        dayOnly.year == today.year && dayOnly.month == today.month;
    final isCompleted =
        isCurrentMonth &&
        !dayOnly.isBefore(completedStart) &&
        !dayOnly.isAfter(today);

    days.add(
      CalendarDay(
        date: dayOnly,
        status: isCompleted ? DayStatus.completed : DayStatus.current,
      ),
    );

    cursor = cursor.add(const Duration(days: 1));
  }

  return days;
}

int _calculateCurrentStreak(List<CalendarDay> days, DateTime today) {
  if (days.isEmpty) return 0;

  final todayOnly = DateTime(today.year, today.month, today.day);
  final last = days.last;
  final lastDate = DateTime(last.date.year, last.date.month, last.date.day);

  // If today's activity is not completed, streak is broken.
  if (lastDate != todayOnly || last.status != DayStatus.completed) {
    return 0;
  }

  int streak = 0;
  for (int i = days.length - 1; i >= 0; i--) {
    if (days[i].status == DayStatus.completed) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int _calculateLongestStreak(List<CalendarDay> days) {
  int current = 0;
  int longest = 0;

  for (final day in days) {
    if (day.status == DayStatus.completed) {
      current++;
      if (current > longest) {
        longest = current;
      }
    } else {
      current = 0;
    }
  }

  return longest;
}

// Grading brackets provider - uses data from helpers.dart
final gradingBracketsProvider = Provider<List<GradingBracket>>((ref) {
  return gradingBrackets;
});
