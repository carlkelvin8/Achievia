import 'dart:math';

import 'package:achievia/core/utils/question_eligibility.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

List<QuestionItemEntity> buildQuestionBankPracticeQuestions({
  required List<Map<String, dynamic>> questionRows,
  required List<Map<String, dynamic>> choiceRows,
  int limit = 20,
  Random? random,
}) {
  final choicesByQuestion = <int, List<ChoiceEntity>>{};

  for (final row in choiceRows) {
    if (isSoftDeleted(row)) continue;
    final questionId = _readInt(row['question_id'] ?? row['questionId']);
    if (questionId == null) continue;

    choicesByQuestion
        .putIfAbsent(questionId, () => [])
        .add(
          ChoiceEntity(
            id: _readInt(row['id']) ?? 0,
            questiondId: questionId,
            choiceText: (row['choice_text'] ?? row['choiceText'] ?? '')
                .toString(),
            isCorrect: row['is_correct'] == true || row['isCorrect'] == true,
          ),
        );
  }

  final usableQuestions = questionRows
      .map((row) {
        if (isSoftDeleted(row)) return null;
        final id = _readInt(row['id']);
        final choices = id == null ? null : choicesByQuestion[id];
        if (id == null || choices == null || choices.isEmpty) return null;
        // Exactly one correct choice, otherwise the question is malformed.
        if (choices.where((c) => c.isCorrect).length != 1) return null;

        return QuestionItemEntity(
          id: id,
          questionText: (row['question_text'] ?? row['questionText'] ?? '')
              .toString(),
          choices: choices,
          imagePath: normalizeQuestionBankOptionalText(row['image_path']),
          // The admin panel stores the explanation in `correct_description`;
          // the older `rationale` column is used only when it is filled.
          rationale: [
            normalizeQuestionBankOptionalText(row['rationale']),
            normalizeQuestionBankOptionalText(row['correct_description']),
          ].firstWhere((text) => text.isNotEmpty, orElse: () => ''),
        );
      })
      .whereType<QuestionItemEntity>()
      .toList();

  usableQuestions.shuffle(random ?? Random());
  return usableQuestions.take(max(0, limit)).toList();
}

double questionBankScore({required int correct, required int total}) {
  if (total <= 0) return 0;
  return double.parse(((correct / total) * 100).toStringAsFixed(2));
}

String normalizeQuestionBankOptionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.toLowerCase() == 'null') return '';
  return text;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Fixed configuration for an individual subject exam started through
/// Take an Exam. These are the single source of truth for the exam item count
/// and time limit: the values are intentionally not user-configurable and are
/// never read from preferences or storage.
const subjectExamQuestionCount = 100;
const subjectExamDuration = Duration(minutes: 60);

/// Passing boundary (in percent) for a Question Bank subject exam.
///
/// Single source of truth: any Passed/Failed decision for a Take an Exam
/// subject exam must compare the full stored score (a double percentage) to
/// this constant, never to a formatted score string.
const questionBankPassingScore = 75.0;

/// Remaining time from an absolute deadline; never negative. Using the
/// deadline (not a decremented counter) keeps time correct across app
/// backgrounding.
Duration remainingUntil(DateTime endsAt, DateTime now) {
  final left = endsAt.difference(now);
  return left.isNegative ? Duration.zero : left;
}

/// Picks up to [count] distinct usable questions at random from
/// [candidateIds] (all eligible question ids of one subject).
///
/// Ids are de-duplicated and shuffled, then loaded in batches via
/// [loadUsable] (which may return fewer rows, e.g. questions without
/// choices). Never repeats a question to reach [count].
Future<List<QuestionItemEntity>> assembleExamQuestions({
  required Iterable<int> candidateIds,
  required Future<List<QuestionItemEntity>> Function(List<int> ids) loadUsable,
  int count = subjectExamQuestionCount,
  Random? random,
}) async {
  final ids = candidateIds.toSet().toList()..shuffle(random ?? Random());
  final picked = <int, QuestionItemEntity>{};
  var cursor = 0;
  while (picked.length < count && cursor < ids.length) {
    final needed = count - picked.length;
    final end = min(cursor + needed + 20, ids.length);
    final batch = await loadUsable(ids.sublist(cursor, end));
    cursor = end;
    for (final question in batch) {
      if (picked.length >= count) break;
      picked.putIfAbsent(question.id, () => question);
    }
  }
  return (picked.values.toList()..shuffle(random ?? Random()));
}
