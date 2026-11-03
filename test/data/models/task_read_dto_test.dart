import 'package:achievia/data/models/task/task_read_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row({Object? description = 'Study'}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'task_name': 'Parasitology',
  'description': description,
  'user_id': '22222222-2222-2222-2222-222222222222',
  'is_done': false,
  'deadline': '2026-09-25T01:00:00+00:00',
  'created_at': '2026-09-01T00:00:00+00:00',
};

void main() {
  test('parses a complete row', () {
    final dto = TaskReadDto.fromJson(row());
    expect(dto.taskName, 'Parasitology');
    expect(dto.description, 'Study');
    expect(dto.isDone, isFalse);
  });

  test('a null description is an empty string, not an exception', () {
    expect(TaskReadDto.fromJson(row(description: null)).description, isEmpty);
  });
}
