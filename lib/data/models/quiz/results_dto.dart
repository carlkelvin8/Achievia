import 'dart:convert';

import 'package:achievia/domain/entities/api/home/results_entity.dart';

class QuizScoreResponse {
  final bool success;
  final Data data;

  QuizScoreResponse({required this.success, required this.data});

  factory QuizScoreResponse.fromJson(Map<String, dynamic> json) {
    return QuizScoreResponse(
      success: json['success'],
      data: Data.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.toJson()};
  }

  // DTO ↔ Entity
  factory QuizScoreResponse.fromEntity(QuizScoreEntity entity) {
    return QuizScoreResponse(
      success: entity.success,
      data: Data.fromEntity(entity.score),
    );
  }

  QuizScoreEntity toEntity() {
    return QuizScoreEntity(success: success, score: data.toEntity());
  }
}

class Data {
  final Score score;

  Data({required this.score});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(score: Score.fromJson(json['score']));
  }

  Map<String, dynamic> toJson() {
    return {'score': score.toJson()};
  }

  factory Data.fromEntity(ScoreEntity entity) {
    return Data(score: Score.fromEntity(entity));
  }

  ScoreEntity toEntity() {
    return score.toEntity();
  }
}

class Score {
  final String score;
  final List<Answer> answer;
  final bool passed;
  final double failedWeight;
  final bool hasMajorBelow50;
  final List<String> reasons;

  Score({
    required this.score,
    required this.answer,
    required this.passed,
    required this.failedWeight,
    required this.hasMajorBelow50,
    required this.reasons,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    var answerJson = jsonDecode(json['answer']) as List;
    List<Answer> answers = answerJson.map((e) => Answer.fromJson(e)).toList();
    return Score(
      score: json['score'].toString(),
      answer: answers,
      passed:
          json['passed'] as bool? ??
          (double.tryParse(json['score'].toString()) ?? 0) >= 75,
      failedWeight: (json['failedWeight'] as num?)?.toDouble() ?? 0,
      hasMajorBelow50: json['hasMajorBelow50'] as bool? ?? false,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'answer': jsonEncode(answer.map((e) => e.toJson()).toList()),
      'passed': passed,
      'failedWeight': failedWeight,
      'hasMajorBelow50': hasMajorBelow50,
      'reasons': reasons,
    };
  }

  factory Score.fromEntity(ScoreEntity entity) {
    return Score(
      score: entity.score,
      answer: entity.answers.map((e) => Answer.fromEntity(e)).toList(),
      passed: entity.passed,
      failedWeight: entity.failedWeight,
      hasMajorBelow50: entity.hasMajorBelow50,
      reasons: entity.reasons,
    );
  }

  ScoreEntity toEntity() {
    return ScoreEntity(
      score: score,
      answers: answer.map((e) => e.toEntity()).toList(),
      passed: passed,
      failedWeight: failedWeight,
      hasMajorBelow50: hasMajorBelow50,
      reasons: reasons,
    );
  }
}

class Answer {
  final bool isCorrect;
  final String name;
  final double score;

  Answer({required this.isCorrect, required this.name, required this.score});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      isCorrect: json['isCorrect'],
      name: json['name'],
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'isCorrect': isCorrect, 'name': name, 'score': score};
  }

  factory Answer.fromEntity(AnswerEntity entity) {
    return Answer(
      isCorrect: entity.isCorrect,
      name: entity.name,
      score: entity.score,
    );
  }

  AnswerEntity toEntity() {
    return AnswerEntity(isCorrect: isCorrect, name: name, score: score);
  }
}
