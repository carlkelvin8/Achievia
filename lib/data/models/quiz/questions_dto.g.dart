// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionsDto _$QuestionsDtoFromJson(Map<String, dynamic> json) => QuestionsDto(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  courseId: (json['courseId'] as num).toInt(),
  description: json['description'] as String,
  image: json['image'] as String?,
  day_subject: json['day_subject'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$QuestionsDtoToJson(QuestionsDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'courseId': instance.courseId,
      'description': instance.description,
      'image': instance.image,
      'day_subject': instance.day_subject,
      'createdAt': instance.createdAt,
    };

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionsDtoAdapter extends TypeAdapter<QuestionsDto> {
  @override
  final int typeId = 1;

  @override
  QuestionsDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionsDto(
      id: fields[0] as int,
      title: fields[1] as String,
      courseId: fields[2] as int,
      description: fields[3] as String,
      image: fields[4] as String?,
      day_subject: fields[5] as String?,
      createdAt: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionsDto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.image)
      ..writeByte(5)
      ..write(obj.day_subject)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionsDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
