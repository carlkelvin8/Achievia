// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
part 'mockboards_paused_dto.g.dart';

@JsonSerializable()
class MockboardsPausedDto {
  final String id;
  // ignore: non_constant_identifier_names
  final String user_id;
  // ignore: non_constant_identifier_names
  final int quiz_id;
  // ignore: non_constant_identifier_names
  final double current_page;
  // ignore: non_constant_identifier_names
  final String created_at;
  // ignore: non_constant_identifier_names
  final String updated_at;
  MockboardsPausedDto({
    required this.id,
    // ignore: non_constant_identifier_names
    required this.user_id,
    // ignore: non_constant_identifier_names
    required this.quiz_id,
    // ignore: non_constant_identifier_names
    required this.current_page,
    // ignore: non_constant_identifier_names
    required this.created_at,
    // ignore: non_constant_identifier_names
    required this.updated_at,
  });

  Map<String, dynamic> toJson() => _$MockboardsPausedDtoToJson(this);

  factory MockboardsPausedDto.fromJson(Map<String, dynamic> json) => _$MockboardsPausedDtoFromJson(json);
}
