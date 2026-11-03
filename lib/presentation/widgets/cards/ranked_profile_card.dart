import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card_mock.dart';
import 'package:flutter/material.dart';

/// A leaderboard entry: the student's whole ID card, never cropped, with
/// their rank right under the profile picture.
class RankedProfileCard extends StatelessWidget {
  static const double defaultWidth = 260;

  /// The height that shows a [defaultWidth] card in full.
  static const double defaultHeight =
      defaultWidth / ProfileStatusCard.aspectRatio;

  final int rank;
  final Widget? customCard;
  final double? width;
  final UserEntity? mockProfile;

  /// Shown after the rank, e.g. the study time ("#1 · 12h 05m").
  final String? rankDetail;

  const RankedProfileCard({
    super.key,
    required this.rank,
    this.customCard,
    this.width,
    this.mockProfile,
    this.rankDetail,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? defaultWidth;
    return SizedBox(
      width: cardWidth,
      height: cardWidth / ProfileStatusCard.aspectRatio,
      child:
          customCard ??
          (mockProfile != null
              ? ProfileStatusCardMock(
                  profile: mockProfile!,
                  rank: rank,
                  rankDetail: rankDetail,
                )
              : ProfileStatusCard(rank: rank, rankDetail: rankDetail)),
    );
  }
}
