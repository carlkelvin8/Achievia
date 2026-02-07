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

// **************************************************************************
// HiveTypeAdapterGenerator
// **************************************************************************

class ModuleDtoAdapter extends TypeAdapter<ModuleDto> {
  @override
  final int typeId = 3;

  @override
  ModuleDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleDto(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String,
      userId: fields[3] as int,
      createdAt: fields[4] as String,
      file: fields[5] as String?,
      image: fields[6] as String?,
      status: fields[7] as String,
      subjectId: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ModuleDto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.file)
      ..writeByte(6)
      ..write(obj.image)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.subjectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
