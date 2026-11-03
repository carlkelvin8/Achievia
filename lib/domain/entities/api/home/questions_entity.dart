import 'package:injectable/injectable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
@injectable
class QuestionsEntity {
  final String id;
  final String title;
  final String courseId;
  final String description;
  final String image;
  final String? daySubject;
  final String createdAt;
  QuestionsEntity({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    required this.image,
    required this.daySubject,
    required this.createdAt,
  });
}
