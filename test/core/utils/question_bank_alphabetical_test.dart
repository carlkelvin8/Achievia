import 'package:achievia/core/utils/alphabetical.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareTitlesAlphabetically', () {
    test('ignores case and surrounding spaces', () {
      final titles = ['virology', 'Bacteriology', '  Anatomy', 'cestodes']
        ..sort(compareTitlesAlphabetically);
      expect(titles, ['  Anatomy', 'Bacteriology', 'cestodes', 'virology']);
    });

    test('equal titles use the tie-breaker so the order is stable', () {
      expect(
        compareTitlesAlphabetically('Same', 'Same', tieBreakA: 2, tieBreakB: 1),
        greaterThan(0),
      );
      expect(
        compareTitlesAlphabetically('Same', 'Same', tieBreakA: 1, tieBreakB: 2),
        lessThan(0),
      );
    });
  });

  group('Question Bank lists', () {
    test('subjects are A-Z even when the database returns Z-A', () {
      final rows = [
        for (final t in [
          'Virology',
          'Parasitology',
          'Mycology',
          'Molecular Biology',
          'Medtech Laws and Ethics',
          'Immunology and Serology',
          'Immunohematology',
          'hematology',
          'Clinical Chemistry',
          'Bacteriology',
        ])
          {'id': t.length, 'title': t, 'course_id': 1},
      ];
      final titles = [for (final s in subjectsFromRows(rows)) s.title];
      expect(titles, [
        'Bacteriology',
        'Clinical Chemistry',
        'hematology',
        'Immunohematology',
        'Immunology and Serology',
        'Medtech Laws and Ethics',
        'Molecular Biology',
        'Mycology',
        'Parasitology',
        'Virology',
      ]);
    });

    test(
      'subtopics are A-Z, case-insensitive, duplicates kept in id order',
      () {
        final rows = [
          {'id': 5, 'subject_id': 26, 'title': 'Trematodes'},
          {
            'id': 9,
            'subject_id': 26,
            'title': 'Parasitology Picture-Based Questions',
          },
          {
            'id': 4,
            'subject_id': 26,
            'title': 'Parasitology Picture-Based Questions',
          },
          {'id': 7, 'subject_id': 26, 'title': 'nematodes'},
          {'id': 3, 'subject_id': 26, 'title': 'Cestodes'},
          {'id': 8, 'subject_id': 99, 'title': 'Another subject'},
          {'id': 2, 'subject_id': 26, 'title': 'Filariae'},
        ];
        final topics = topicsFromRows(rows, 26);
        expect(
          [for (final t in topics) t.title],
          [
            'Cestodes',
            'Filariae',
            'nematodes',
            'Parasitology Picture-Based Questions',
            'Parasitology Picture-Based Questions',
            'Trematodes',
          ],
        );
        // Same title: lower id first, every load.
        expect(topics[3].id, 4);
        expect(topics[4].id, 9);
      },
    );
  });
}
