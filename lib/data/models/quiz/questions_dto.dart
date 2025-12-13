// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'questions_dto.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class QuestionsDto {

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int courseId;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String? image; // nullable

  @HiveField(5)
  final String? day_subject;

  @HiveField(6)
  final String createdAt;

  QuestionsDto({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    this.image,
    required this.day_subject,
    required this.createdAt,
  });

  factory QuestionsDto.fromJson(Map<String, dynamic> json) => _$QuestionsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionsDtoToJson(this);

  QuestionsEntity toEntity() => QuestionsEntity(
      id: id.toString(),  // convert int to String if entity expects String
      title: title,
      courseId: courseId.toString(), 
      description: description,
      image: image ?? '',
      day_subject: day_subject,
      createdAt: createdAt,
    );

  static QuestionsDto fromEntity(QuestionsEntity entity) => QuestionsDto(
      id: int.parse(entity.id),
      title: entity.title,
      courseId: int.parse(entity.courseId),
      description: entity.description,
      image: entity.image,
      day_subject: entity.day_subject,
      createdAt: entity.createdAt,
    );
}
