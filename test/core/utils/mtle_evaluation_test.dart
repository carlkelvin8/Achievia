import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scores in [mockBoardSectionSpecs] order.
List<Map<String, dynamic>> _answers(List<num> scores) => [
  for (var i = 0; i < scores.length; i++)
    {'name': mockBoardSectionSpecs[i].title, 'score': scores[i]},
];

void main() {
  group('utcTimestampText', () {
    test('a timestamp without an offset is read as UTC', () {
      final parsed = DateTime.parse(
        utcTimestampText('2026-11-03T02:59:46.482'),
      );

      expect(parsed.isUtc, isTrue);
      expect(parsed, DateTime.utc(2026, 11, 3, 2, 59, 46, 482));
    });

    test('a value with an offset or without a time is left as it is', () {
      for (final text in [
        '2026-11-03T02:59:46+00:00',
        '2026-11-03T02:59:46Z',
        '2026-11-03',
        '',
      ]) {
        expect(utcTimestampText(text), text);
      }
      expect(utcTimestampText(null), '');
    });
  });

  test('the sections are in the order the weights assume', () {
    expect(mockBoardSectionSpecs.map((spec) => spec.title), [
      'Clinical Chemistry',
      'Microbiology and Parasitology',
      'Clinical Microscopy',
      'Hematology',
      'Blood Banking and Serology',
      'Histopathology and Medical Technology Laws/Ethics',
    ]);
  });

  test('GWA uses the MTLE weights (reported attempt: 26.40, not 25.50)', () {
    final result = evaluateMtleResult(_answers([32, 26, 19, 21, 28, 31]));

    expect(result.gwa, 26.40);
    expect(result.passed, isFalse);
  });

  test('each subject carries its own weight', () {
    const expected = [20.0, 20.0, 10.0, 20.0, 20.0, 10.0];
    for (var section = 0; section < expected.length; section++) {
      final scores = List<num>.filled(6, 0)..[section] = 100;
      expect(evaluateMtleResult(_answers(scores)).gwa, expected[section]);
    }
  });

  test('Blood Banking is a major subject, Clinical Microscopy is not', () {
    final lowMicroscopy = evaluateMtleResult(
      _answers([90, 90, 49, 90, 90, 90]),
    );
    expect(lowMicroscopy.hasMajorBelow50, isFalse);
    expect(lowMicroscopy.passed, isTrue);

    final lowBloodBanking = evaluateMtleResult(
      _answers([90, 90, 90, 90, 49, 90]),
    );
    expect(lowBloodBanking.hasMajorBelow50, isTrue);
    expect(lowBloodBanking.passed, isFalse);
  });

  test('failed weight adds up the corrected weights', () {
    final result = evaluateMtleResult(_answers([90, 90, 60, 90, 60, 90]));

    expect(result.failedWeight, 30);
  });
}
