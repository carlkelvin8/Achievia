import 'package:achievia/domain/entities/api/home/qoty_entity.dart';

class MockExamSubjectEntity {
  final String id;
  final String title;
  final String courseId;
  final String description;
  final String? image;
  final String? daySubject;
  final String createdAt;
  final List<QotyEntity> questions;

  MockExamSubjectEntity({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    this.image,
    required this.daySubject,
    required this.createdAt,
    required this.questions,
  });
}
