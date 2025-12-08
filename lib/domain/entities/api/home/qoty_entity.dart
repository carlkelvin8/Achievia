// ignore_for_file: public_member_api_docs, sort_constructors_first
class QotyEntity {
  final int quizId;
  final int id;
  final String questionText;
  final List<Map<String,dynamic>> choices;
  QotyEntity({
    required this.quizId,
    required this.id,
    required this.questionText,
    required this.choices,
  });
}


