import 'package:achievia/core/utils/mnemonic_filters.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:flutter_test/flutter_test.dart';

NotesEntity m(String title, {int? subject}) =>
    NotesEntity(image: '', title: title, subjectId: subject);

List<String> titles(List<NotesEntity> items) => [
  for (final item in items) item.title,
];

void main() {
  group('sortMnemonicsAlphabetically', () {
    test('is A-Z and ignores case', () {
      final sorted = sortMnemonicsAlphabetically([
        m('zebra'),
        m('Apple'),
        m('banana'),
        m('Cherry'),
        m('apricot'),
      ]);
      expect(titles(sorted), ['Apple', 'apricot', 'banana', 'Cherry', 'zebra']);
    });

    test(
      'keeps the original order of equal titles and ignores edge spaces',
      () {
        final a = m('Same', subject: 1);
        final b = m('same', subject: 2);
        final c = m('  Alpha');
        final sorted = sortMnemonicsAlphabetically([a, b, c]);
        expect(sorted.first, c);
        expect(sorted[1], a);
        expect(sorted[2], b);
      },
    );

    test('does not change the input list', () {
      final input = [m('b'), m('a')];
      sortMnemonicsAlphabetically(input);
      expect(titles(input), ['b', 'a']);
    });
  });

  group('filterMnemonics', () {
    final items = sortMnemonicsAlphabetically([
      m('Cranial nerves', subject: 1),
      m('Carpal bones', subject: 2),
      m('Anion gap', subject: 3),
      m('Coagulation cascade', subject: 3),
      m('Global mnemonic'),
    ]);

    test('All Subjects (empty selection) shows everything in order', () {
      final result = filterMnemonics(items: items, query: '', subjectIds: {});
      expect(titles(result), [
        'Anion gap',
        'Carpal bones',
        'Coagulation cascade',
        'Cranial nerves',
        'Global mnemonic',
      ]);
    });

    test('search alone matches the title, case-insensitively', () {
      final result = filterMnemonics(items: items, query: 'CA', subjectIds: {});
      expect(titles(result), ['Carpal bones', 'Coagulation cascade']);
    });

    test('a subject alone shows only its mnemonics, A-Z', () {
      final result = filterMnemonics(items: items, query: '', subjectIds: {3});
      expect(titles(result), ['Anion gap', 'Coagulation cascade']);
    });

    test('several subjects show mnemonics of any of them', () {
      final result = filterMnemonics(
        items: items,
        query: '',
        subjectIds: {1, 2},
      );
      expect(titles(result), ['Carpal bones', 'Cranial nerves']);
    });

    test('search and subjects apply together and keep the order', () {
      final result = filterMnemonics(
        items: items,
        query: 'c',
        subjectIds: {2, 3},
      );
      expect(titles(result), ['Carpal bones', 'Coagulation cascade']);
      expect(
        filterMnemonics(items: items, query: 'cranial', subjectIds: {3}),
        isEmpty,
      );
    });

    test('a mnemonic without a subject only shows under All Subjects', () {
      expect(
        titles(filterMnemonics(items: items, query: 'global', subjectIds: {})),
        ['Global mnemonic'],
      );
      expect(
        filterMnemonics(items: items, query: 'global', subjectIds: {1, 2, 3}),
        isEmpty,
      );
    });

    test('a query with only spaces behaves like no query', () {
      expect(
        filterMnemonics(items: items, query: '   ', subjectIds: {}),
        hasLength(5),
      );
    });
  });

  group('subjects', () {
    test('only subjects with mnemonics and a known name, sorted A-Z', () {
      final subjects = subjectsForMnemonics(
        mnemonics: [m('a', subject: 2), m('b', subject: 1), m('c', subject: 9)],
        titlesById: {1: 'hematology', 2: 'Clinical Chemistry', 5: 'Unused'},
      );
      expect(
        [for (final s in subjects) s.title],
        ['Clinical Chemistry', 'hematology'],
      );
    });

    test('selecting every subject, or none, means All Subjects', () {
      const available = [
        SupplementalSubject(id: 1, title: 'A'),
        SupplementalSubject(id: 2, title: 'B'),
      ];
      expect(normalizeSubjectSelection({1, 2}, available), isEmpty);
      expect(normalizeSubjectSelection({}, available), isEmpty);
      expect(normalizeSubjectSelection({1}, available), {1});
      // A subject that no longer exists is dropped.
      expect(normalizeSubjectSelection({1, 99}, available), {1});
      expect(normalizeSubjectSelection({99}, available), isEmpty);
    });
  });
}
