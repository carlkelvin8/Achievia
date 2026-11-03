import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/presentation/widgets/cards/examination_results_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExaminationResult resultWith({required double score, double passing = 75}) =>
      ExaminationResult(
        examName: 'Clinical Chemistry',
        date: 'Aug 14, 2026',
        score: score,
        passingScore: passing,
      );

  Widget wrap(List<ExaminationResult> results) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExaminationResultsCard(
            title: 'Examination Results',
            results: results,
          ),
        ),
      ),
    );
  }

  testWidgets('marks PASSED exactly at the passing boundary', (tester) async {
    await tester.pumpWidget(wrap([resultWith(score: 75)]));

    expect(find.text('PASSED'), findsOneWidget);
    expect(find.text('FAILED'), findsNothing);
  });

  testWidgets('marks FAILED just below the passing boundary', (tester) async {
    await tester.pumpWidget(wrap([resultWith(score: 74.999)]));

    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('PASSED'), findsNothing);
  });

  testWidgets('respects each result own passing score', (tester) async {
    await tester.pumpWidget(
      wrap([
        resultWith(score: 75, passing: 80),
        resultWith(score: 80, passing: 80),
      ]),
    );

    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('PASSED'), findsOneWidget);
  });
}
