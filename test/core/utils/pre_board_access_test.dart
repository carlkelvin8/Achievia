import 'package:achievia/core/utils/pre_board_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final exam = DateTime.utc(2026, 11, 20);

  PreBoardStatus status({
    DateTime? examDate,
    bool used = false,
    DateTime? now,
  }) {
    return PreBoardStatus(
      examDate: examDate,
      used: used,
      serverNow: now ?? DateTime.utc(2026, 11, 10),
    );
  }

  test('no exam date keeps Pre Boards locked', () {
    expect(status().access, PreBoardAccess.noExamDate);
  });

  test('more than 14 days before the exam is not open yet', () {
    final s = status(examDate: exam, now: DateTime.utc(2026, 11, 5, 23));
    expect(s.access, PreBoardAccess.notYet);
    expect(s.lockedMessage, contains('November 6, 2026'));
  });

  test('opens exactly 14 days before the exam', () {
    final s = status(examDate: exam, now: DateTime.utc(2026, 11, 6));
    expect(s.access, PreBoardAccess.available);
  });

  test('stays open through the exam day, closes after', () {
    expect(
      status(examDate: exam, now: DateTime.utc(2026, 11, 20, 23)).access,
      PreBoardAccess.available,
    );
    expect(
      status(examDate: exam, now: DateTime.utc(2026, 11, 21)).access,
      PreBoardAccess.passed,
    );
  });

  test('a used attempt is never available again', () {
    expect(
      status(examDate: exam, used: true).access,
      PreBoardAccess.alreadyTaken,
    );
  });

  test('parses the server row', () {
    final s = PreBoardStatus.fromJson({
      'exam_date': '2026-11-20T00:00:00+00:00',
      'used': false,
      'server_now': '2026-11-10T00:00:00+00:00',
    });
    expect(s.access, PreBoardAccess.available);
  });
}
