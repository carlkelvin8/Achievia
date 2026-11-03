import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same title -> section table is executed against PostgreSQL by
/// `scripts/test_mock_board_grading.py` (`SECTION_TITLES`). Keeping both in
/// step guarantees the app builds boards with the sections the server accepts.
const _expected = <String, List<int>>{
  'Clinical Chemistry': [1],
  'Clinical Chemistry (Advanced)': [1],
  'Microbiology & Parasitology': [2],
  'Bacteriology': [2],
  'Mycology and Virology': [2],
  'Clinical Microscopy': [3],
  'Hematology': [4],
  'Immunohematology': [5],
  'Blood Banking / Serology': [5],
  'Histopathology': [6],
  'Medical Technology Laws/Ethics': [6],
  'Anatomy': [],
};

void main() {
  test('subject titles map to the same sections the server accepts', () {
    _expected.forEach((title, sections) {
      final matched = [
        for (final spec in mockBoardSectionSpecs)
          if (isMockBoardSectionSubject({'title': title}, spec)) spec.id,
      ];
      expect(matched, sections, reason: title);
    });
  });

  test('section ids and titles match the server blueprint', () {
    expect(
      [for (final spec in mockBoardSectionSpecs) spec.id],
      [1, 2, 3, 4, 5, 6],
    );
    expect(
      [for (final spec in mockBoardSectionSpecs) spec.title],
      [
        'Clinical Chemistry',
        'Microbiology and Parasitology',
        'Clinical Microscopy',
        'Hematology',
        'Blood Banking and Serology',
        'Histopathology and Medical Technology Laws/Ethics',
      ],
    );
  });
}
