import 'package:achievia/core/utils/helpers.dart' show gradingBrackets;
import 'package:achievia/core/utils/question_bank_helpers.dart'
    show questionBankPassingScore;
import 'package:achievia/domain/entities/widgets/progress_entity.dart';

export 'package:achievia/domain/entities/widgets/progress_entity.dart'
    show GradingBracket, GradingResult;

/// Single, shared Passed/Failed comparison used across every exam result
/// surface. Always compares the raw numeric percentage, never a formatted
/// string, so 74.999 fails and 75 passes.
bool isPassing({required double score, required double passingScore}) =>
    score >= passingScore;

/// Deterministic safe representation of a stored percentage.
///
/// Valid finite percentages in [0, 100] pass through unchanged with full
/// precision. Invalid inputs (NaN, ±Infinity, negatives, values above 100)
/// are clamped to a safe value so no corrupted data can reach the UI.
double sanitizePercentage(double? raw) {
  if (raw == null || raw.isNaN || raw.isInfinite || raw < 0) return 0;
  if (raw > 100) return 100;
  return raw;
}

/// Resolves a percentage to its Achievia grading bracket in O(n) over the
/// declared bracket list. Ranges are half-open on the upper bound and the top
/// bracket is open-ended. Falls back deterministically to the lowest declared
/// bracket if [percentage] lands below every range.
GradingBracket bracketForPercentage(double percentage) {
  final safe = sanitizePercentage(percentage);
  GradingBracket? fallback;
  for (final bracket in gradingBrackets) {
    if (safe < bracket.minScore) break;
    fallback = bracket;
    final maxExclusive = bracket.maxScoreExclusive;
    if (maxExclusive == null || safe < maxExclusive) {
      return bracket;
    }
  }
  if (fallback != null) return fallback;
  throw StateError('gradingBrackets must not be empty.');
}

/// Applies grading to a finished exam percentage: sanitizes the value,
/// compares it against the shared passing boundary and resolves the bracket
/// (level + message) used for the result interpretation.
GradingResult gradePercentage(
  double percentage, {
  double passingScore = questionBankPassingScore,
}) {
  final safe = sanitizePercentage(percentage);
  return GradingResult(
    percentage: safe,
    passed: isPassing(score: safe, passingScore: passingScore),
    bracket: bracketForPercentage(safe),
  );
}
