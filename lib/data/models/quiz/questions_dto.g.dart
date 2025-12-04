// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionsDto _$QuestionsDtoFromJson(Map<String, dynamic> json) => QuestionsDto(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  courseId: (json['courseId'] as num).toInt(),
  description: json['description'] as String,
  image: json['image'] as String?,
  day_subject: json['day_subject'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$QuestionsDtoToJson(QuestionsDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'courseId': instance.courseId,
      'description': instance.description,
      'image': instance.image,
      'day_subject': instance.day_subject,
      'createdAt': instance.createdAt,
    };
