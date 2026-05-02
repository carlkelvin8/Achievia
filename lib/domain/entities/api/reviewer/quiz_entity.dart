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

  QuestionItemEntity({
    required this.id,
    required this.questionText,
    required this.choices,
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
