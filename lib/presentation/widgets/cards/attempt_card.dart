// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/achievia_grading.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mock Boards result card: subject scores, average, remarks and an
/// interpretation that follows the Achievia grading bracket of the average.
///
/// The card takes the full width it is given (the screen adds equal side
/// padding) and is only as tall as its content, so the Average row follows
/// the last subject directly.
class AttemptCard extends ConsumerWidget {
  final int attemptId;
  const AttemptCard({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(getResultsProviderState(attemptId));
    return Container(
      key: const ValueKey('attempt-card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 17, 44, 131),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const InlineStyleSvg(
                key: ValueKey('attempt-results-logo'),
                assetPath: logo,
                width: 36,
                height: 36,
                semanticsLabel: 'Achievia',
              ),
              const SizedBox(width: 10),
              Text(
                'RESULTS',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          watch.when(
            data: (q) {
              if (q == null) {
                return const _Panel(
                  child: Center(child: Text('No results available')),
                );
              }
              final data = q.score.answers;
              final passed = q.score.passed;
              final bracket = bracketForPercentage(
                double.tryParse(q.score.score) ?? 0,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Interpretation(
                    level: bracket.level,
                    message: bracket.message,
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    child: Column(
                      children: [
                        for (var index = 0; index < data.length; index++) ...[
                          if (index > 0) const SizedBox(height: 8),
                          DataCard(
                            dataNum: double.parse(
                              data[index].score.toStringAsFixed(1),
                            ).round().toString(),
                            subject: data[index].name,
                            scores: q.score.score,
                          ),
                        ],
                        const SizedBox(height: 16),
                        DataCard(
                          dataNum: q.score.score,
                          subject: 'Average',
                          scores: q.score.score,
                        ),
                        const SizedBox(height: 8),
                        DataCard(
                          dataNum: passed ? 'Pass' : 'Failed',
                          subject: 'Remarks',
                          scores: q.score.score,
                          textColor: passed ? Colors.black : Colors.white,
                          color: passed ? Colors.green : Colors.red,
                        ),
                        if (q.score.reasons.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              q.score.reasons.join('\n'),
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            error: (_, __) => _Panel(
              child: Text(
                'We could not load your results. Please check your '
                'connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ReusableButton(
              title: 'Summary',
              // This attempt's own answers, also when revisited later.
              onPressed: () {
                context.push(RouteConstants.summaryScreen, extra: attemptId);
              },
              width: 150,
              height: 40,
              backgroundColor: Colors.white,
              textColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bracket's level and its own message for the student's average.
class _Interpretation extends StatelessWidget {
  final String level;
  final String message;

  const _Interpretation({required this.level, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('attempt-interpretation'),
      children: [
        Text(
          level,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: LightColors.secondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}
