import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const studentId = '550e8400-e29b-41d4-a716-446655440000';

  test('parses student_id as a uuid string', () {
    final dto = QotdDtoPost.fromJson({
      'chosen_answer': 'Choice A',
      'quiz_id': 1,
      'student_id': studentId,
    });

    expect(dto.student_id, studentId);
  });

  test('preserves student_id uuid when converting from entity', () {
    final dto = QotdDtoPost.fromEntity(
      QotyEntityPost(chosen_ans: 'Choice A', quiz_id: 1, student_id: studentId),
    );

    expect(dto.toJson()['student_id'], studentId);
  });
}
