class AnswerQuestionNotifier {
  final String quiz_id;
  final String student_id;
  final String chosen_answer;
  AnswerQuestionNotifier({
    required this.quiz_id,
    required this.student_id,
    required this.chosen_answer,
  });

  AnswerQuestionNotifier copyWith({
    String? quiz_id,
    String? student_id,
    String? chosen_answer,
  }) {
    return AnswerQuestionNotifier(
      quiz_id: quiz_id ?? this.quiz_id,
      student_id: student_id ?? this.student_id,
      chosen_answer: chosen_answer ?? this.chosen_answer,
    );
  }
}
