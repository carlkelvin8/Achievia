import 'package:achievia/core/utils/mnemonic_filters.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/abbreviation_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MedicalAbbreviation a(String short, String full, {int? subject}) =>
    MedicalAbbreviation(
      abbreviation: short,
      expansion: full,
      subjectId: subject,
    );

void main() {
  final items = [
    a('Zn', 'Zinc', subject: 1),
    a('WBC', 'White blood cell', subject: 2),
    a('B2M', '<em>beta</em>-2 macroglobulin', subject: 2),
    a('YP', '<em>Yersinia pestis</em>', subject: 3),
    a('x', 'albumin', subject: null),
  ];

  test('sorted A-Z by the text students read, ignoring case and tags', () {
    final sorted = sortAbbreviationsAlphabetically(items);
    expect(sorted.map((e) => e.abbreviation).toList(), [
      'x', // albumin
      'B2M', // beta-2 macroglobulin
      'WBC', // White blood cell
      'YP', // Yersinia pestis
      'Zn', // Zinc
    ]);
  });

  test('sorting is stable for equal text', () {
    final sorted = sortAbbreviationsAlphabetically([
      a('B', 'same'),
      a('A', 'same'),
    ]);
    expect(sorted.map((e) => e.abbreviation).toList(), ['A', 'B']);
  });

  test('subject filter: empty set is All Subjects, otherwise any selected', () {
    expect(
      filterAbbreviations(items: items, query: '', subjectIds: const {}),
      hasLength(5),
    );
    final two = filterAbbreviations(
      items: items,
      query: '',
      subjectIds: const {2},
    );
    expect(two.map((e) => e.abbreviation).toSet(), {'WBC', 'B2M'});
    final several = filterAbbreviations(
      items: items,
      query: '',
      subjectIds: const {1, 3},
    );
    expect(several.map((e) => e.abbreviation).toSet(), {'Zn', 'YP'});
    // An abbreviation with no subject only shows under All Subjects.
    expect(two.any((e) => e.subjectId == null), isFalse);
  });

  test('search works with the subject filter and ignores tags', () {
    final r = filterAbbreviations(
      items: items,
      query: 'yersinia',
      subjectIds: const {3},
    );
    expect(r.single.abbreviation, 'YP');
    expect(
      filterAbbreviations(items: items, query: 'em>', subjectIds: const {}),
      isEmpty,
    );
  });

  testWidgets('every row ends with one simple right arrow, no save/heart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AbbreviationList(items: items)),
      ),
    );
    expect(
      find.byKey(const ValueKey('abbreviation-chevron')),
      findsNWidgets(5),
    );
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });
}
