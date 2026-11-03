import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';

/// How many results the Profile shows before "Show all".
const recentResultsPerKind = 10;

/// How many results of each kind (Take an Exam, Mock Boards) are loaded for
/// the Profile's exam history. Older ones used to fall out of the history
/// after 10, which looked as if they were never recorded.
const examHistoryLimit = 200;

/// Merge the latest Take an Exam subject exams with the latest Mock Board
/// attempts into one recent-results collection.
///
/// Only completed Question Bank subject exams (`attemptType` == `subject_exam`)
/// are eligible; practice attempts are excluded. The newest [limit] of each
/// kind are kept separately, so one kind can never push the other out of the
/// Profile. The collection is sorted by completion timestamp (newest first).
/// Sorting is deterministic: equal timestamps are broken first by result type
/// then by a stable id, so identical input always produces the same output.
List<ExaminationResult> mergeRecentExamResults({
  required List<QuestionBankAttempt> questionBankAttempts,
  required List<ExaminationResult> mockBoardResults,
  int limit = examHistoryLimit,
}) {
  final subjectExams = <_DatedResult>[];
  final mockBoards = <_DatedResult>[];

  for (final attempt in questionBankAttempts) {
    if (attempt.attemptType != QuestionBankAttempt.subjectExamType) continue;
    subjectExams.add(
      _DatedResult(
        type: _ResultType.subjectExam,
        id: attempt.id,
        timestamp: attempt.completedAt,
        result: ExaminationResult(
          examName: attempt.subjectTitle.isEmpty
              ? attempt.topicTitle
              : attempt.subjectTitle,
          date: _formatDate(attempt.completedAt),
          score: attempt.score,
          passingScore: questionBankPassingScore,
          attemptId: attempt.id.isEmpty ? null : attempt.id,
        ),
      ),
    );
  }

  for (var index = 0; index < mockBoardResults.length; index++) {
    final result = mockBoardResults[index];
    final timestamp = DateTime.tryParse(result.date);
    mockBoards.add(
      _DatedResult(
        type: _ResultType.mockBoard,
        // Mock Board result rows carry no id; name + position is stable for
        // the given list, and equal timestamps stay deterministic.
        id: result.examName,
        timestamp: timestamp,
        // Same local date format as the subject exams (the row stores UTC).
        result: timestamp == null
            ? result
            : ExaminationResult(
                examName: result.examName,
                date: _formatDate(timestamp),
                score: result.score,
                passingScore: result.passingScore,
                attemptId: result.attemptId,
                mockBoardAttemptNo: result.mockBoardAttemptNo,
              ),
      ),
    );
  }

  subjectExams.sort(_compareNewestFirst);
  mockBoards.sort(_compareNewestFirst);
  final entries = [...subjectExams.take(limit), ...mockBoards.take(limit)]
    ..sort(_compareNewestFirst);
  return entries.map((entry) => entry.result).toList();
}

String _formatDate(DateTime value) =>
    value.toLocal().toString().split('.').first;

enum _ResultType { subjectExam, mockBoard }

class _DatedResult {
  final _ResultType type;
  final String id;
  final DateTime? timestamp;
  final ExaminationResult result;

  const _DatedResult({
    required this.type,
    required this.id,
    required this.timestamp,
    required this.result,
  });
}

int _compareNewestFirst(_DatedResult left, _DatedResult right) {
  final leftTime = left.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
  final rightTime = right.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
  final byTime = rightTime.compareTo(leftTime);
  if (byTime != 0) return byTime;
  final byType = left.type.index.compareTo(right.type.index);
  if (byType != 0) return byType;
  return left.id.compareTo(right.id);
}
