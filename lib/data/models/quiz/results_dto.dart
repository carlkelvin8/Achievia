// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
part 'results_dto.g.dart';
@JsonSerializable()
class ResultsDto {
  final String name;
  final num score;
  ResultsDto({required this.name, required this.score});
  
  

  Map<String, dynamic> toMap() => _$ResultsDtoToJson(this);

  factory ResultsDto.fromMap(Map<String, dynamic> map) => _$ResultsDtoFromJson(map);
}
