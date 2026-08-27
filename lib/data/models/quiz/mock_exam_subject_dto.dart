import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/domain/entities/api/home/mock_exam_subject_entity.dart';

class MockExamSubjectDto {
  final int id;
  final String title;
  final int courseId;
  final String description;
  final String? image;
  final String? daySubject;
  final String createdAt;
  final List<QotdDto> questions;

  MockExamSubjectDto({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    this.image,
    required this.daySubject,
    required this.createdAt,
    required this.questions,
  });

  factory MockExamSubjectDto.fromJson(Map<String, dynamic> json) {
    return MockExamSubjectDto(
      id: json['id'] as int,
      title: json['title'] as String,
      courseId: json['courseId'] as int,
      description: (json['description'] ?? '') as String,
      image: json['image'] as String?,
      daySubject: json['day_subject'] as String?,
      createdAt: json['createdAt'] as String,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map(
            (question) => QotdDto.fromJson(Map<String, dynamic>.from(question)),
          )
          .toList(),
    );
  }

  MockExamSubjectEntity toEntity() {
    return MockExamSubjectEntity(
      id: id.toString(),
      title: title,
      courseId: courseId.toString(),
      description: description,
      image: image,
      daySubject: daySubject,
      createdAt: createdAt,
      questions: questions.map((question) => question.toEntity()).toList(),
    );
  }
}
