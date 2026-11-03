import 'dart:math';

import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';

/// Deterministic once-per-calendar-day Question of the Day selection.
///
/// The "day" always rolls over at midnight UTC+8 (the application timezone),
/// matching the Daily Motivation cycle so both features turn over together.
/// Given the same [now] and the same eligible lists, every method returns the
/// same result, which keeps the daily question stable while the app is running
/// and predictable across app restarts and devices.
class QuestionOfTheDayPicker {
  const QuestionOfTheDayPicker._();

  /// UTC+8 offset shared with [DailyMotivationPicker].
  static const appUtcOffset = Duration(hours: 8);

  /// yyyy-MM-dd of [now] in the application timezone.
  static String dayKey(DateTime now) => DailyMotivationPicker.dayKey(now);

  /// Whole number of application-timezone days since the epoch.
  static int dayNumber(DateTime now) => DailyMotivationPicker.dayNumber(now);

  /// Index of the subject shown on the day containing [now], rotating through
  /// [eligibleSubjectCount] subjects. Subjects must be supplied in the stable
  /// order used by the app (created_at, then id).
  static int subjectIndex(DateTime now, int eligibleSubjectCount) {
    if (eligibleSubjectCount <= 0) return 0;
    return dayNumber(now) % eligibleSubjectCount;
  }

  /// Index of the question selected from a subject's eligible questions.
  /// Questions must be supplied in ascending id order; [eligibleQuestionCount]
  /// is the number of questions that have at least one option.
  static int questionIndex(DateTime now, int eligibleQuestionCount) {
    if (eligibleQuestionCount <= 0) return 0;
    return dayNumber(now) % eligibleQuestionCount;
  }

  /// Picks the day's question from [liveIds] (ascending ids of live questions)
  /// without loading them all: starts at the deterministic index for [now] and
  /// checks small windows with [filterEligible], wrapping around, so a
  /// malformed question simply hands the day to the next eligible one. The
  /// result is stable for the same data. Null when nothing is eligible.
  static Future<int?> pickEligibleQuestionId({
    required DateTime now,
    required List<int> liveIds,
    required Future<Set<int>> Function(List<int> ids) filterEligible,
    int window = 25,
  }) async {
    if (liveIds.isEmpty) return null;
    final start = questionIndex(now, liveIds.length);
    for (var offset = 0; offset < liveIds.length; offset += window) {
      final size = min(window, liveIds.length - offset);
      final chunk = [
        for (var i = 0; i < size; i++)
          liveIds[(start + offset + i) % liveIds.length],
      ];
      final eligible = await filterEligible(chunk);
      for (final id in chunk) {
        if (eligible.contains(id)) return id;
      }
    }
    return null;
  }

  /// Same rotation as [pickEligibleQuestionId], with bounded server pages
  /// instead of downloading every question ID in a subject.
  static Future<int?> pickEligibleQuestionIdPaged({
    required DateTime now,
    required int questionCount,
    required Future<List<({int id, bool eligible})>> Function(
      int start,
      int size,
    )
    loadPage,
    int window = 25,
  }) async {
    if (questionCount <= 0) return null;
    if (window <= 0) throw ArgumentError.value(window, 'window');
    final start = questionIndex(now, questionCount);
    var checked = 0;
    while (checked < questionCount) {
      final offset = (start + checked) % questionCount;
      final size = min(
        window,
        min(questionCount - offset, questionCount - checked),
      );
      final page = await loadPage(offset, size);
      for (final question in page) {
        if (question.eligible) return question.id;
      }
      checked += size;
    }
    return null;
  }

  /// UTC instant at which the application-timezone day containing [now] starts
  /// (midnight UTC+8). `answered_at` values inside
  /// `[dayStartUtc, dayStartUtc + 1 day)` belong to this daily cycle, so a
  /// stale answer from a previous day is never restored onto today's question.
  static DateTime dayStartUtc(DateTime now) {
    final d = now.toUtc().add(appUtcOffset);
    return DateTime.utc(d.year, d.month, d.day).subtract(appUtcOffset);
  }

  /// UTC instant at which the application-timezone day containing [now] ends.
  static DateTime dayEndUtc(DateTime now) =>
      dayStartUtc(now).add(const Duration(days: 1));
}
