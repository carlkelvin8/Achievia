import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BuildBanner extends StatelessWidget {
  const BuildBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(9),
        ),
          child: Text(
          'Medical Technology Dashboard',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class MotivationQuoteBanner extends StatelessWidget {
  const MotivationQuoteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                'assets/Motivation Background.svg',
                fit: BoxFit.fill,
              ),
              Align(
                alignment: const Alignment(0, 0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'You did not come this far to only come this far. Every late night, every sacrificed moment — they are all shaping your victory. Keep going.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0C1E62),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}