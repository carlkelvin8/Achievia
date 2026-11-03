import 'package:intl/intl.dart';

/// Pre Boards open this many days before the student's board exam date.
const int preBoardUnlockDays = 14;

enum PreBoardAccess { available, noExamDate, notYet, passed, alreadyTaken }

/// What the server says about a student's Pre Boards (`get_pre_board_status`).
/// [serverNow] is the database clock, so the phone's clock cannot unlock it.
class PreBoardStatus {
  const PreBoardStatus({
    required this.examDate,
    required this.used,
    required this.serverNow,
  });

  final DateTime? examDate;
  final bool used;
  final DateTime serverNow;

  factory PreBoardStatus.fromJson(Map<String, dynamic> json) {
    final exam = json['exam_date'] as String?;
    final now = json['server_now'] as String?;
    return PreBoardStatus(
      examDate: exam == null ? null : DateTime.parse(exam),
      used: json['used'] == true,
      serverNow: now == null ? DateTime.now() : DateTime.parse(now),
    );
  }

  DateTime? get unlocksAt =>
      examDate?.subtract(const Duration(days: preBoardUnlockDays));

  /// Same rule as `claim_pre_board_attempt`: open from [unlocksAt] until the
  /// end of the exam day, and only once.
  PreBoardAccess get access {
    final exam = examDate;
    if (used) return PreBoardAccess.alreadyTaken;
    if (exam == null) return PreBoardAccess.noExamDate;
    if (serverNow.isBefore(unlocksAt!)) return PreBoardAccess.notYet;
    if (!serverNow.isBefore(exam.add(const Duration(days: 1)))) {
      return PreBoardAccess.passed;
    }
    return PreBoardAccess.available;
  }

  /// Why Pre Boards cannot be opened; empty when [access] is available.
  String get lockedMessage => switch (access) {
    PreBoardAccess.available => '',
    PreBoardAccess.alreadyTaken => 'You have already taken your Pre Boards.',
    PreBoardAccess.noExamDate =>
      'Set your board exam date in your profile to unlock Pre Boards.',
    PreBoardAccess.notYet =>
      'Pre Boards unlock on '
          '${DateFormat('MMMM d, yyyy').format(unlocksAt!.toLocal())}, '
          'two weeks before your board exam.',
    PreBoardAccess.passed =>
      'Your board exam date has passed, so Pre Boards are closed.',
  };
}
