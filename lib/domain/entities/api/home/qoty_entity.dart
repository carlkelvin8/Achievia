// ignore_for_file: public_member_api_docs, sort_constructors_first
class QotyEntity {
  final int quizId;
  final int id;
  final String title;
  final String questionText;
  final List<Map<String, dynamic>> choices;
  final List<Map<String, dynamic>>? questions;

  QotyEntity({
    required this.quizId,
    required this.title,
    required this.id,
    required this.questionText,
    required this.choices,
    this.questions,
  });
}

class QotyEntityPost {
  final String chosenAns;
  final int quizId;
  final String studentId;
  QotyEntityPost({
    required this.chosenAns,
    required this.quizId,
    required this.studentId,
  });
}
