// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AttemptCard extends ConsumerWidget {
  final int attemptId;
  const AttemptCard({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(getResultsProviderState(attemptId));
    print('id:$attemptId');
    print(watch);
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 17, 44, 131),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(logo, height: 40),
              const SizedBox(width: 8),
              Text(
                'RESULTS',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              "Nice one, Achievian! You're getting better and better",
              style: GoogleFonts.poppins(
                color: LightColors.secondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: watch.when(
              data: (q) {
                if (q == null) {
                  return const Center(child: Text('No results available'));
                }
                final data = q.score.answers;
                final passed = q.score.passed;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            int value = double.parse(
                              data[index].score.toStringAsFixed(1),
                            ).round();
                            return DataCard(
                              dataNum: value.toString(),
                              subject: data[index].name,
                              scores: q.score.score,
                            );
                          },
                        ),
                      ),
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
                );
              },
              error: (_, __) => const Center(child: Text('Error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: ReusableButton(
              title: 'Summary',
              onPressed: () {
                Navigator.pushNamed(context, '/summary-screen');
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
