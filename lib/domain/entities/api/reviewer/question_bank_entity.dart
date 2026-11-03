import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

class QuestionBankSubject {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final String image;

  const QuestionBankSubject({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.image,
  });
}

class QuestionBankTopic {
  final int id;
  final int subjectId;
  final String title;
  final String description;

  const QuestionBankTopic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
  });
}

class QuestionBankSelection {
  final QuestionBankSubject subject;

  /// Null for a Take an Exam (subject wide) session, which has no subtopic.
  final QuestionBankTopic? topic;

  const QuestionBankSelection({required this.subject, this.topic});

  bool get isSubjectExam => topic == null;

  String get attemptType => isSubjectExam
      ? QuestionBankAttempt.subjectExamType
      : QuestionBankAttempt.practiceType;
}

class QuestionBankAttempt {
  final String id;
  final String userId;
  final int subjectId;
  final int? topicId;
  final String subjectTitle;
  final String topicTitle;
  final int correctAnswers;
  final int totalQuestions;
  final double score;
  final DateTime completedAt;

  /// `practice` (one subtopic) or `subject_exam` (Take an Exam). Only
  /// subject exams count toward Best / Weakest Subject.
  final String attemptType;

  /// True only when the exam's item snapshots were persisted with this attempt
  /// (new-style save). Older attempts and score-only fallbacks have none and
  /// cannot be reopened as a summary.
  final bool hasSummary;

  static const practiceType = 'practice';
  static const subjectExamType = 'subject_exam';

  const QuestionBankAttempt({
    required this.id,
    required this.userId,
    required this.subjectId,
    this.topicId,
    required this.subjectTitle,
    required this.topicTitle,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.completedAt,
    this.attemptType = practiceType,
    this.hasSummary = false,
  });
}

class QuestionBankTopicArgs {
  final QuestionBankSubject subject;

  const QuestionBankTopicArgs(this.subject);
}

/// Route arguments of the subtopic Study Mode screen.
class StudyModeArgs {
  final QuestionBankSubject subject;
  final QuestionBankTopic topic;

  const StudyModeArgs(this.subject, this.topic);
}

class QuestionBankPracticeArgs {
  final QuestionBankSelection selection;

  /// Pre-selected questions for a subject exam; fixed for the whole attempt.
  final List<QuestionItemEntity>? examQuestions;

  const QuestionBankPracticeArgs(this.selection, {this.examQuestions});
}

class QuestionBankResultArgs {
  final QuestionBankSelection selection;
  final QuestionBankAttempt attempt;
  final bool isSaved;

  /// In-memory snapshot of the just-finished exam. Used to retry the save with
  /// the exact same items and, only when nothing was persisted, for an
  /// immediate non-persistent summary. Null for practice.
  final ExamAttemptSnapshot? snapshot;

  const QuestionBankResultArgs({
    required this.selection,
    required this.attempt,
    required this.isSaved,
    this.snapshot,
  });
}

class QuestionBankCompletion {
  final QuestionBankAttempt attempt;
  final bool isSaved;
  final ExamAttemptSnapshot? snapshot;

  const QuestionBankCompletion({
    required this.attempt,
    required this.isSaved,
    this.snapshot,
  });
}

class QuestionBankCourseMissingException implements Exception {
  const QuestionBankCourseMissingException();

  @override
  String toString() => 'Your profile does not have an assigned course.';
}
