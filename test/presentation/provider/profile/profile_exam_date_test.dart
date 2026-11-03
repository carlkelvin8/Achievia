import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/presentation/provider/profile/profile_view_state.dart';
import 'package:flutter_test/flutter_test.dart';

ProfileEntity _profile({DateTime? exam}) =>
    ProfileEntity(firstName: 'QA', lastName: 'Tester', dateOfExamination: exam);

DateTime _inDays(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

void main() {
  group('profile exam date', () {
    test('the profile date wins over the copy kept on this device', () {
      final server = _inDays(30);
      final view = ProfileScreenViewData.fromEntity(
        _profile(exam: server),
        selectedBoardExamDate: _inDays(5),
      );
      expect(view.boardExamDate, server);
      expect(view.daysLeftLabel, '30 Days');
    });

    test('the device copy is only a fallback while the profile has none', () {
      final local = _inDays(10);
      final view = ProfileScreenViewData.fromEntity(
        _profile(),
        selectedBoardExamDate: local,
      );
      expect(view.boardExamDate, local);
      expect(view.daysLeftLabel, '10 Days');
    });

    test('no date anywhere is N/A, a past date is Exam Passed', () {
      final none = ProfileScreenViewData.fromEntity(_profile());
      expect(none.boardExamDateLabel, 'N/A');
      expect(none.daysLeftLabel, 'N/A');
      final past = ProfileScreenViewData.fromEntity(
        _profile(exam: _inDays(-3)),
      );
      expect(past.daysLeftLabel, 'Exam Passed');
    });

    test('a UTC timestamp counts days on the local calendar day', () {
      final view = ProfileScreenViewData.fromEntity(
        _profile(exam: _inDays(2).toUtc()),
      );
      expect(view.daysLeftLabel, '2 Days');
    });
  });
}
