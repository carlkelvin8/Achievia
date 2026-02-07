// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModuleDto _$ModuleDtoFromJson(Map<String, dynamic> json) => ModuleDto(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  userId: (json['userId'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  file: json['file'] as String?,
  image: json['image'] as String?,
  status: json['status'] as String,
  subjectId: (json['subjectId'] as num).toInt(),
);

Map<String, dynamic> _$ModuleDtoToJson(ModuleDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'userId': instance.userId,
  'createdAt': instance.createdAt,
  'file': instance.file,
  'image': instance.image,
  'status': instance.status,
  'subjectId': instance.subjectId,
};
