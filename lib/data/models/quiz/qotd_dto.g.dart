// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qotd_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QotdDto _$QotdDtoFromJson(Map<String, dynamic> json) => QotdDto(
  title: json['title'] as String,
  quizId: (json['quizId'] as num).toInt(),
  id: (json['id'] as num).toInt(),
  questionText: json['questionText'] as String,
  choices: (json['choices'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  questions: (json['questions'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$QotdDtoToJson(QotdDto instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'id': instance.id,
  'title': instance.title,
  'questionText': instance.questionText,
  'choices': instance.choices,
  'questions': instance.questions,
};
