// ignore_for_file: public_member_api_docs, sort_constructors_first
class AnswerQuestionNotifier {
  final String quiz_id;
  final String student_id;
  final String chosen_answer;
  final bool isLoading;
  AnswerQuestionNotifier({
    required this.quiz_id,
    required this.student_id,
    required this.chosen_answer,
    required this.isLoading,
  });

  AnswerQuestionNotifier copyWith({
    String? quiz_id,
    String? student_id,
    String? chosen_answer,
    bool? isLoading,
  }) {
    return AnswerQuestionNotifier(
      isLoading: isLoading ?? this.isLoading,
      quiz_id: quiz_id ?? this.quiz_id,
      student_id: student_id ?? this.student_id,
      chosen_answer: chosen_answer ?? this.chosen_answer,
    );
  }
}

class ResumeQuestionState {
  final bool isLoading;
  final bool isFetching;
  final double currentPage;
  ResumeQuestionState({
    required this.isLoading,
    required this.isFetching,
    required this.currentPage,
  });


  ResumeQuestionState copyWith({
    bool? isLoading,
    bool? isFetching,
    double? currentPage,
  }) {
    return ResumeQuestionState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
