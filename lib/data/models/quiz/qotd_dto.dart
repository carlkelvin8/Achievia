// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qotd_dto.g.dart';
@JsonSerializable()
class QotdDto {
  final int quizId;
  final int id;
  final String questionText;
  final List<Map<String,dynamic>> choices;
  final Map<String,dynamic>? quiz;
  QotdDto({
    required this.quizId,
    required this.id,
    required this.questionText,
    required this.choices,
    this.quiz
  });

  factory QotdDto.fromJson(Map<String,dynamic> json) => _$QotdDtoFromJson(json);

  Map<String,dynamic> toJson() => _$QotdDtoToJson(this);

  QotyEntity toEntity() => QotyEntity(
    quizId: quizId, id: id, 
    questionText: questionText,
    quiz: quiz,
    choices: choices.map((c) => c).toList(),);

  static QotdDto fromEntity(QotyEntity entity) => 
  QotdDto(
    quiz: entity.quiz,
    quizId: entity.quizId, id: entity.id, questionText: entity.questionText, choices: entity.choices);

    
}


extension QotdDtoSqflite on QotdDto {
  Map<String, Object?> toSqliteMap() {
    return {
      'id': id,
      'quizId': quizId,
      'questionText': questionText,
      'choices': jsonEncode(choices),
      'quiz': quiz != null ? jsonEncode(quiz) : null,
    };
  }
}
