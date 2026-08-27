import 'package:achievia/domain/entities/widgets/goal_entity.dart';

class GoalDto {
  final String id;
  final DateTime date;
  final String title;
  final String details;
  final bool isChecked;

  const GoalDto({
    required this.id,
    required this.date,
    required this.title,
    required this.details,
    required this.isChecked,
  });

  factory GoalDto.fromJson(Map<String, dynamic> json) {
    return GoalDto(
      id: json['id'].toString(),
      date: DateTime.parse(json['goal_date'].toString()),
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      isChecked: json['is_checked'] == true,
    );
  }

  GoalEntity toEntity() => GoalEntity(
    id: id,
    date: date,
    title: title,
    details: details,
    isChecked: isChecked,
  );
}
