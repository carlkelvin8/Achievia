import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_dynamic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubjectSequence(List<QuizItemEntity> subjects) {
    return ProviderScope(
      overrides: [getGeneratedQuestions.overrideWith((ref) async => subjects)],
      child: const MaterialApp(
        home: Scaffold(body: MockboardDynamicCard(label: 'Subject Sequence')),
      ),
    );
  }

  QuizItemEntity subject(int id, String title) {
    return QuizItemEntity(
      id: id,
      title: title,
      description: '',
      createdAt: '2026-06-06T00:00:00Z',
      subjectId: id,
      questions: const [],
    );
  }

  testWidgets('renders generated subjects in order', (tester) async {
    await tester.pumpWidget(
      buildSubjectSequence([
        subject(1, 'Clinical Chemistry'),
        subject(2, 'Microbiology and Parasitology'),
        subject(3, 'Clinical Microscopy'),
        subject(4, 'Hematology'),
        subject(5, 'Blood Banking and Serology'),
        subject(6, 'Histopathology and Medical Technology Laws/Ethics'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subject Sequence'), findsOneWidget);
    expect(find.text('1. Clinical Chemistry'), findsOneWidget);
    expect(find.text('2. Microbiology and Parasitology'), findsOneWidget);
    expect(find.text('4. Hematology'), findsOneWidget);
    expect(find.text('5. Blood Banking and Serology'), findsOneWidget);
    expect(
      find.text('6. Histopathology and Medical Technology Laws/Ethics'),
      findsOneWidget,
    );
    expect(find.textContaining('2. Parasitology'), findsNothing);
  });

  testWidgets('shows an empty state when no generated subjects are cached', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubjectSequence([]));
    await tester.pumpAndSettle();

    expect(find.text('No subjects generated yet'), findsOneWidget);
  });
}
