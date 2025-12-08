// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'qotd_dto.g.dart';
@HiveType(typeId: 1)
@JsonSerializable()
class QotdDto {
  @HiveField(0)
  final int quizId;
  @HiveField(1)
  final int id;
  @HiveField(2)
  final String questionText;
  final List<Map<String,dynamic>> choices;
  QotdDto({
    required this.quizId,
    required this.id,
    required this.questionText,
    required this.choices,
  });

  factory QotdDto.fromJson(Map<String,dynamic> json) => _$QotdDtoFromJson(json);

  Map<String,dynamic> toJson() => _$QotdDtoToJson(this);

  QotyEntity toEntity() => QotyEntity(quizId: quizId, id: id, questionText: questionText, choices: choices.map((c) => c).toList(),);

  static QotdDto fromEntity(QotyEntity entity) => QotdDto(quizId: entity.quizId, id: entity.id, questionText: entity.questionText, choices: entity.choices);
}

