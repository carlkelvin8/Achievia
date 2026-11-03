import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/network_image_with_fallback.dart';
import 'package:flutter/material.dart';

/// The Achievia professional ID card.
///
/// Drawn on a fixed design canvas ([_designWidth] x [_designHeight], the
/// ID-1 card ratio) and scaled uniformly to the available width, so every
/// field keeps its place and proportions on any screen and nothing can
/// overlap or run past the card edges. Long values end with an ellipsis.
class ProfileStatusCard extends StatelessWidget {
  /// Purpose printed on every ID. Fixed on purpose, it is not user-editable.
  static const String fixedPurpose = 'MTLE';

  static const double _designWidth = 340;
  static const double _designHeight = 214;

  /// Width / height of the card.
  static const double aspectRatio = _designWidth / _designHeight;

  static const _navy = Color(0xFF0B1F5C);
  static const _cyan = Color(0xFF0098C7);
  static const _green = Color(0xFF0F5A1E);

  final String lastName;
  final String firstName;
  final String middleName;
  final String university;
  final String dateOfExam;
  final String profileImageUrl;

  /// Leaderboard position, shown right under the photo; null shows none.
  final int? rank;

  /// Shown after the rank, e.g. the study time.
  final String? rankDetail;

  const ProfileStatusCard({
    super.key,
    this.lastName = 'N/A',
    this.firstName = 'N/A',
    this.middleName = 'N/A',
    this.university = 'N/A',
    this.dateOfExam = 'N/A',
    this.profileImageUrl = '',
    this.rank,
    this.rankDetail,
  });

  Widget _detailRow(String label, String value) {
    const labelStyle = TextStyle(
      fontSize: 7.5,
      fontWeight: FontWeight.w700,
      color: _navy,
      letterSpacing: 0.2,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, maxLines: 1, style: labelStyle),
          ),
          const Text(':  ', style: labelStyle),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: _designWidth,
      height: _designHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F9FE), Color(0xFFDCEBF8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background art: corner stripes and the large Achievia mark.
          const Positioned.fill(child: CustomPaint(painter: _IdArtPainter())),
          Column(
            children: [
              // Header: logo, issuer lines, logo.
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 8, 36, 0),
                child: Row(
                  children: [
                    const InlineStyleSvg(
                      assetPath: logo,
                      width: 46,
                      height: 46,
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Republic of the Philippines',
                            maxLines: 1,
                            style: TextStyle(fontSize: 6.5, color: _navy),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'ACHIEVIA REVIEW',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _cyan,
                              letterSpacing: 2.2,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'PROFESSIONAL IDENTIFICATION CARD',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 6.8,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      idCardLogo,
                      key: const ValueKey('id-card-logo-right'),
                      width: 46,
                      height: 46,
                      filterQuality: FilterQuality.medium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: _cyan.withValues(alpha: 0.5),
              ),
              // Body: photo and details, centred between the divider and the
              // green bar so the space above and below is equal. The faint
              // Achievia mark is centred in the same area.
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Opacity(
                            opacity: 0.22,
                            child: InlineStyleSvg(
                              assetPath: selectedAnswerIcon,
                              width: 112,
                              height: 112,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // The photo on its own, no frame; the slot
                              // keeps the details column where it was.
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 82,
                                    height: 92,
                                    child: Center(
                                      child: NetworkImageWithFallback(
                                        imageUrl: profileImageUrl,
                                        width: 77,
                                        height: 87,
                                        fit: BoxFit.cover,
                                        fallbackIcon: Icons.person,
                                        fallbackIconSize: 40,
                                      ),
                                    ),
                                  ),
                                  if (rank != null) ...[
                                    const SizedBox(height: 2),
                                    _RankBadge(rank: rank!, detail: rankDetail),
                                  ],
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _detailRow('LAST NAME', lastName),
                                    _detailRow('FIRST NAME', firstName),
                                    _detailRow('MIDDLE NAME', middleName),
                                    _detailRow('UNIVERSITY', university),
                                    _detailRow('PURPOSE', fixedPurpose),
                                    _detailRow('DATE OF EXAM', dateOfExam),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Profession bar and motto.
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: _green,
                child: const Text(
                  'MEDICAL TECHNOLOGIST',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 6),
                child: Text(
                  'AWAKEN ACADEMIC AMBITION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AspectRatio(
      aspectRatio: _designWidth / _designHeight,
      child: FittedBox(fit: BoxFit.contain, child: card),
    );
  }
}

/// "#3": the leaderboard position under the photo, as wide as the photo.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, this.detail});

  final int rank;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('id-card-rank-$rank'),
      width: 77,
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: ProfileStatusCard._navy,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        detail == null ? '#$rank' : '#$rank · $detail',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// The diagonal blue stripes in the top-left corner and the faint lines
/// across the card, as on the reference ID.
class _IdArtPainter extends CustomPainter {
  const _IdArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Path band(double from, double width) => Path()
      ..moveTo(from, 0)
      ..lineTo(from + width, 0)
      ..lineTo(0, from + width)
      ..lineTo(0, from)
      ..close();

    // Kept clear of the header logo (x + y <= 44 at the stripe edge).
    canvas.drawPath(band(0, 24), Paint()..color = const Color(0xFF1E4FA8));
    canvas.drawPath(band(28, 8), Paint()..color = const Color(0xFF4FB3E8));
    canvas.drawPath(band(40, 4), Paint()..color = const Color(0xFF9AD3F2));

    final lines = Paint()
      ..color = const Color(0xFF0098C7).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        lines,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
