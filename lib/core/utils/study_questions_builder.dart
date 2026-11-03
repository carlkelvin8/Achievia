import 'package:achievia/core/utils/question_eligibility.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

/// Builds the eligible Study Mode questions of one subtopic from raw rows.
///
/// A question is eligible when it is not soft-deleted, has text, and its
/// non-deleted choices include exactly one marked correct (see
/// question_eligibility.dart). Malformed questions are skipped individually. Questions are
/// returned in canonical order (ascending id) with unique ids; choices are in
/// ascending id order with unique ids.
List<QuestionItemEntity> buildStudyQuestions({
  required List<Map<String, dynamic>> questionRows,
  required List<Map<String, dynamic>> choiceRows,
}) {
  int? readInt(dynamic v) => v is int
      ? v
      : v is num
      ? v.toInt()
      : v is String
      ? int.tryParse(v)
      : null;

  final choicesByQuestion = <int, Map<int, ChoiceEntity>>{};
  for (final row in choiceRows) {
    if (isSoftDeleted(row)) continue;
    final id = readInt(row['id']);
    final questionId = readInt(row['question_id']);
    if (id == null || questionId == null) continue;
    choicesByQuestion.putIfAbsent(questionId, () => {})[id] = ChoiceEntity(
      id: id,
      questiondId: questionId,
      choiceText: (row['choice_text'] ?? '').toString(),
      isCorrect: row['is_correct'] == true,
    );
  }

  final byId = <int, QuestionItemEntity>{};
  for (final row in questionRows) {
    if (isSoftDeleted(row)) continue;
    final id = readInt(row['id']);
    if (id == null || byId.containsKey(id)) continue;
    final text = (row['question_text'] ?? '').toString();
    final choices = choicesByQuestion[id]?.values.toList();
    if (text.trim().isEmpty || choices == null || choices.isEmpty) continue;
    if (choices.where((c) => c.isCorrect).length != 1) continue;
    choices.sort((a, b) => a.id - b.id);
    // The admin panel stores the explanation in `correct_description`;
    // the older `rationale` column is used only when it is filled.
    final rationale = _firstText(row['rationale'], row['correct_description']);
    final notes = _firstText(row['notes']);
    final imagePath = (row['image_path'] ?? '').toString().trim();
    byId[id] = QuestionItemEntity(
      id: id,
      questionText: text,
      imagePath: imagePath.toLowerCase() == 'null' ? '' : imagePath,
      choices: choices,
      rationale: rationale,
      notes: notes,
    );
  }
  return byId.values.toList()..sort((a, b) => a.id - b.id);
}

/// First value that holds real text: not null, empty, or the literal "null"
/// the admin tooling sometimes stores.
String _firstText(Object? first, [Object? second]) {
  for (final value in [first, second]) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}
