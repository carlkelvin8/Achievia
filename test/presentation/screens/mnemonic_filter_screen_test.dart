import 'package:achievia/core/di/injection.dart';
import 'package:achievia/data/data_source/reviewer/supplemental_remote_datasource.dart';
import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:achievia/data/repositoryImpl/reviewer/supplemental_repository_impl.dart';
import 'package:achievia/domain/use_cases/reviewer/supplemental_use_case.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/supplementals_content_screen.dart';
import 'package:achievia/presentation/widgets/supplementals/mnemonic_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SupplementalItemDto mnemonic(int id, String title, {int? subject}) =>
    SupplementalItemDto(
      id: id,
      courseId: subject,
      kind: 'mnemonic',
      title: title,
      content: 'Content of $title',
      imageUrl: null,
      fileUrl: null,
      subjectId: subject,
    );

class FakeSupplementalDatasource extends SupplementalRemoteDatasource {
  FakeSupplementalDatasource(
    this.items,
    this.subjects, {
    this.subjectsFail = false,
  });

  final List<SupplementalItemDto> items;
  final Map<int, String> subjects;
  final bool subjectsFail;

  @override
  Future<List<SupplementalItemDto>> getItems({int? courseId}) async => items;

  @override
  Future<Map<int, String>> getSubjectTitles(Iterable<int> subjectIds) async {
    if (subjectsFail) throw Exception('subjects unavailable');
    return {
      for (final id in subjectIds)
        if (subjects.containsKey(id)) id: subjects[id]!,
    };
  }
}

void register(FakeSupplementalDatasource datasource) {
  if (sl.isRegistered<SupplementalUseCase>()) {
    sl.unregister<SupplementalUseCase>();
  }
  sl.registerSingleton<SupplementalUseCase>(
    SupplementalUseCase(SupplementalRepositoryImpl(datasource)),
  );
}

final _items = [
  mnemonic(1, 'Cranial nerves', subject: 10),
  mnemonic(2, 'carpal bones', subject: 20),
  mnemonic(3, 'Anion gap', subject: 30),
  mnemonic(4, 'Coagulation cascade', subject: 30),
  mnemonic(5, 'Beta blockers'),
  // Not mnemonics: must not appear in the grid and keep their behaviour.
  SupplementalItemDto(
    id: 6,
    courseId: null,
    kind: 'abbreviation',
    title: 'SOB',
    content: 'Shortness of breath',
    imageUrl: null,
    fileUrl: null,
  ),
];

const _subjectNames = {
  10: 'Anatomy',
  20: 'Anatomy and Physiology',
  30: 'Clinical Chemistry',
};

Future<void> pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: SupplementalsContentScreen())),
  );
  await tester.pumpAndSettle();
  // Show the full mnemonic list (the All view only previews four).
  await tester.tap(find.text('Mnemonics').first);
  await tester.pumpAndSettle();
}

List<String> shownTitles(WidgetTester tester) {
  final grid = find.byType(MnemonicGrid);
  if (grid.evaluate().isEmpty) return const [];
  final texts = tester.widgetList<Text>(
    find.descendant(of: grid, matching: find.byType(Text)),
  );
  return [for (final t in texts) t.data ?? ''];
}

Future<void> openFilter(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('subject-filter-button')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => register(FakeSupplementalDatasource(_items, _subjectNames)));

  testWidgets('mnemonics are A-Z, case-insensitive, without icons', (
    tester,
  ) async {
    await pump(tester);
    expect(shownTitles(tester), [
      'Anion gap',
      'Beta blockers',
      'carpal bones',
      'Coagulation cascade',
      'Cranial nerves',
    ]);
    // The tiles carry no icon any more.
    expect(
      find.descendant(
        of: find.byType(MnemonicGrid),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    // And remain tappable.
    await tester.tap(find.text('Anion gap'));
    await tester.pumpAndSettle();
    expect(find.text('Content of Anion gap'), findsOneWidget);
  });

  testWidgets('the dialog lists the real subjects and All Subjects', (
    tester,
  ) async {
    await pump(tester);
    await openFilter(tester);
    expect(find.text('Filter by Subject'), findsOneWidget);
    expect(find.text('All Subjects'), findsOneWidget);
    expect(find.text('Anatomy'), findsOneWidget);
    expect(find.text('Anatomy and Physiology'), findsOneWidget);
    expect(find.text('Clinical Chemistry'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Apply Filter'), findsOneWidget);
    // All Subjects is the default.
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('subject-filter-all')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('one subject, then several subjects', (tester) async {
    await pump(tester);
    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-30')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Anion gap', 'Coagulation cascade']);

    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-20')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), [
      'Anion gap',
      'carpal bones',
      'Coagulation cascade',
    ]);
  });

  testWidgets('search and subject filter work together', (tester) async {
    await pump(tester);
    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-30')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'co');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Coagulation cascade']);

    // Clearing the search keeps the subject filter.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Anion gap', 'Coagulation cascade']);
  });

  testWidgets('Clear and All Subjects reset the selection', (tester) async {
    await pump(tester);
    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-10')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), ['Cranial nerves']);

    // The dialog reopens with the applied selection; Clear resets it.
    await openFilter(tester);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('subject-filter-10')),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('subject-filter-clear')));
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('subject-filter-all')),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(5));
  });

  testWidgets('no match shows an empty state and keeps the controls', (
    tester,
  ) async {
    await pump(tester);
    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-10')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mnemonic-empty')), findsOneWidget);
    expect(
      find.textContaining('No mnemonics match your search'),
      findsOneWidget,
    );
    // Search field and filter button are still there.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-filter-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mnemonic-empty-clear-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mnemonic-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mnemonic-empty-clear-search')));
    await tester.pumpAndSettle();
    expect(shownTitles(tester), hasLength(5));
  });

  testWidgets('without subject names the filter is hidden, lists still work', (
    tester,
  ) async {
    register(
      FakeSupplementalDatasource(_items, _subjectNames, subjectsFail: true),
    );
    await pump(tester);
    expect(find.byKey(const ValueKey('subject-filter-button')), findsNothing);
    expect(shownTitles(tester), hasLength(5));
  });

  testWidgets('the subject filter also applies to abbreviations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SupplementalsContentScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await openFilter(tester);
    await tester.tap(find.byKey(const ValueKey('subject-filter-10')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('subject-filter-apply')));
    await tester.pumpAndSettle();
    // The abbreviation has no subject, so a subject filter hides it; it
    // returns with All Subjects.
    expect(find.text('Shortness of breath'), findsNothing);
    expect(find.byKey(const ValueKey('abbreviation-empty')), findsOneWidget);
  });
}
