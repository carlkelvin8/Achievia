/// Single source of truth for which Question Bank rows normal users may see.
///
/// A question is eligible when it, its subtopic and its subject are not
/// soft-deleted (`deleted_at IS NULL`) and its live choices form a valid
/// single-answer question: at least [minChoices] choices and exactly one
/// marked correct. Malformed questions are skipped one by one; they never
/// break a deck, an exam or the Question of the Day.
library;

/// True when a row carries a non-null `deleted_at`. Rows fetched with a
/// server-side `deleted_at IS NULL` filter simply do not include the column,
/// which counts as live.
bool isSoftDeleted(Map<String, dynamic> row) => row['deleted_at'] != null;

/// The single-answer rule: at least [minChoices] live choices and exactly one
/// of them correct. Every caller (exams, Study Mode, QOTD, Mock Boards) uses
/// this one definition.
bool isValidSingleAnswer({
  required int total,
  required int correct,
  int minChoices = 1,
}) => total >= minChoices && correct == 1;

int? _asInt(Object? v) => v is int
    ? v
    : v is num
    ? v.toInt()
    : v is String
    ? int.tryParse(v)
    : null;

/// Ids of questions whose non-deleted choices (from [choiceRows]) contain at
/// least [minChoices] options and exactly one correct option.
Set<int> validQuestionIdsFromChoices(
  Iterable<Map<String, dynamic>> choiceRows, {
  int minChoices = 1,
}) {
  final total = <int, int>{};
  final correct = <int, int>{};
  final seen = <int>{};
  for (final row in choiceRows) {
    if (isSoftDeleted(row)) continue;
    final questionId = _asInt(row['question_id']);
    final choiceId = _asInt(row['id']);
    if (questionId == null) continue;
    // Ignore a choice row repeated in a page overlap.
    if (choiceId != null && !seen.add(choiceId)) continue;
    total[questionId] = (total[questionId] ?? 0) + 1;
    if (row['is_correct'] == true) {
      correct[questionId] = (correct[questionId] ?? 0) + 1;
    }
  }
  return {
    for (final entry in total.entries)
      if (isValidSingleAnswer(
        total: entry.value,
        correct: correct[entry.key] ?? 0,
        minChoices: minChoices,
      ))
        entry.key,
  };
}
