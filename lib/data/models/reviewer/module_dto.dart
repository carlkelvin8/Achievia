// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'module_dto.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class ModuleDto {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int userId;

  @HiveField(4)
  final String createdAt;

  @HiveField(5)
  final String? file;

  @HiveField(6)
  final String? image;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final int subjectId;

  ModuleDto({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
    this.file,
    this.image,
    required this.status,
    required this.subjectId,
  });

  factory ModuleDto.fromJson(Map<String, dynamic> json) => _$ModuleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleDtoToJson(this);

  ModuleEntity toEntity() => ModuleEntity(
        id: id,
        title: title,
        description: description,
        userId: userId,
        createdAt: createdAt,
        file: file,
        image: image,
        status: status,
        subjectId: subjectId,
      );

  static ModuleDto fromEntity(ModuleEntity entity) => ModuleDto(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        userId: entity.userId,
        createdAt: entity.createdAt,
        file: entity.file,
        image: entity.image,
        status: entity.status,
        subjectId: entity.subjectId,
      );
}
