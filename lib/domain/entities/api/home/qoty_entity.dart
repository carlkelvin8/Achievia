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
  final String chosen_ans;
  final int quiz_id;
  final String student_id;
  QotyEntityPost({
    required this.chosen_ans,
    required this.quiz_id,
    required this.student_id,
  });
}
