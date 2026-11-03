import 'package:achievia/core/utils/achievia_grading.dart';
import 'package:achievia/core/utils/helpers.dart' show gradingBrackets;
import 'package:achievia/core/utils/progress_aggregator.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Progress level/message come from the shared grading brackets', () {
    for (final bracket in gradingBrackets) {
      final score = bracket.minScore.toDouble();
      final result = aggregateProgress(
        snapshot: ProgressSnapshotDto(
          activeDays: const [],
          studySessions: const [],
          quizAttempts: [
            {'score': score, 'attempted_at': '2026-09-26', 'answer': []},
          ],
        ),
        startDate: DateTime(2026, 9, 26),
        today: DateTime(2026, 9, 26),
      );
      final shared = bracketForPercentage(score);
      expect(shared.level, bracket.level);
      expect(result.level, bracket.level);
      expect(result.message, bracket.message);
    }
  });

  test('combines subject scores and uses summary when answers are empty', () {
    final result = aggregateProgress(
      snapshot: const ProgressSnapshotDto(
        activeDays: [],
        studySessions: [],
        quizAttempts: [
          {
            'score': 80,
            'attempted_at': '2026-09-25',
            'answer': [],
            'summary': '[{"name":"Chemistry","score":80}]',
          },
          {
            'score': 60,
            'attempted_at': '2026-09-26',
            'answer': [
              {'name': 'Hematology', 'score': 60},
            ],
          },
          {
            'score': 100,
            'attempted_at': '2026-09-26T10:00:00',
            'answer': [
              {'name': 'Chemistry', 'score': 100},
            ],
          },
        ],
      ),
      startDate: DateTime(2026, 9, 25),
      today: DateTime(2026, 9, 26),
    );
    // Mock Board subject breakdowns must not drive Best/Weakest Subject.
    expect(result.strengthWeakness.bestSubject, 'N/A');
    expect(result.strengthWeakness.weakestSubject, 'N/A');
    expect(result.scoreHistory.map((score) => score.score), [80, 60, 100]);
  });

  test('best and weakest come from individual subject exams only', () {
    Map<String, dynamic> row(int id, String name, int correct, int total) => {
      'attempt_type': 'subject_exam',
      'subject_id': id,
      'subjects': {'title': name},
      'correct_answers': correct,
      'total_questions': total,
      'completed_at': '2026-09-26T10:00:00Z',
    };
    final result = aggregateProgress(
      snapshot: ProgressSnapshotDto(
        activeDays: const [],
        studySessions: const [],
        quizAttempts: const [
          {
            'score': 10,
            'attempted_at': '2026-09-26',
            'answer': [
              {'name': 'Hematology', 'score': 1},
            ],
          },
        ],
        subjectExamAttempts: [
          row(1, 'Chemistry', 45, 50),
          row(1, 'Chemistry', 60, 100),
          row(2, 'Bacteriology', 67, 100),
        ],
      ),
      startDate: DateTime(2026, 9, 25),
      today: DateTime(2026, 9, 26),
    );
    expect(result.strengthWeakness.bestSubject, 'Chemistry');
    expect(result.strengthWeakness.bestAverage, 75);
    expect(result.strengthWeakness.weakestSubject, 'Bacteriology');
    expect(result.strengthWeakness.weakestAverage, 67);
  });

  group('Subject performance graph data', () {
    Map<String, dynamic> exam({
      required int id,
      String name = 'Chemistry',
      required double score,
      required String completedAt,
      Object? storedScore,
      String? attemptId,
    }) {
      return {
        'id': attemptId ?? 'attempt-$id',
        'attempt_type': 'subject_exam',
        'subject_id': id,
        'subjects': {'title': name},
        'correct_answers': score.round(),
        'total_questions': 100,
        if (storedScore != null) 'score': storedScore,
        'completed_at': completedAt,
      };
    }

    ProgressEntity aggregate(List<Map<String, dynamic>> rows) =>
        aggregateProgress(
          snapshot: ProgressSnapshotDto(
            activeDays: const [],
            studySessions: const [],
            quizAttempts: const [],
            subjectExamAttempts: rows,
          ),
          startDate: DateTime(2026, 9, 1),
          today: DateTime(2026, 9, 30),
        );

    test(
      'comes only from subject exams, one chronological line per subject',
      () {
        final result = aggregate([
          exam(
            id: 1,
            score: 80,
            completedAt: '2026-09-10T10:00:00',
            attemptId: 'a1',
          ),
          exam(
            id: 1,
            score: 90,
            completedAt: '2026-09-20T10:00:00',
            attemptId: 'a2',
          ),
          {
            'attempt_type': 'practice',
            'subject_id': 1,
            'subjects': {'title': 'Chemistry'},
            'correct_answers': 99,
            'total_questions': 100,
            'completed_at': '2026-09-25T10:00:00',
          },
        ]);

        expect(result.subjectHistory.isEmpty, isFalse);
        expect(result.subjectHistory.keys.toList(), ['Chemistry']);
        final line = result.subjectHistory['Chemistry']!;
        expect(line.map((point) => point.score), [80, 90]);
        expect(line.map((point) => point.date.toIso8601String()), [
          '2026-09-10T10:00:00.000',
          '2026-09-20T10:00:00.000',
        ]);
      },
    );

    test('ignores Mock Board score rows entirely', () {
      final result = aggregate(const []);

      expect(result.scoreHistory, isEmpty);
      expect(result.subjectHistory, isEmpty);

      final withMockBoards = aggregateProgress(
        snapshot: const ProgressSnapshotDto(
          activeDays: [],
          studySessions: [],
          quizAttempts: [
            {
              'score': 85,
              'attempted_at': '2026-09-25',
              'answer': [
                {'name': 'Chemistry', 'score': 85},
              ],
            },
          ],
          subjectExamAttempts: [],
        ),
        startDate: DateTime(2026, 9, 1),
        today: DateTime(2026, 9, 30),
      );
      expect(withMockBoards.scoreHistory.map((point) => point.score), [85]);
      expect(withMockBoards.subjectHistory, isEmpty);
    });

    test('uses the stored score when present and computes otherwise', () {
      final result = aggregate([
        {
          'id': 'a-stored',
          'attempt_type': 'subject_exam',
          'subject_id': 1,
          'subjects': {'title': 'Chemistry'},
          'correct_answers': 80,
          'total_questions': 100,
          'score': 62.5,
          'completed_at': '2026-09-10T10:00:00',
        },
        {
          'id': 'a-computed',
          'attempt_type': 'subject_exam',
          'subject_id': 2,
          'subjects': {'title': 'Biology'},
          'correct_answers': 30,
          'total_questions': 40,
          'completed_at': '2026-09-11T10:00:00',
        },
      ]);

      expect(result.subjectHistory['Chemistry']!.single.score, 62.5);
      expect(result.subjectHistory['Biology']!.single.score, 75);
    });

    test('a renamed subject stays on the same line under the latest name', () {
      final result = aggregate([
        exam(
          id: 1,
          name: 'Clinical Chemistry',
          score: 70,
          completedAt: '2026-09-10T10:00:00',
          attemptId: 'a1',
        ),
        exam(
          id: 1,
          name: 'Analytical Chemistry',
          score: 85,
          completedAt: '2026-09-20T10:00:00',
          attemptId: 'a2',
        ),
      ]);

      expect(result.subjectHistory.keys.toList(), ['Analytical Chemistry']);
      expect(result.subjectHistory['Analytical Chemistry']!.length, 2);
    });

    test('same display name with different ids stays on separate lines', () {
      final result = aggregate([
        exam(
          id: 1,
          score: 70,
          completedAt: '2026-09-10T10:00:00',
          attemptId: 'a1',
        ),
        exam(
          id: 2,
          score: 85,
          completedAt: '2026-09-20T10:00:00',
          attemptId: 'a2',
        ),
      ]);

      expect(result.subjectHistory.keys.toSet(), {
        'Chemistry',
        'Chemistry (2)',
      });
    });

    test('duplicated attempt rows are collapsed by id', () {
      final result = aggregate([
        exam(
          id: 1,
          score: 80,
          completedAt: '2026-09-10T10:00:00',
          attemptId: 'dup',
        ),
        exam(
          id: 1,
          score: 90,
          completedAt: '2026-09-20T10:00:00',
          attemptId: 'dup',
        ),
      ]);

      expect(result.subjectHistory['Chemistry']!.length, 1);
    });

    test('an empty subjectHistory is an empty map', () {
      expect(aggregate(const []).subjectHistory, isEmpty);
    });
  });
}
