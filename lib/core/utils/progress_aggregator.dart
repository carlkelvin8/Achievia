import 'dart:convert';

import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';

ProgressEntity aggregateProgress({
  required ProgressSnapshotDto snapshot,
  required DateTime startDate,
  required DateTime today,
}) {
  final attempts = [...snapshot.quizAttempts]
    ..sort(
      (a, b) => _date(a['attempted_at']).compareTo(_date(b['attempted_at'])),
    );
  final history = attempts
      .map(
        (row) => ScoreData(
          date: _date(row['attempted_at']),
          score: _number(row['score']),
        ),
      )
      .toList();
  final currentScore = history.isEmpty ? 0.0 : history.last.score;
  final bracket = _bracketFor(currentScore);

  final subjectScores = <String, List<double>>{};
  for (final attempt in attempts) {
    final rawAnswers = attempt['answer'] ?? attempt['summary'];
    final decoded = rawAnswers is String ? _decode(rawAnswers) : rawAnswers;
    if (decoded is! List) continue;
    for (final rawAnswer in decoded) {
      if (rawAnswer is! Map) continue;
      final answer = Map<String, dynamic>.from(rawAnswer);
      final name = answer['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      subjectScores.putIfAbsent(name, () => []).add(_number(answer['score']));
    }
  }
  final averages = subjectScores.map(
    (name, values) => MapEntry(
      name,
      values.reduce((left, right) => left + right) / values.length,
    ),
  );
  final best = _extreme(averages, highest: true);
  final weakest = _extreme(averages, highest: false);

  final dailyMinutes = <String, int>{};
  for (final session in snapshot.studySessions) {
    final date = _date(session['started_at']);
    final key = _dateKey(date);
    dailyMinutes[key] =
        (dailyMinutes[key] ?? 0) + _number(session['duration_minutes']).round();
  }
  final dailyBreakdown =
      dailyMinutes.entries
          .map(
            (entry) => DailyScreentime(
              date: DateTime.parse(entry.key),
              minutes: entry.value,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final minuteValues = dailyBreakdown.map((item) => item.minutes).toList();

  final activeKeys = snapshot.activeDays
      .where((day) => day.isActive)
      .map((day) => _dateKey(day.activityDate))
      .toSet();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedStart = DateTime(
    startDate.year,
    startDate.month,
    startDate.day,
  );
  final days = <CalendarDay>[];
  for (
    var cursor = normalizedStart;
    !cursor.isAfter(normalizedToday);
    cursor = cursor.add(const Duration(days: 1))
  ) {
    days.add(
      CalendarDay(
        date: cursor,
        status: activeKeys.contains(_dateKey(cursor))
            ? DayStatus.completed
            : DayStatus.inactive,
      ),
    );
  }

  final streak = _currentStreak(activeKeys, normalizedToday);
  return ProgressEntity(
    currentScore: currentScore,
    level: bracket.$1,
    message: bracket.$2,
    strengthWeakness: StrengthWeakness(
      bestSubject: best?.key ?? 'N/A',
      bestAverage: best?.value ?? 0,
      weakestSubject: weakest?.key ?? 'N/A',
      weakestAverage: weakest?.value ?? 0,
    ),
    scoreHistory: history,
    screentimeData: ScreentimeData(
      dailyAverage: minuteValues.isEmpty
          ? 0
          : (minuteValues.reduce((a, b) => a + b) / minuteValues.length)
                .round(),
      longestScreentime: minuteValues.isEmpty ? 0 : minuteValues.reduce(_max),
      shortestScreentime: minuteValues.isEmpty ? 0 : minuteValues.reduce(_min),
      dailyBreakdown: dailyBreakdown,
    ),
    calendarData: CalendarData(
      currentMonth: DateTime(normalizedToday.year, normalizedToday.month),
      thisMonthStreak: streak,
      longestStreak: _longestStreak(days),
      days: days,
    ),
  );
}

MapEntry<String, double>? _extreme(
  Map<String, double> values, {
  required bool highest,
}) {
  if (values.isEmpty) return null;
  return values.entries.reduce(
    (left, right) => highest
        ? (left.value >= right.value ? left : right)
        : (left.value <= right.value ? left : right),
  );
}

List<dynamic>? _decode(String value) {
  try {
    final decoded = jsonDecode(value);
    return decoded is List ? decoded : null;
  } catch (_) {
    return null;
  }
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

String _dateKey(DateTime value) => DateTime(
  value.year,
  value.month,
  value.day,
).toIso8601String().split('T').first;

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _max(int left, int right) => left > right ? left : right;
int _min(int left, int right) => left < right ? left : right;

int _currentStreak(Set<String> activeKeys, DateTime today) {
  var cursor = today;
  var count = 0;
  while (activeKeys.contains(_dateKey(cursor))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

int _longestStreak(List<CalendarDay> days) {
  var current = 0;
  var longest = 0;
  for (final day in days) {
    if (day.status == DayStatus.completed) {
      current++;
      longest = _max(longest, current);
    } else {
      current = 0;
    }
  }
  return longest;
}

(String, String) _bracketFor(double score) {
  if (score >= 90) {
    return (
      'Achievian Topnotcher Potential',
      'Excellent work! Keep pushing and stay sharp.',
    );
  }
  if (score >= 85) {
    return ('Board Ready', 'You\'re nearly there. Sharpen your details.');
  }
  if (score >= 75) {
    return (
      'Solid Achievian',
      'Strong performance! Focus on high-yield topics.',
    );
  }
  if (score >= 65) {
    return ('Almost There', 'You\'re on the right track. Keep practicing.');
  }
  if (score >= 50) {
    return ('Warming Up', 'Strengthen weak areas and stay consistent.');
  }
  return (
    'Recharge & Refocus',
    'Revisit the basics and rebuild your foundation.',
  );
}
