import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_dynamic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubjectSequence(List<QuestionsEntity> subjects) {
    return ProviderScope(
      overrides: [getRandomQ.overrideWith((ref) async => subjects)],
      child: const MaterialApp(
        home: Scaffold(body: MockboardDynamicCard(label: 'Subject Sequence')),
      ),
    );
  }

  QuestionsEntity subject(String id, String title) {
    return QuestionsEntity(
      id: id,
      title: title,
      courseId: '1',
      description: '',
      image: '',
      day_subject: null,
      createdAt: '2026-06-06T00:00:00Z',
    );
  }

  testWidgets('renders generated subjects in order', (tester) async {
    await tester.pumpWidget(
      buildSubjectSequence([
        subject('1', 'Clinical Chemistry'),
        subject('2', 'Hematology'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subject Sequence'), findsOneWidget);
    expect(find.text('1. Clinical Chemistry'), findsOneWidget);
    expect(find.text('2. Hematology'), findsOneWidget);
  });

  testWidgets('shows an empty state when no generated subjects are cached', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubjectSequence([]));
    await tester.pumpAndSettle();

    expect(find.text('No subjects generated yet'), findsOneWidget);
  });
}
