// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:achievia/domain/entities/api/home/questions_entity.dart';

class QuestionsDto {
  final String id;
  final String title;
  final String courseId;
  final String description;
  final String image;
  final String day_subject;
  final String createdAt;
  QuestionsDto({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    required this.image,
    required this.day_subject,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'courseId': courseId,
      'description': description,
      'image': image,
      'day_subject': day_subject,
      'createdAt': createdAt,
    };
  }

  factory QuestionsDto.fromMap(Map<String, dynamic> map) {
    return QuestionsDto(
      id: map['id'] as String,
      title: map['title'] as String,
      courseId: map['courseId'] as String,
      description: map['description'] as String,
      image: map['image'] as String,
      day_subject: map['day_subject'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory QuestionsDto.fromJson(String source) => QuestionsDto.fromMap(json.decode(source) as Map<String, dynamic>);

  QuestionsEntity toEntity(){
    return QuestionsEntity(id: id, title: title, courseId: courseId, description: description, image: image, day_subject: day_subject, createdAt: createdAt);
  }

  static QuestionsDto fromEntity(QuestionsEntity entity){
    return QuestionsDto(id: entity.id, title: entity.title, courseId: entity.courseId, description: entity.description, image: entity.image, day_subject: entity.day_subject, createdAt: entity.createdAt);
  }
}
