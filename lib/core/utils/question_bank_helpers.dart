import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

List<QuestionItemEntity> buildQuestionBankPracticeQuestions({
  required List<Map<String, dynamic>> questionRows,
  required List<Map<String, dynamic>> choiceRows,
  int limit = 20,
  Random? random,
}) {
  final choicesByQuestion = <int, List<ChoiceEntity>>{};

  for (final row in choiceRows) {
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
        final id = _readInt(row['id']);
        final choices = id == null ? null : choicesByQuestion[id];
        if (id == null || choices == null || choices.isEmpty) return null;

        return QuestionItemEntity(
          id: id,
          questionText: (row['question_text'] ?? row['questionText'] ?? '')
              .toString(),
          choices: choices,
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
