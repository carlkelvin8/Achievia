// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qotd_dto.g.dart';

@JsonSerializable()
class QotdDto {
  final int quizId;
  final int id;
  final String title;
  final String questionText;
  final List<Map<String, dynamic>> choices;
  final List<Map<String, dynamic>>? questions;
  QotdDto({
    required this.title,
    required this.quizId,
    required this.id,
    required this.questionText,
    required this.choices,
    this.questions,
  });

  factory QotdDto.fromJson(Map<String, dynamic> json) =>
      _$QotdDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QotdDtoToJson(this);

  QotyEntity toEntity() => QotyEntity(
    title: title,
    quizId: quizId,
    id: id,
    questionText: questionText,
    questions: questions,
    choices: choices.map((c) => c).toList(),
  );

  static QotdDto fromEntity(QotyEntity entity) => QotdDto(
    title: entity.title,
    questions: entity.questions,
    quizId: entity.quizId,
    id: entity.id,
    questionText: entity.questionText,
    choices: entity.choices,
  );
}
