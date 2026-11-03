import 'dart:math';

import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _question(int id, int quizId) => {
  'id': id,
  'quiz_id': quizId,
  'question_text': 'Question $id',
};

Map<String, dynamic> _choice(int id, int questionId) => {
  'id': id,
  'choice_text': 'Choice $id',
  'is_correct': id % 4 == 0,
  'question_id': questionId,
};

Map<String, dynamic> _subject(int id, String title) => {
  'id': id,
  'title': title,
  'description': '',
  'created_at': '2026-01-01T00:00:00.000Z',
};

void _seedTopic({
  required Map<int, List<Map<String, dynamic>>> quizzesBySubject,
  required Map<int, List<Map<String, dynamic>>> questionsByQuiz,
  required Map<int, List<Map<String, dynamic>>> choicesByQuestion,
  required int subjectId,
  required int quizId,
  required String title,
  required int count,
}) {
  quizzesBySubject.putIfAbsent(subjectId, () => []).add({
    'id': quizId,
    'title': title,
    'description': '',
    'created_at': '2026-01-01T00:00:00.000Z',
    'subject_id': subjectId,
    'configured_question_count': count,
  });
  questionsByQuiz[quizId] = List.generate(
    count + 5,
    (index) => _question((quizId * 1000) + index, quizId),
  );
  for (final question in questionsByQuiz[quizId]!) {
    final questionId = question['id'] as int;
    choicesByQuestion[questionId] = List.generate(
      4,
      (index) => _choice((questionId * 10) + index, questionId),
    );
  }
}

void main() {
  group('mock board generation', () {
    test('builds six subject sections with 100 questions each', () {
      final subjects = [
        _subject(1, 'Clinical Chemistry'),
        _subject(2, 'Microbiology and Parasitology'),
        _subject(3, 'Clinical Microscopy'),
        _subject(4, 'Hematology'),
        _subject(5, 'Blood Banking and Serology'),
        _subject(6, 'Histopathology and Medical Technology Laws/Ethics'),
      ];
      final quizzesBySubject = {
        for (final subject in subjects)
          subject['id'] as int: List.generate(
            4,
            (index) => {
              'id': ((subject['id'] as int) * 10) + index,
              'title': 'Topic $index',
              'description': '',
              'created_at': '2026-01-01T00:00:00.000Z',
              'subject_id': subject['id'],
              'configured_question_count': 25,
            },
          ),
      };
      final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
      final choicesByQuestion = <int, List<Map<String, dynamic>>>{};

      for (final quizzes in quizzesBySubject.values) {
        for (final quiz in quizzes) {
          final quizId = quiz['id'] as int;
          questionsByQuiz[quizId] = List.generate(
            30,
            (index) => _question((quizId * 1000) + index, quizId),
          );
          for (final question in questionsByQuiz[quizId]!) {
            final questionId = question['id'] as int;
            choicesByQuestion[questionId] = List.generate(
              4,
              (index) => _choice((questionId * 10) + index, questionId),
            );
          }
        }
      }

      final sections = buildMockBoardQuizItemsFromRows(
        subjects: subjects,
        quizzesBySubject: quizzesBySubject,
        questionsByQuiz: questionsByQuiz,
        choicesByQuestion: choicesByQuestion,
        random: Random(1),
      );

      expect(sections, hasLength(6));
      expect(sections.expand((section) => section.questions), hasLength(600));
      for (final section in sections) {
        expect(section.questions, hasLength(100));
      }
      expect(
        sections
            .expand((section) => section.questions)
            .map((q) => q.id)
            .toSet(),
        hasLength(600),
      );
    });
    test(
      'uses the fixed MTLE board sequence and combines configured sections',
      () {
        final subjects = [
          _subject(1, 'Clinical Chemistry'),
          _subject(2, 'Bacteriology'),
          _subject(3, 'Parasitology'),
          _subject(4, 'Mycology'),
          _subject(5, 'Virology'),
          _subject(6, 'Clinical Microscopy'),
          _subject(7, 'Hematology'),
          _subject(8, 'Immunology / Serology'),
          _subject(9, 'Immunohematology'),
          _subject(10, 'Histopathology'),
          _subject(11, 'Medical Technology Laws and Ethics'),
          _subject(12, 'Molecular Biology'),
        ];
        final quizzesBySubject = <int, List<Map<String, dynamic>>>{};
        final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
        final choicesByQuestion = <int, List<Map<String, dynamic>>>{};
        var quizId = 100;

        void add(int subjectId, String title, int count) {
          _seedTopic(
            quizzesBySubject: quizzesBySubject,
            questionsByQuiz: questionsByQuiz,
            choicesByQuestion: choicesByQuestion,
            subjectId: subjectId,
            quizId: quizId++,
            title: title,
            count: count,
          );
        }

        add(1, 'Clinical Chemistry - Carbohydrates', 100);
        add(2, 'Bacteriology configured set', 25);
        add(3, 'Parasitology configured set', 25);
        add(4, 'Mycology configured set', 25);
        add(5, 'Virology configured set', 25);
        add(6, 'Urinalysis and Body Fluids', 100);
        add(7, 'Hematology configured set', 100);
        add(8, 'Immunology and Serology', 50);
        add(9, 'Immunohematology', 50);
        add(10, 'Histopathology', 50);
        add(11, 'MT Laws and Ethics', 50);
        add(12, 'Molecular distractor', 100);

        final sections = buildMockBoardQuizItemsFromRows(
          subjects: subjects,
          quizzesBySubject: quizzesBySubject,
          questionsByQuiz: questionsByQuiz,
          choicesByQuestion: choicesByQuestion,
          random: Random(1),
        );

        expect(sections.map((section) => section.title), [
          'Clinical Chemistry',
          'Microbiology and Parasitology',
          'Clinical Microscopy',
          'Hematology',
          'Blood Banking and Serology',
          'Histopathology and Medical Technology Laws/Ethics',
        ]);
        for (final section in sections) {
          expect(section.questions, hasLength(100));
        }
        expect(sections.expand((section) => section.questions), hasLength(600));
        expect(
          sections.map((section) => section.title),
          isNot(contains('Molecular Biology')),
        );
        expect(
          sections.map((section) => section.title),
          isNot(contains('Mycology')),
        );
        expect(
          sections.map((section) => section.title),
          isNot(contains('Virology')),
        );
      },
    );

    test('throws a meaningful error when a configured topic is short', () {
      expect(
        () => buildMockBoardQuizItemsFromRows(
          subjects: [
            {
              'id': 1,
              'title': 'Clinical Chemistry',
              'description': '',
              'created_at': '2026-01-01T00:00:00.000Z',
            },
          ],
          quizzesBySubject: {
            1: [
              {
                'id': 10,
                'title': 'Carbohydrates',
                'description': '',
                'created_at': '2026-01-01T00:00:00.000Z',
                'subject_id': 1,
                'configured_question_count': 100,
              },
            ],
          },
          questionsByQuiz: {
            10: List.generate(99, (index) => _question(index + 1, 10)),
          },
          // Usable questions have choices with exactly one correct answer.
          choicesByQuestion: {
            for (var id = 1; id <= 99; id++)
              id: List.generate(4, (i) => _choice(id * 10 + i, id)),
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(
              'Carbohydrates needs 100 questions but only 99 are available',
            ),
          ),
        ),
      );
    });
  });
}
