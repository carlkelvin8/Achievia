import 'package:achievia/core/utils/achievia_grading.dart';
import 'package:achievia/core/utils/helpers.dart' show gradingBrackets;
import 'package:achievia/core/utils/question_bank_helpers.dart'
    show questionBankPassingScore;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizePercentage', () {
    test('passes valid percentages through unchanged with full precision', () {
      expect(sanitizePercentage(0), 0);
      expect(sanitizePercentage(74.999), 74.999);
      expect(sanitizePercentage(75), 75);
      expect(sanitizePercentage(100), 100);
    });

    test('maps invalid inputs to a deterministic safe value', () {
      expect(sanitizePercentage(null), 0);
      expect(sanitizePercentage(double.nan), 0);
      expect(sanitizePercentage(double.infinity), 0);
      expect(sanitizePercentage(double.negativeInfinity), 0);
      expect(sanitizePercentage(-1), 0);
      expect(sanitizePercentage(104), 100);
    });
  });

  group('isPassing', () {
    test('compares the raw numerical percentage, never a formatted string', () {
      expect(isPassing(score: 0, passingScore: 75), isFalse);
      expect(isPassing(score: 74, passingScore: 75), isFalse);
      expect(isPassing(score: 74.999, passingScore: 75), isFalse);
      expect(isPassing(score: 75, passingScore: 75), isTrue);
      expect(isPassing(score: 76, passingScore: 75), isTrue);
      expect(isPassing(score: 100, passingScore: 75), isTrue);
    });

    test('uses the shared passing boundary by default', () {
      expect(questionBankPassingScore, 75);
      expect(
        isPassing(score: 74, passingScore: questionBankPassingScore),
        isFalse,
      );
      expect(
        isPassing(score: 75, passingScore: questionBankPassingScore),
        isTrue,
      );
    });
  });

  group('bracket boundaries', () {
    test('every boundary value resolves to its declared bracket', () {
      const expectations = <(double, int)>[
        (0, 0),
        (49.999, 0),
        (50, 1),
        (64.999, 1),
        (65, 2),
        (74.999, 2),
        (75, 3),
        (84.999, 3),
        (85, 4),
        (89.999, 4),
        (90, 5),
        (100, 5),
      ];
      for (final (score, index) in expectations) {
        final resolved = bracketForPercentage(score);
        expect(
          resolved.level,
          gradingBrackets[index].level,
          reason: 'score $score should resolve to bracket at index $index',
        );
        expect(
          resolved.message,
          gradingBrackets[index].message,
          reason: 'interpretation for $score must come from the same bracket',
        );
      }
    });

    test('each bracket is reachable at its own inclusive lower bound', () {
      for (var index = 0; index < gradingBrackets.length; index++) {
        final bracket = gradingBrackets[index];
        final resolved = bracketForPercentage(bracket.minScore);
        expect(
          resolved.level,
          bracket.level,
          reason: 'minScore ${bracket.minScore} must map to its own bracket',
        );
        expect(resolved.message, bracket.message);
      }
    });

    test('resolution is monotonic across 0..100 with no gaps', () {
      final levelIndexOf = <String, int>{
        for (var i = 0; i < gradingBrackets.length; i++)
          gradingBrackets[i].level: i,
      };
      final seen = <String>{};
      String? previous;
      for (var score = 0.0; score <= 100; score += 0.25) {
        final level = bracketForPercentage(score).level;
        seen.add(level);
        if (previous != null) {
          expect(
            levelIndexOf[level]! >= levelIndexOf[previous]!,
            isTrue,
            reason: 'score $score regressed from "$previous" to "$level"',
          );
        }
        previous = level;
      }
      expect(seen.length, gradingBrackets.length);
    });

    test('declared ranges are strictly increasing and start at 0', () {
      expect(gradingBrackets.first.minScore, 0);
      expect(gradingBrackets.last.maxScoreExclusive, isNull);
      for (var i = 0; i < gradingBrackets.length; i++) {
        final current = gradingBrackets[i];
        final next = i + 1 < gradingBrackets.length
            ? gradingBrackets[i + 1]
            : null;
        if (next != null) {
          expect(
            next.minScore,
            current.maxScoreExclusive,
            reason: 'brackets $i and ${i + 1} must be contiguous',
          );
        }
      }
    });
  });

  group('gradePercentage', () {
    test('resolves status, bracket and interpretation', () {
      final passed = gradePercentage(80);
      expect(passed.percentage, 80);
      expect(passed.passed, isTrue);
      expect(passed.statusLabel, 'PASSED');
      expect(passed.level, gradingBrackets[3].level);
      expect(passed.message, gradingBrackets[3].message);

      final failed = gradePercentage(72);
      expect(failed.percentage, 72);
      expect(failed.passed, isFalse);
      expect(failed.statusLabel, 'FAILED');
      expect(failed.level, gradingBrackets[2].level);
      expect(failed.message, gradingBrackets[2].message);
    });

    test('passes exactly at 75 and fails just below', () {
      expect(gradePercentage(74.999).passed, isFalse);
      expect(gradePercentage(75).passed, isTrue);
      expect(gradePercentage(100).passed, isTrue);
      expect(gradePercentage(0).passed, isFalse);
    });

    test('grades invalid percentages deterministically', () {
      for (final raw in <double>[double.nan, double.infinity, -5]) {
        final grade = gradePercentage(raw);
        expect(grade.percentage, 0);
        expect(grade.passed, isFalse);
        expect(grade.level, gradingBrackets.first.level);
      }

      final above = gradePercentage(900);
      expect(above.percentage, 100);
      expect(above.passed, isTrue);
      expect(above.level, gradingBrackets.last.level);
    });

    test('respects a custom passing boundary', () {
      final grade = gradePercentage(78, passingScore: 80);
      expect(grade.passed, isFalse);
      expect(grade.statusLabel, 'FAILED');
      expect(gradePercentage(80, passingScore: 80).passed, isTrue);
    });
  });
}
