// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:json_annotation/json_annotation.dart';
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

  factory MockboardsPausedDto.fromJson(Map<String, dynamic> json) =>
      _$MockboardsPausedDtoFromJson(json);

  MockboardPausedEntity toEntity() => MockboardPausedEntity(
    id: id,
    user_id: user_id,
    quiz_id: quiz_id,
    current_page: current_page,
    created_at: created_at,
    updated_at: updated_at,
  );

  static MockboardsPausedDto fromEntity(MockboardPausedEntity entity) =>
      MockboardsPausedDto(
        id: entity.id,
        user_id: entity.user_id,
        quiz_id: entity.quiz_id,
        current_page: entity.current_page,
        created_at: entity.created_at,
        updated_at: entity.updated_at,
      );
}
