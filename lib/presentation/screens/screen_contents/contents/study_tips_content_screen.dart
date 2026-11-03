import 'package:achievia/core/constants/study_tips.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// About > Study Tips: the banner, the 15 numbered tips and a closing
/// reminder.
class StudyTipsContentScreen extends StatelessWidget {
  const StudyTipsContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        key: const ValueKey('study-tips-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _Banner(),
          const SizedBox(height: 24),
          for (var i = 0; i < studyTips.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _TipCard(number: i + 1, tip: studyTips[i]),
          ],
          const SizedBox(height: 24),
          const _Reminder(),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        // The banner's own shape (1200 x 450), so nothing is cropped.
        aspectRatio: 1200 / 450,
        child: Image.asset(
          studyTipsBanner,
          key: const ValueKey('study-tips-banner'),
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => const _BannerPlaceholder(),
        ),
      ),
    );
  }
}

/// Shown if the banner image cannot be loaded.
class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('study-tips-banner-placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F5C), Color(0xFF1565C0), Color(0xFF0098C7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Be Our First Batch of',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'TOPNOTCHERS',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final int number;
  final StudyTip tip;

  const _TipCard({required this.number, required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      key: ValueKey('study-tip-$number'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            height: 26,
            child: Center(
              child: tip.iconText != null
                  ? Text(
                      tip.iconText!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    )
                  : Icon(tip.icon, size: 24, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Reminder extends StatelessWidget {
  const _Reminder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      key: const ValueKey('study-tips-reminder'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events, color: primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Important Reminder: ',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const TextSpan(text: studyTipsReminder),
                ],
              ),
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
