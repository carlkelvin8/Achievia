// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qotd_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QotdDto _$QotdDtoFromJson(Map<String, dynamic> json) => QotdDto(
  title: (json['title'] ?? '').toString(),
  quizId: json['quizId'] is num
      ? (json['quizId'] as num).toInt()
      : int.tryParse('${json['quizId']}') ?? 0,
  id: json['id'] is num
      ? (json['id'] as num).toInt()
      : int.tryParse('${json['id']}') ?? 0,
  questionText: (json['questionText'] ?? '').toString(),
  choices:
      (json['choices'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      <Map<String, dynamic>>[],
  questions: (json['questions'] as List?)
      ?.whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
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
