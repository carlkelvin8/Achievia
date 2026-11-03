import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Homepage Daily Motivation. Keeps the banner frame while loading (no layout
/// jump) and collapses when there is nothing to show.
class MotivationQuoteBanner extends ConsumerWidget {
  const MotivationQuoteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivation = ref.watch(dailyMotivationProvider);
    if (motivation.isLoading && !motivation.hasValue) {
      return const MotivationQuoteCard(message: '');
    }
    final message = motivation.value?.message ?? '';
    if (message.isEmpty) return const SizedBox.shrink();
    return MotivationQuoteCard(message: message);
  }
}

class MotivationQuoteCard extends StatelessWidget {
  const MotivationQuoteCard({super.key, required this.message});

  final String message;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  // Scales down instead of overflowing for long messages or
                  // large system text sizes.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (MediaQuery.sizeOf(context).width - 84).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: Text(
                        message,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
