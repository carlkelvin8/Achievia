import 'dart:convert';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

class QuizDto {
  final List<QuizDtoItems> items;
  QuizDto({required this.items});

  static QuizDto fromEntity(QuizEntity entity) {
    return QuizDto(
      items: entity.items.map((item) => QuizDtoItems.fromEntity(item)).toList(),
    );
  }

  QuizEntity toEntity() {
    return QuizEntity(
      items: items.map((item) => QuizItemEntity(
        id: item.id,
        title: item.title,
        description: item.description,
        createdAt: item.createdAt,
        subjectId: item.subjectId,
        questions: item.questions.map((q) => QuestionItemEntity(
          id: q.id,
          questionText: q.questionText,
          choices: q.choices.map((c) => ChoiceEntity(
            questiondId: c.questionId,
            id: c.id,
            choiceText: c.choiceText,
            isCorrect: c.isCorrect,
          )).toList(),
        )).toList(),
      )).toList(),
    );
  }

  factory QuizDto.fromJson(Map<String, dynamic> json) {
    return QuizDto(
      items: (json['quiz'] as List<dynamic>)
          .map(
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
                          .map(
                            (choice) => ChoicesDto.fromJson(
                              choice as Map<String, dynamic>,
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
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
                  .map(
                    (choice) =>
                        ChoicesDto.fromJson(choice as Map<String, dynamic>),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  static QuizDtoItems fromEntity(QuizItemEntity entity) {
    return QuizDtoItems(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      subjectId: entity.subjectId,
      questions: entity.questions
          .map((q) => QuestionsItemsDto.fromEntity(q))
          .toList(),
    );
  }


  QuizItemEntity toEntity() {
    return QuizItemEntity(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      subjectId: subjectId,
      questions: questions
          .map((q) => QuestionItemEntity(
                id: q.id,
                questionText: q.questionText,
                choices: q.choices
                    .map((c) => ChoiceEntity(
                          questiondId: c.questionId,
                          id: c.id,
                          choiceText: c.choiceText,
                          isCorrect: c.isCorrect,
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'subjectId': subjectId,
      'questions': jsonEncode(
        questions
            .map((q) => {
                  'id': q.id,
                  'questionText': q.questionText,
                  'choices': q.choices
                      .map((c) => {
                            'id': c.id,
                            'choiceText': c.choiceText,
                            'isCorrect': c.isCorrect,
                            'questionId': c.questionId,
                          })
                      .toList(),
                })
            .toList(),
      ),
    };
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

  factory QuestionsItemsDto.fromJson(Map<String, dynamic> json) {
    return QuestionsItemsDto(
      id: json['id'] as int,
      questionText: json['questionText'] ?? "",
      choices: (json['choices'] as List<dynamic>)
          .map((choice) => ChoicesDto.fromJson(choice as Map<String, dynamic>))
          .toList(),
    );
  }

  static QuestionsItemsDto fromEntity(QuestionItemEntity entity) {
    return QuestionsItemsDto(
      id: entity.id,
      questionText: entity.questionText,
      choices: entity.choices.map((c) => ChoicesDto.fromEntity(c)).toList(),
    );
  }
}

class ChoicesDto {
  final int id;
  final String choiceText;
  final bool isCorrect;
  final int questionId;
  ChoicesDto({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
    required this.questionId,
  });

  factory ChoicesDto.fromJson(Map<String, dynamic> json) {
    return ChoicesDto(
      id: json['id'] as int,
      choiceText: json['choiceText'] ?? "",
      isCorrect: json['isCorrect'] as bool,
      questionId: json['questionId'] as int,
    );
  }

  static ChoicesDto fromEntity(ChoiceEntity entity) {
    return ChoicesDto(
      id: entity.id,
      choiceText: entity.choiceText,
      isCorrect: entity.isCorrect,
      questionId: entity.questiondId,
    );
  }
}
/// THIS ONE CAN'T BE DELETED BECAUSE IT'S USED IN THE OFFLINE CACHING OF THE QUIZ QUESTIONS, AND IT'S ALSO USED IN THE EXAM SCREEN TO FLATTEN THE QUESTION DATA FOR EASIER ACCESS. WAG DELETE POTA PLEASE.
typedef FlattenedQuestion = ({
  String title,
  int quizId,
  QuestionItemEntity question,
});
