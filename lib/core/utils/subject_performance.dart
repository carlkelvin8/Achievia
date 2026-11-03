import 'package:flutter/foundation.dart';

/// One completed Take an Exam subject exam (`attempt_type = subject_exam`).
class SubjectExamAttempt {
  /// Stable row id of the `question_bank_attempts` record, when available.
  final String id;
  final int subjectId;
  final String subjectName;
  final double percentage;
  final DateTime completedAt;

  const SubjectExamAttempt({
    this.id = '',
    required this.subjectId,
    required this.subjectName,
    required this.percentage,
    required this.completedAt,
  });

  /// Builds an attempt from a `question_bank_attempts` row joined with
  /// `subjects(title)`. Returns null (and logs) when the row cannot yield a
  /// trustworthy percentage: missing subject id/name, missing counts, zero
  /// or invalid totals, or an invalid completion timestamp.
  static SubjectExamAttempt? tryFromRow(Map<String, dynamic> row) {
    // Only official Take an Exam attempts count; subtopic practice does not.
    if (row['attempt_type'] != 'subject_exam') return null;
    final subjectId = _int(row['subject_id']);
    final correct = _int(row['correct_answers']);
    final total = _int(row['total_questions']);
    final completedAt = DateTime.tryParse(
      row['completed_at']?.toString() ?? '',
    );
    final name = _title(row['subjects']);

    String? problem;
    if (subjectId == null) {
      problem = 'missing subject id';
    } else if (correct == null || total == null) {
      problem = 'missing correct/total';
    } else if (total <= 0 || correct < 0 || correct > total) {
      problem = 'invalid counts $correct/$total';
    } else if (completedAt == null) {
      problem = 'invalid completed_at';
    }
    if (problem != null) {
      debugPrint('SubjectPerformance: skipped attempt ($problem)');
      return null;
    }
    return SubjectExamAttempt(
      id: (row['id'] ?? '').toString(),
      subjectId: subjectId!,
      subjectName: name,
      // The stored final percentage is authoritative; recomputing from counts
      // is only a fallback for rows saved before the column existed.
      percentage: _storedScore(row['score']) ?? correct! / total! * 100,
      completedAt: completedAt!,
    );
  }

  static double? _storedScore(Object? value) {
    final score = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (score == null || !score.isFinite || score < 0 || score > 100) {
      return null;
    }
    return score;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _title(Object? relation) {
    final Object? title = relation is Map
        ? relation['title']
        : (relation is List && relation.isNotEmpty && relation.first is Map)
        ? (relation.first as Map)['title']
        : null;
    return title?.toString().trim() ?? '';
  }
}

class SubjectPerformance {
  final int subjectId;
  final String subjectName;

  /// Arithmetic mean of attempt percentages, at full precision.
  final double averagePercentage;
  final int completedExamCount;
  final DateTime latestCompletedExamAt;

  const SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    required this.averagePercentage,
    required this.completedExamCount,
    required this.latestCompletedExamAt,
  });
}

class SubjectPerformanceSummary {
  final SubjectPerformance? best;

  /// Only set once at least two different subjects have data.
  final SubjectPerformance? weakest;

  const SubjectPerformanceSummary({this.best, this.weakest});
}

/// Single source of truth for Best / Weakest Subject.
///
/// Attempts are grouped by subject id; each subject's score is the mean of its
/// attempt percentages (not weighted by question count).
SubjectPerformanceSummary summarizeSubjectPerformance(
  Iterable<SubjectExamAttempt> attempts,
) {
  final grouped = <int, List<SubjectExamAttempt>>{};
  for (final attempt in attempts) {
    grouped.putIfAbsent(attempt.subjectId, () => []).add(attempt);
  }

  final subjects = <SubjectPerformance>[];
  grouped.forEach((id, list) {
    var latest = list.first;
    var sum = 0.0;
    for (final attempt in list) {
      sum += attempt.percentage;
      if (attempt.completedAt.isAfter(latest.completedAt)) latest = attempt;
    }
    final name = latest.subjectName.isNotEmpty
        ? latest.subjectName
        : list
              .map((a) => a.subjectName)
              .firstWhere((n) => n.isNotEmpty, orElse: () => '');
    if (name.isEmpty) {
      debugPrint('SubjectPerformance: subject $id has no name; skipped');
      return;
    }
    subjects.add(
      SubjectPerformance(
        subjectId: id,
        subjectName: name,
        averagePercentage: sum / list.length,
        completedExamCount: list.length,
        latestCompletedExamAt: latest.completedAt,
      ),
    );
  });

  if (subjects.isEmpty) return const SubjectPerformanceSummary();
  final best = ([...subjects]..sort(_bestOrder)).first;
  if (subjects.length < 2) return SubjectPerformanceSummary(best: best);
  final weakest = ([...subjects]..sort(_weakestOrder)).first;
  return SubjectPerformanceSummary(best: best, weakest: weakest);
}

int _bestOrder(SubjectPerformance a, SubjectPerformance b) {
  final byAverage = b.averagePercentage.compareTo(a.averagePercentage);
  return byAverage != 0 ? byAverage : _tieBreak(a, b);
}

int _weakestOrder(SubjectPerformance a, SubjectPerformance b) {
  final byAverage = a.averagePercentage.compareTo(b.averagePercentage);
  return byAverage != 0 ? byAverage : _tieBreak(a, b);
}

/// Same for both rankings: more completed exams, then most recent, then id.
int _tieBreak(SubjectPerformance a, SubjectPerformance b) {
  final byCount = b.completedExamCount.compareTo(a.completedExamCount);
  if (byCount != 0) return byCount;
  final byRecency = b.latestCompletedExamAt.compareTo(a.latestCompletedExamAt);
  if (byRecency != 0) return byRecency;
  return a.subjectId.compareTo(b.subjectId);
}
