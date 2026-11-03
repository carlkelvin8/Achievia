// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'questions_dto.g.dart';

@JsonSerializable()
class QuestionsDto {
  final int id;
  final String title;
  final int courseId;
  final String description;
  final String? image; // nullable
  @JsonKey(name: 'day_subject')
  final String? daySubject;
  final String createdAt;

  QuestionsDto({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    this.image,
    required this.daySubject,
    required this.createdAt,
  });

  factory QuestionsDto.fromJson(Map<String, dynamic> json) =>
      _$QuestionsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionsDtoToJson(this);

  QuestionsEntity toEntity() => QuestionsEntity(
    id: id.toString(), // convert int to String if entity expects String
    title: title,
    courseId: courseId.toString(),
    description: description,
    image: image ?? '',
    daySubject: daySubject,
    createdAt: createdAt,
  );

  static QuestionsDto fromEntity(QuestionsEntity entity) => QuestionsDto(
    id: int.parse(entity.id),
    title: entity.title,
    courseId: int.parse(entity.courseId),
    description: entity.description,
    image: entity.image,
    daySubject: entity.daySubject,
    createdAt: entity.createdAt,
  );
}
