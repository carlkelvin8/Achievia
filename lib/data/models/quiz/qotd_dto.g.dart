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
);

Map<String, dynamic> _$QotdDtoToJson(QotdDto instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'id': instance.id,
  'questionText': instance.questionText,
  'choices': instance.choices,
};

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QotdDtoAdapter extends TypeAdapter<QotdDto> {
  @override
  final int typeId = 3;

  @override
  QotdDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QotdDto(
      quizId: fields[0] as int,
      id: fields[1] as int,
      questionText: fields[2] as String,
      choices: (fields[3] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, QotdDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.quizId)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.questionText)
      ..writeByte(3)
      ..write(obj.choices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QotdDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
