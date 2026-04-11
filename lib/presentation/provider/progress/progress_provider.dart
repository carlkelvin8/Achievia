import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/use_cases/progress/progress_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';

final progressUseCaseProvider = Provider<ProgressUseCase>((ref) {
  return sl<ProgressUseCase>();
});

final progressProvider = FutureProvider.autoDispose<ProgressEntity>((ref) async {
  final token = ref.watch(tokenStream).value;
  if (token == null || token.isEmpty) {
    return demoProgressData;
  }

  final profile = await ref.watch(profileProvider.future);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdRaw = profile.createdAt ?? today;
  final createdAt = DateTime(createdRaw.year, createdRaw.month, createdRaw.day);
  final startDate = createdAt.isAfter(today) ? today : createdAt;

  final useCase = ref.read(progressUseCaseProvider);
  final activeDays = await useCase.getActiveDays();
  final activeDayKeys = activeDays
      .where((d) => d.isActive)
      .map((d) => _dateKey(d.activityDate))
      .toSet();
  final todayKey = _dateKey(today);

  // Avoid an extra write call when today's activity is already recorded.
  if (!activeDayKeys.contains(todayKey)) {
    await useCase.markTodayActive();
    activeDayKeys.add(todayKey);
  }

  final days = _buildCalendarDays(
    startDate: startDate,
    today: today,
    activeDayKeys: activeDayKeys,
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
  required Set<String> activeDayKeys,
}) {
  final days = <CalendarDay>[];

  DateTime cursor = startDate;
  while (!cursor.isAfter(today)) {
    final dayOnly = DateTime(cursor.year, cursor.month, cursor.day);
    final isCompleted = activeDayKeys.contains(_dateKey(dayOnly));

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

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
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
