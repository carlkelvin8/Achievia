import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:intl/intl.dart';

class ProfileCardViewData {
  final String lastName;
  final String firstName;
  final String middleName;
  final String university;
  final String purpose;
  final String dateOfExam;
  final String profileImageUrl;

  const ProfileCardViewData({
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.university,
    required this.purpose,
    required this.dateOfExam,
    required this.profileImageUrl,
  });
}

class ProfileScreenViewData {
  final ProfileCardViewData card;
  final DateTime? boardExamDate;
  final String boardExamDateLabel;
  final String daysLeftLabel;

  const ProfileScreenViewData({
    required this.card,
    required this.boardExamDate,
    required this.boardExamDateLabel,
    required this.daysLeftLabel,
  });

  static ProfileScreenViewData fromEntity(
    ProfileEntity profile, {
    DateTime? selectedBoardExamDate,
  }) {
    final examDate = selectedBoardExamDate ?? profile.dateOfExamination;

    return ProfileScreenViewData(
      card: ProfileCardViewData(
        lastName: _safeUpper(profile.lastName),
        firstName: _safeUpper(profile.firstName),
        middleName: _safeUpper(profile.middleName),
        university: _safeUpper(profile.university),
        purpose: _safeUpper(profile.purpose),
        dateOfExam: _formatExamDateForCard(examDate),
        profileImageUrl: profile.profileImage ?? '',
      ),
      boardExamDate: examDate,
      boardExamDateLabel: _formatExamDateForBadge(examDate),
      daysLeftLabel: _calculateDaysLeft(examDate),
    );
  }

  static String _safeUpper(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'N/A';
    }
    return value.trim().toUpperCase();
  }

  static String _formatExamDateForCard(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMMM yyyy').format(date.toLocal()).toUpperCase();
  }

  static String _formatExamDateForBadge(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMMM d, yyyy').format(date.toLocal());
  }

  static String _calculateDaysLeft(DateTime? examDate) {
    if (examDate == null) return 'N/A';

    final now = DateTime.now();
    final days = examDate.difference(now).inDays;

    if (days < 0) return 'Exam Passed';
    if (days == 0) return 'Today';
    if (days == 1) return '1 Day';
    return '$days Days';
  }
}
