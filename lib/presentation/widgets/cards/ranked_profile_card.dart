import 'package:flutter/material.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';

/// A wrapper widget that displays a ProfileStatusCard with a rank badge
/// Useful for leaderboards and ranked lists
class RankedProfileCard extends StatelessWidget {
  final int rank;
  final Widget? customCard;
  final double? width;
  final double? height;

  const RankedProfileCard({
    super.key,
    required this.rank,
    this.customCard,
    this.width,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width ?? 260,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: customCard ??
                    FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 360,
                        child: const ProfileStatusCard(),
                      ),
                    ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#$rank',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
