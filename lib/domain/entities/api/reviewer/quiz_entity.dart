class QuizEntity {
  final List<QuizItemEntity> items;

  QuizEntity({required this.items});
}

class QuizItemEntity {
  final int id;
  final String title;
  final String description;
  final String createdAt;
  final int subjectId;
  final List<QuestionItemEntity> questions;

  QuizItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.subjectId,
    required this.questions,
  });
}

class QuestionItemEntity {
  final int id;
  final String questionText;
  final List<ChoiceEntity> choices;

  /// Storage attachment associated with this question's ID.
  final String imagePath;

  /// Stored explanation of the question; empty when the question has none.
  /// Only Study Mode loads it, everywhere else it stays empty.
  final String rationale;

  /// Study notes the admin attached to the question; empty when there are
  /// none. Only Study Mode loads them.
  final String notes;

  QuestionItemEntity({
    required this.id,
    required this.questionText,
    required this.choices,
    this.imagePath = '',
    this.rationale = '',
    this.notes = '',
  });
}

class ChoiceEntity {
  final int questiondId;
  final int id;
  final String choiceText;
  final bool isCorrect;

  ChoiceEntity({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
    required this.questiondId,
  });
}
