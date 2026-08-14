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
  final QuestionBankTopic topic;

  const QuestionBankSelection({required this.subject, required this.topic});
}

class QuestionBankAttempt {
  final String id;
  final String userId;
  final int subjectId;
  final int topicId;
  final String subjectTitle;
  final String topicTitle;
  final int correctAnswers;
  final int totalQuestions;
  final double score;
  final DateTime completedAt;

  const QuestionBankAttempt({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.topicId,
    required this.subjectTitle,
    required this.topicTitle,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.completedAt,
  });
}

class QuestionBankTopicArgs {
  final QuestionBankSubject subject;

  const QuestionBankTopicArgs(this.subject);
}

class QuestionBankPracticeArgs {
  final QuestionBankSelection selection;

  const QuestionBankPracticeArgs(this.selection);
}

class QuestionBankResultArgs {
  final QuestionBankSelection selection;
  final QuestionBankAttempt attempt;
  final bool isSaved;

  const QuestionBankResultArgs({
    required this.selection,
    required this.attempt,
    required this.isSaved,
  });
}

class QuestionBankCompletion {
  final QuestionBankAttempt attempt;
  final bool isSaved;

  const QuestionBankCompletion({required this.attempt, required this.isSaved});
}

class QuestionBankCourseMissingException implements Exception {
  const QuestionBankCourseMissingException();

  @override
  String toString() => 'Your profile does not have an assigned course.';
}
