import 'package:achievia/domain/entities/api/progress/progress_day_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_day_dto.g.dart';

@JsonSerializable()
class ProgressDayDto {
  final int id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'activity_date')
  final DateTime activityDate;
  @JsonKey(name: 'is_active')
  final bool isActive;

  ProgressDayDto({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.isActive,
  });

  factory ProgressDayDto.fromJson(Map<String, dynamic> json) =>
      _$ProgressDayDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressDayDtoToJson(this);

  ProgressDayEntity toEntity() => ProgressDayEntity(
    id: id,
    userId: userId,
    activityDate: activityDate,
    isActive: isActive,
  );
}
