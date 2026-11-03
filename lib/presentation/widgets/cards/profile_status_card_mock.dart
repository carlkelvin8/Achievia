import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:flutter/material.dart';

/// A version of ProfileStatusCard that accepts mock data directly
/// Used for displaying top achievians without API calls
class ProfileStatusCardMock extends StatelessWidget {
  final UserEntity profile;

  /// Leaderboard position shown under the photo.
  final int? rank;
  final String? rankDetail;

  const ProfileStatusCardMock({
    super.key,
    required this.profile,
    this.rank,
    this.rankDetail,
  });

  String _formatExamDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _upper(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? 'N/A' : text.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStatusCard(
      lastName: _upper(profile.lastName),
      firstName: _upper(profile.firstName),
      middleName: _upper(profile.middleName),
      university: _upper(profile.university),
      dateOfExam: _formatExamDate(profile.dateOfExamination),
      profileImageUrl: profile.profileImage ?? '',
      rank: rank,
      rankDetail: rankDetail,
    );
  }
}
