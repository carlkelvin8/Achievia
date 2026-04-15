class QuizDto {
  final List<QuizDtoItems> items;
  QuizDto({required this.items});
  factory QuizDto.fromJson(Map<String, dynamic> json) {
    return QuizDto(
      items: (json['quiz'] as List<dynamic>).map(
            (item) => QuizDtoItems(
              id: item['id'] as int,
              title: item['title'] ?? "",
              description: item['description'] ?? "",
              createdAt: item['createdAt'] ?? "",
              subjectId: item['subjectId'] as int,
              questions: (item['questions'] as List<dynamic>)
                  .map(
                    (question) => QuestionsItemsDto(
                      id: question['id'] as int,
                      questionText: question['questionText'] ?? "",
                      choices: (question['choices'] as List<dynamic>)
                          .map((choice) => ChoicesDto.fromJson(choice as Map<String, dynamic>))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ).toList(),
    );
  }
}

class QuizDtoItems {
  final int id;
  final String title;
  final String description;
  final String createdAt;
  final int subjectId;
  final List<QuestionsItemsDto> questions;
  QuizDtoItems({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.subjectId,
    required this.questions,
  });

  factory QuizDtoItems.fromJson(Map<String, dynamic> json) {
    return QuizDtoItems(
      id: json['id'] as int,
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      createdAt: json['createdAt'] ?? "",
      subjectId: json['subjectId'] as int,
      questions: (json['questions'] as List<dynamic>)
          .map(
            (question) => QuestionsItemsDto(
              id: question['id'] as int,
              questionText: question['questionText'] ?? "",
              choices: (question['choices'] as List<dynamic>)
                  .map((choice) => ChoicesDto.fromJson(choice as Map<String, dynamic>))
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class QuestionsItemsDto {
  final int id;
  final String questionText;
  final List<ChoicesDto> choices;
  QuestionsItemsDto({
    required this.id,
    required this.questionText,
    required this.choices,
  });
}

class ChoicesDto {
  final int id;
  final String choiceText;
  final bool isCorrect;
  ChoicesDto({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
  });

  static ChoicesDto fromJson(Map<String, dynamic> json) {
    return ChoicesDto(
      id: json['id'] as int,
      choiceText: json['choiceText'] ?? "",
      isCorrect: json['isCorrect'] as bool,
    );
  }
}
