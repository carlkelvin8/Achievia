import 'dart:convert';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'qotd_dto_post.g.dart';
@JsonSerializable()
class QotdDtoPost {
  final String chosen_answer;
  final int quiz_id;
  final int student_id;
  QotdDtoPost({
    required this.chosen_answer,
    required this.quiz_id,
    required this.student_id,
  });
  


  Map<String,dynamic> toJson() => _$QotdDtoPostToJson(this);

  factory QotdDtoPost.fromJson(Map<String,dynamic> json) => _$QotdDtoPostFromJson(json);

  static QotdDtoPost fromEntity(QotyEntityPost entity) => QotdDtoPost(
                                chosen_answer: entity.chosen_ans, 
                                quiz_id: entity.quiz_id, 
                                student_id: entity.student_id
                              );
  QotyEntityPost toEntity() => QotyEntityPost(chosen_ans: chosen_answer, quiz_id: quiz_id, student_id: student_id);
}
