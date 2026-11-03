/// A single option of today's Question of the Day.
class QotdChoice {
  final int id;
  final String text;
  final bool isCorrect;

  const QotdChoice({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}

/// A subject eligible for the Question of the Day rotation.
class QotdSubject {
  final int id;
  final String title;

  const QotdSubject({required this.id, required this.title});
}

/// The daily question resolved for the current cycle.
class QotdDailyQuestion {
  final int questionId;
  final int quizId;
  final String questionText;
  final String imagePath;

  /// Empty when the question does not carry an explanation. The UI then shows
  /// nothing; no placeholder content is ever invented.
  final String rationale;
  final List<QotdChoice> choices;

  const QotdDailyQuestion({
    required this.questionId,
    required this.quizId,
    required this.questionText,
    this.imagePath = '',
    this.rationale = '',
    required this.choices,
  });
}

/// The user's persisted answer for the current daily cycle, if one exists.
class QotdUserAnswer {
  final int choiceId;
  final bool isCorrect;
  final DateTime answeredAt;

  const QotdUserAnswer({
    required this.choiceId,
    required this.isCorrect,
    required this.answeredAt,
  });
}

/// Single source of truth for the Question of the Day card.
class QuestionOfTheDayState {
  /// The UTC+8 calendar day this state belongs to.
  final String dayKey;
  final String subjectTitle;
  final int questionId;
  final int quizId;
  final String questionText;
  final String imagePath;
  final String rationale;
  final List<QotdChoice> choices;

  /// Index within [choices] of the persisted answer, or null when unanswered.
  final int? selectedIndex;
  final bool isAnswered;
  final bool isCorrect;
  final bool isSaving;
  final String? errorMessage;

  const QuestionOfTheDayState._({
    required this.dayKey,
    required this.subjectTitle,
    required this.questionId,
    required this.quizId,
    required this.questionText,
    required this.imagePath,
    required this.rationale,
    required this.choices,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrect,
    required this.isSaving,
    required this.errorMessage,
  });

  factory QuestionOfTheDayState.loaded({
    required String dayKey,
    required String subjectTitle,
    required QotdDailyQuestion question,
    required QotdUserAnswer? answer,
  }) {
    // A persisted answer whose choice is no longer present still counts as
    // answered (the user cannot answer again), but no option is highlighted.
    final matchedIndex = answer == null
        ? -1
        : question.choices.indexWhere((choice) => choice.id == answer.choiceId);
    return QuestionOfTheDayState._(
      dayKey: dayKey,
      subjectTitle: subjectTitle,
      questionId: question.questionId,
      quizId: question.quizId,
      questionText: question.questionText,
      imagePath: question.imagePath,
      rationale: question.rationale,
      choices: question.choices,
      selectedIndex: matchedIndex >= 0 ? matchedIndex : null,
      isAnswered: answer != null,
      isCorrect: answer?.isCorrect ?? false,
      isSaving: false,
      errorMessage: null,
    );
  }

  QuestionOfTheDayState copyWith({
    int? selectedIndex,
    bool clearSelection = false,
    bool? isAnswered,
    bool? isCorrect,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuestionOfTheDayState._(
      dayKey: dayKey,
      subjectTitle: subjectTitle,
      questionId: questionId,
      quizId: quizId,
      questionText: questionText,
      imagePath: imagePath,
      rationale: rationale,
      choices: choices,
      selectedIndex: clearSelection
          ? null
          : (selectedIndex ?? this.selectedIndex),
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
