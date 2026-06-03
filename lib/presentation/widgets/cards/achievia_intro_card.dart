import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' as services;

/// Achievia branding introduction card with logo and description
class AchieviaIntroCard extends StatelessWidget {
  const AchieviaIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _InlineStyleSvg(
                assetPath: 'assets/images/LOGO/1.svg',
                width: 100,
                height: 100,
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Achie',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: 'via',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AWAKEN ACADEMIC AMBITION',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Achievia is a modern review platform designed to help students study smarter and excel in board exams through a convenient, innovative, and effective approach. Achievia offers curated materials and tools tailored to meet the needs of future board passers. With a growing community of dedicated users called Achievians, the platform continues to redefine how students prepare — with focus, flexibility, and results.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStyleSvg extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;

  const _InlineStyleSvg({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: services.rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: width, height: height);
        }

        return SvgPicture.string(
          _inlineSimpleFillStyles(snapshot.data!),
          width: width,
          height: height,
          fit: BoxFit.contain,
        );
      },
    );
  }

  String _inlineSimpleFillStyles(String svgString) {
    final styleReg = RegExp(
      r'<style[^>]*>([\s\S]*?)<\/style>',
      caseSensitive: false,
    );
    final styleMatch = styleReg.firstMatch(svgString);
    if (styleMatch == null) return svgString;

    final styleBody = styleMatch.group(1)!;
    final classReg = RegExp(
      r'\.([\w-]+)\s*\{[^}]*fill:\s*([^;\s}]+)[^}]*\}',
      caseSensitive: false,
    );

    var normalizedSvg = svgString;
    for (final match in classReg.allMatches(styleBody)) {
      final className = match.group(1)!;
      final fill = match.group(2)!;
      normalizedSvg = normalizedSvg.replaceAll(
        RegExp('class="$className"'),
        'fill="$fill"',
      );
      normalizedSvg = normalizedSvg.replaceAll(
        RegExp("class='$className'"),
        "fill='$fill'",
      );
    }

    return normalizedSvg.replaceFirst(styleReg, '');
  }
}
