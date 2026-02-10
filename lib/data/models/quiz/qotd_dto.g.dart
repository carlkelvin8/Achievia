// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qotd_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QotdDto _$QotdDtoFromJson(Map<String, dynamic> json) => QotdDto(
  quizId: (json['quizId'] as num).toInt(),
  id: (json['id'] as num).toInt(),
  questionText: json['questionText'] as String,
  choices: (json['choices'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  quiz: json['quiz'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$QotdDtoToJson(QotdDto instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'id': instance.id,
  'questionText': instance.questionText,
  'choices': instance.choices,
  'quiz': instance.quiz,
};
