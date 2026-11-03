import 'package:achievia/core/utils/subject_performance.dart';
import 'package:flutter_test/flutter_test.dart';

SubjectExamAttempt _a(int id, String name, double pct, {int day = 1}) =>
    SubjectExamAttempt(
      subjectId: id,
      subjectName: name,
      percentage: pct,
      completedAt: DateTime.utc(2026, 1, day),
    );

const _chem = 1;
const _bact = 2;
const _hema = 3;

SubjectPerformanceSummary _s(List<SubjectExamAttempt> a) =>
    summarizeSubjectPerformance(a);

Map<String, dynamic> _row({
  Object? subjectId = 1,
  Object? correct = 9,
  Object? total = 10,
  Object? completedAt = '2026-01-01T00:00:00Z',
  Object? title = 'Chemistry',
  Object? type = 'subject_exam',
}) => {
  'attempt_type': type,
  'subject_id': subjectId,
  'correct_answers': correct,
  'total_questions': total,
  'completed_at': completedAt,
  'subjects': title == null ? null : {'title': title},
};

void main() {
  group('ranking', () {
    test('case 1: single subject has no weakest', () {
      final r = _s([_a(_chem, 'Clinical Chemistry', 90)]);
      expect(r.best!.subjectName, 'Clinical Chemistry');
      expect(r.best!.averagePercentage, 90);
      expect(r.weakest, isNull);
    });

    test('empty input has neither', () {
      final r = _s([]);
      expect(r.best, isNull);
      expect(r.weakest, isNull);
    });

    test('case 2: two subjects', () {
      final r = _s([_a(_chem, 'CC', 90), _a(_bact, 'Bact', 67)]);
      expect(r.best!.subjectName, 'CC');
      expect(r.weakest!.subjectName, 'Bact');
      expect(r.weakest!.averagePercentage, 67);
    });

    test('case 3: averages all attempts, not the latest', () {
      final r = _s([
        _a(_chem, 'CC', 90, day: 1),
        _a(_chem, 'CC', 20, day: 2),
        _a(_bact, 'Bact', 67),
      ]);
      expect(r.best!.subjectName, 'Bact');
      expect(r.weakest!.subjectName, 'CC');
      expect(r.weakest!.averagePercentage, 55);
      expect(r.weakest!.completedExamCount, 2);
    });

    test('case 4: three subjects', () {
      final r = _s([
        _a(_chem, 'CC', 55),
        _a(_bact, 'Bact', 67),
        _a(_hema, 'Hema', 35),
      ]);
      expect(r.best!.subjectName, 'Bact');
      expect(r.weakest!.subjectName, 'Hema');
    });

    test('case 5: equal average, more attempts wins best', () {
      final r = _s([
        for (var i = 1; i <= 3; i++) _a(_chem, 'CC', 80, day: i),
        for (var i = 1; i <= 2; i++) _a(_bact, 'Bact', 80, day: i),
      ]);
      expect(r.best!.subjectName, 'CC');
    });

    test('case 6: equal average and count, newer wins best', () {
      final r = _s([
        for (var i = 1; i <= 3; i++) _a(_chem, 'CC', 80, day: i),
        for (var i = 1; i <= 3; i++) _a(_bact, 'Bact', 80, day: i + 5),
      ]);
      expect(r.best!.subjectName, 'Bact');
    });

    test('case 7: equal lowest average, more attempts wins weakest', () {
      final r = _s([
        for (var i = 1; i <= 4; i++) _a(_chem, 'CC', 60, day: i),
        for (var i = 1; i <= 2; i++) _a(_bact, 'Bact', 60, day: i),
        _a(_hema, 'Hema', 90),
      ]);
      expect(r.weakest!.subjectName, 'CC');
    });

    test('case 8: equal average and count, newer wins weakest', () {
      final r = _s([
        for (var i = 1; i <= 4; i++) _a(_chem, 'CC', 60, day: i),
        for (var i = 1; i <= 4; i++) _a(_bact, 'Bact', 60, day: i + 5),
      ]);
      expect(r.weakest!.subjectName, 'Bact');
    });

    test('recency never overrides a better average', () {
      final r = _s([
        _a(_chem, 'CC', 80, day: 1),
        _a(_bact, 'Bact', 79, day: 9),
      ]);
      expect(r.best!.subjectName, 'CC');
    });

    test('full precision is used, not rounded values', () {
      final r = _s([_a(_chem, 'CC', 79.49), _a(_bact, 'Bact', 79.51)]);
      expect(r.best!.subjectName, 'Bact');
      expect(r.weakest!.subjectName, 'CC');
    });

    test('exact tie is deterministic by subject id', () {
      final same = [_a(_bact, 'Bact', 70), _a(_chem, 'CC', 70)];
      expect(_s(same).best!.subjectId, _chem);
      expect(_s(same.reversed.toList()).best!.subjectId, _chem);
    });

    test('groups by subject id even if names differ', () {
      final r = _s([
        _a(_chem, 'CC', 100),
        _a(_chem, 'cc ', 50),
        _a(2, 'X', 10),
      ]);
      expect(r.best!.completedExamCount, 2);
      expect(r.best!.averagePercentage, 75);
    });
  });

  group('SubjectExamAttempt.tryFromRow', () {
    test('case 13: percentages are averaged, not weighted', () {
      final r = _s([
        SubjectExamAttempt.tryFromRow(_row(correct: 45, total: 50))!,
        SubjectExamAttempt.tryFromRow(_row(correct: 60, total: 100))!,
      ]);
      expect(r.best!.averagePercentage, 75);
    });

    test('case 12 and other invalid rows are excluded', () {
      expect(SubjectExamAttempt.tryFromRow(_row(total: 0)), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(total: null)), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(correct: null)), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(correct: 11)), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(subjectId: null)), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(completedAt: 'bad')), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(completedAt: null)), isNull);
    });

    test('practice and untyped attempts never count', () {
      expect(SubjectExamAttempt.tryFromRow(_row(type: 'practice')), isNull);
      expect(SubjectExamAttempt.tryFromRow(_row(type: null)), isNull);
    });

    test('subject without a name is not ranked and never shown as unknown', () {
      final attempt = SubjectExamAttempt.tryFromRow(_row(title: null))!;
      final r = _s([attempt]);
      expect(r.best, isNull);
    });
  });
}
