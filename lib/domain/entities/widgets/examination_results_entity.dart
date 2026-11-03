class ExaminationResult {
  final String examName;
  final String date;
  final double score;
  final double passingScore;

  /// Stable id of the Question Bank subject exam attempt this result came
  /// from; null for Mock Board results (see [mockBoardAttemptNo]).
  final String? attemptId;

  /// The Mock Board attempt number (`quiz_attempts.no_of_attempt`); reopens
  /// that attempt's results overview. Null for subject exams.
  final int? mockBoardAttemptNo;

  const ExaminationResult({
    required this.examName,
    required this.date,
    required this.score,
    required this.passingScore,
    this.attemptId,
    this.mockBoardAttemptNo,
  });

  bool get isMockBoard => mockBoardAttemptNo != null;

  /// A subject exam reopens its Exam Summary, a Mock Board its results.
  bool get canOpenSummary =>
      (attemptId != null && attemptId!.isNotEmpty) ||
      (mockBoardAttemptNo != null && mockBoardAttemptNo! > 0);
}
