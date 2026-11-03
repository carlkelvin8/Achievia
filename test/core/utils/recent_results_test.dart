import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/core/utils/recent_results.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeRecentExamResults', () {
    QuestionBankAttempt examAttempt({
      required String id,
      required int subjectId,
      required String subjectTitle,
      required double score,
      required DateTime completedAt,
      String topicTitle = '',
      String attemptType = QuestionBankAttempt.subjectExamType,
    }) {
      return QuestionBankAttempt(
        id: id,
        userId: 'user-1',
        subjectId: subjectId,
        subjectTitle: subjectTitle,
        topicTitle: topicTitle,
        correctAnswers: score.round(),
        totalQuestions: 100,
        score: score,
        completedAt: completedAt,
        attemptType: attemptType,
      );
    }

    ExaminationResult mockBoard(String name, String date, double score) {
      return ExaminationResult(
        examName: name,
        date: date,
        score: score,
        passingScore: 80,
      );
    }

    test('keeps each subject exam attempt id; Mock Board has none', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'attempt-x',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 80,
            completedAt: DateTime(2026, 9, 27, 10),
          ),
          // Same subject and score, different attempt: identity is the id.
          examAttempt(
            id: 'attempt-y',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 80,
            completedAt: DateTime(2026, 9, 26, 10),
          ),
        ],
        mockBoardResults: [mockBoard('Mock Board 1', '2026-09-25', 90)],
      );
      expect(results.map((r) => r.attemptId), ['attempt-x', 'attempt-y', null]);
      expect(results.map((r) => r.canOpenSummary), [true, true, false]);
    });

    test('an attempt without an id cannot open a summary', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: '',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 80,
            completedAt: DateTime(2026, 9, 27),
          ),
        ],
        mockBoardResults: const [],
      );
      expect(results.single.attemptId, isNull);
      expect(results.single.canOpenSummary, isFalse);
    });

    test('combines both sources newest first; caps only subject exams', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 60,
            completedAt: DateTime(2026, 9, 25, 10),
          ),
          examAttempt(
            id: 'a2',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 85,
            completedAt: DateTime(2026, 9, 27, 10),
          ),
        ],
        mockBoardResults: [
          mockBoard('Mock Board 1', '2026-09-24', 90),
          mockBoard('Mock Board 2', '2026-09-26', 78),
        ],
      );

      expect(results.map((r) => r.examName), [
        'Chemistry',
        'Mock Board 2',
        'Chemistry',
        'Mock Board 1',
      ]);
    });

    test('maps subject exam fields onto ExaminationResult', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: 'Microbiology',
            score: 92,
            completedAt: DateTime(2026, 9, 20, 9, 30),
          ),
        ],
        mockBoardResults: const [],
      );

      final result = results.single;
      expect(result.examName, 'Microbiology');
      expect(result.date, '2026-09-20 09:30:00');
      expect(result.score, 92);
      expect(result.passingScore, questionBankPassingScore);
    });

    test('falls back to the topic title when the subject title is empty', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: '',
            topicTitle: 'Enzymes',
            score: 70,
            completedAt: DateTime(2026, 9, 20),
          ),
        ],
        mockBoardResults: const [],
      );

      expect(results.single.examName, 'Enzymes');
    });

    test('excludes practice attempts entirely', () {
      final practice = examAttempt(
        id: 'p1',
        subjectId: 1,
        subjectTitle: 'Chemistry',
        score: 99,
        completedAt: DateTime(2026, 9, 30),
        attemptType: QuestionBankAttempt.practiceType,
      );

      final results = mergeRecentExamResults(
        questionBankAttempts: [practice],
        mockBoardResults: const [],
      );

      expect(results, isEmpty);
    });

    test('empty inputs yield an empty collection', () {
      expect(
        mergeRecentExamResults(
          questionBankAttempts: const [],
          mockBoardResults: const [],
        ),
        isEmpty,
      );
    });

    test('a single source beyond the limit is truncated', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 50,
            completedAt: DateTime(2026, 9, 1),
          ),
          examAttempt(
            id: 'a2',
            subjectId: 2,
            subjectTitle: 'Biology',
            score: 60,
            completedAt: DateTime(2026, 9, 2),
          ),
        ],
        mockBoardResults: const [],
        limit: 1,
      );

      expect(results.map((r) => r.examName), ['Biology']);
    });

    test('keeps the latest of each kind; one never pushes out the other', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          for (var day = 10; day < 22; day++)
            examAttempt(
              id: 'a$day',
              subjectId: 1,
              subjectTitle: 'Bacteriology',
              score: 20,
              completedAt: DateTime(2026, 10, day),
            ),
        ],
        mockBoardResults: [
          for (var day = 1; day <= 12; day++)
            mockBoard(
              'Mock Board $day',
              '2026-10-${day.toString().padLeft(2, '0')}T03:00:00Z',
              70,
            ),
        ],
        limit: recentResultsPerKind,
      );
      expect(
        results.where((r) => r.examName == 'Bacteriology'),
        hasLength(recentResultsPerKind),
      );
      final mockBoards = results
          .where((r) => r.examName.startsWith('Mock Board'))
          .map((r) => r.examName);
      expect(mockBoards, hasLength(recentResultsPerKind));
      // The newest ten Mock Boards are the ones kept.
      expect(mockBoards, isNot(contains('Mock Board 1')));
      expect(mockBoards, contains('Mock Board 12'));
    });

    test('a Mock Board stored in UTC shows and sorts by local time', () {
      const stored = '2026-11-03T02:59:46+00:00';
      final local = DateTime.parse(stored).toLocal();
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: 'Laws',
            score: 26,
            completedAt: local.subtract(const Duration(minutes: 58)),
          ),
        ],
        mockBoardResults: [mockBoard('Mock Board 10', stored, 26.4)],
      );

      expect(results.map((r) => r.examName), ['Mock Board 10', 'Laws']);
      expect(results.first.date, local.toString().split('.').first);
    });

    test('an unparseable mock board date sorts last', () {
      final results = mergeRecentExamResults(
        questionBankAttempts: [
          examAttempt(
            id: 'a1',
            subjectId: 1,
            subjectTitle: 'Chemistry',
            score: 70,
            completedAt: DateTime(2026, 9, 25),
          ),
        ],
        mockBoardResults: [mockBoard('Mock Board 1', 'not-a-date', 90)],
        limit: 1,
      );

      expect(results.map((r) => r.examName), ['Chemistry', 'Mock Board 1']);
    });

    test('equal timestamps resolve deterministically by type then id', () {
      final sameInstant = DateTime(2026, 9, 26);
      final inputAttempts = [
        examAttempt(
          id: 'b',
          subjectId: 2,
          subjectTitle: 'Biology',
          score: 60,
          completedAt: sameInstant,
        ),
        examAttempt(
          id: 'a',
          subjectId: 1,
          subjectTitle: 'Chemistry',
          score: 70,
          completedAt: sameInstant,
        ),
      ];
      const date = '2026-09-26';
      final inputMockBoards = [mockBoard('Mock Board 1', date, 80)];

      final results = mergeRecentExamResults(
        questionBankAttempts: inputAttempts,
        mockBoardResults: inputMockBoards,
      );
      final again = mergeRecentExamResults(
        questionBankAttempts: inputAttempts,
        mockBoardResults: inputMockBoards,
      );

      for (final merged in [results, again]) {
        expect(merged.map((r) => r.examName), [
          'Chemistry',
          'Biology',
          'Mock Board 1',
        ]);
      }
    });
  });
}
