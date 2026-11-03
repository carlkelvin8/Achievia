import 'dart:io';

import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('image_path of a question survives into the quiz DTO and entity', () {
    final dto = QuestionsItemsDto.fromJson({
      'id': 5,
      'questionText': 'Which organism is shown?',
      'imagePath': 'questions/plate.jpg',
      'choices': [
        {'id': 1, 'choiceText': 'A', 'is_correct': true, 'questionId': 5},
      ],
    });
    expect(dto.imagePath, 'questions/plate.jpg');

    final item = QuizDtoItems(
      id: 1,
      title: 'Picture-Based',
      description: '',
      createdAt: '',
      subjectId: 2,
      questions: [dto],
    );
    expect(item.toEntity().questions.single.imagePath, 'questions/plate.jpg');
  });

  test('a question without a picture has an empty image path', () {
    final dto = QuestionsItemsDto.fromJson({
      'id': 6,
      'questionText': 'Plain question',
      'choices': <Object>[],
    });
    expect(dto.imagePath, '');
  });

  test('the Mock Board loader downloads the image_path column', () {
    final source = File(
      'lib/core/utils/mock_board_loader.dart',
    ).readAsStringSync();
    expect(source, contains('id, quiz_id, question_text, image_path'));
  });
}
