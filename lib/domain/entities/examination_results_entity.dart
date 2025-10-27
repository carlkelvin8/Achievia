class ExaminationResult {
  final String examName;
  final String date;
  final double score;
  final double passingScore;

  const ExaminationResult({
    required this.examName,
    required this.date,
    required this.score,
    required this.passingScore,
  });
}