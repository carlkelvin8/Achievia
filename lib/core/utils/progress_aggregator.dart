import 'package:achievia/core/utils/achievia_grading.dart'
    show bracketForPercentage;
import 'package:achievia/core/utils/subject_performance.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';

ProgressEntity aggregateProgress({
  required ProgressSnapshotDto snapshot,
  required DateTime startDate,
  required DateTime today,
}) {
  final attempts =
      snapshot.quizAttempts
          .where(
            (row) =>
                DateTime.tryParse(row['attempted_at']?.toString() ?? '') !=
                    null &&
                _score(row['score']) != null,
          )
          .toList()
        ..sort(
          (a, b) =>
              _date(a['attempted_at']).compareTo(_date(b['attempted_at'])),
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
  final bracket = bracketForPercentage(currentScore);

  // The per-subject graph uses only completed individual subject exams
  // (Question Bank, attempt_type = subject_exam), never Mock Board subject
  // breakdowns or practice attempts.
  final subjectHistory = _subjectHistoryFromSubjectExams(
    snapshot.subjectExamAttempts,
  );
  // Best/Weakest use only completed individual subject exams (Question Bank),
  // never Mock Board subject breakdowns.
  final performance = summarizeSubjectPerformance(
    snapshot.subjectExamAttempts
        .map(SubjectExamAttempt.tryFromRow)
        .whereType<SubjectExamAttempt>(),
  );
  final best = performance.best;
  final weakest = performance.weakest;

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
    // Calendar-day step: adding 24h to a local date drifts across DST changes.
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1)
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

  final streak = _longestStreakInMonth(
    days
        .where(
          (d) =>
              d.date.year == normalizedToday.year &&
              d.date.month == normalizedToday.month,
        )
        .toList(),
  );
  return ProgressEntity(
    currentScore: currentScore,
    level: bracket.level,
    message: bracket.message,
    strengthWeakness: StrengthWeakness(
      bestSubject: best?.subjectName ?? 'N/A',
      bestAverage: best?.averagePercentage ?? 0,
      weakestSubject: weakest?.subjectName ?? 'N/A',
      weakestAverage: weakest?.averagePercentage ?? 0,
    ),
    scoreHistory: history,
    subjectHistory: subjectHistory,
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

/// Groups Question Bank subject exam rows by subject id and returns one
/// chronologically sorted history line per subject, keyed by display name.
///
/// Grouping by the stable subject id means a renamed subject stays on the same
/// line, while two different subjects that happen to share a display name are
/// kept apart (the later one is suffixed with its id).
Map<String, List<ScoreData>> _subjectHistoryFromSubjectExams(
  List<Map<String, dynamic>> rows,
) {
  final byId = <int, List<SubjectExamAttempt>>{};
  final seenAttemptIds = <String>{};
  for (final attempt
      in rows
          .map(SubjectExamAttempt.tryFromRow)
          .whereType<SubjectExamAttempt>()) {
    if (attempt.id.isNotEmpty && !seenAttemptIds.add(attempt.id)) continue;
    byId.putIfAbsent(attempt.subjectId, () => []).add(attempt);
  }

  final result = <String, List<ScoreData>>{};
  final claimedLabels = <String, int>{};
  byId.forEach((id, attempts) {
    var latest = attempts.first;
    for (final attempt in attempts) {
      if (attempt.completedAt.isAfter(latest.completedAt)) latest = attempt;
    }
    final preferred = latest.subjectName.isNotEmpty
        ? latest.subjectName
        : attempts
              .map((attempt) => attempt.subjectName)
              .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    if (preferred.isEmpty) return;

    var label = preferred;
    final claimedBy = claimedLabels[label];
    if (claimedBy != null && claimedBy != id) {
      label = '$preferred ($id)';
    }
    claimedLabels[label] = id;

    final sorted = [...attempts]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    result[label] = [
      for (final attempt in sorted)
        ScoreData(date: attempt.completedAt, score: attempt.percentage),
    ];
  });
  return result;
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
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

double? _score(Object? value) {
  final score = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return score != null && score.isFinite && score >= 0 && score <= 100
      ? score
      : null;
}

int _max(int left, int right) => left > right ? left : right;
int _min(int left, int right) => left < right ? left : right;

/// Longest consecutive run of completed days within a given list.
/// Used for both "this month's streak" (month-scoped) and all-time longest.
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

/// Longest consecutive streak within a single calendar month.
int _longestStreakInMonth(List<CalendarDay> monthDays) =>
    _longestStreak(monthDays);
