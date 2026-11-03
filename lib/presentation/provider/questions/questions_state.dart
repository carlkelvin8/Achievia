// ignore_for_file: public_member_api_docs, sort_constructors_first
class AnswerQuestionNotifier {
  final String quizId;
  final String studentId;
  final String chosenAnswer;
  final bool isLoading;
  AnswerQuestionNotifier({
    required this.quizId,
    required this.studentId,
    required this.chosenAnswer,
    required this.isLoading,
  });

  AnswerQuestionNotifier copyWith({
    String? quizId,
    String? studentId,
    String? chosenAnswer,
    bool? isLoading,
  }) {
    return AnswerQuestionNotifier(
      isLoading: isLoading ?? this.isLoading,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      chosenAnswer: chosenAnswer ?? this.chosenAnswer,
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
