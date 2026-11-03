import 'package:achievia/core/utils/study_questions_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> q(int id, Map<String, dynamic> extra) => {
  'id': id,
  'quiz_id': 1,
  'question_text': 'Question $id',
  ...extra,
};

List<Map<String, dynamic>> choicesFor(int id) => [
  {'id': id * 10, 'question_id': id, 'choice_text': 'A', 'is_correct': true},
  {
    'id': id * 10 + 1,
    'question_id': id,
    'choice_text': 'B',
    'is_correct': false,
  },
];

void main() {
  test('the admin explanation (correct_description) is the rationale', () {
    final built = buildStudyQuestions(
      questionRows: [
        q(1, {'rationale': null, 'correct_description': '<p>Why A</p>'}),
        q(2, {'rationale': 'Legacy text', 'correct_description': 'Other'}),
        q(3, {'rationale': 'NULL', 'correct_description': null}),
      ],
      choiceRows: [...choicesFor(1), ...choicesFor(2), ...choicesFor(3)],
    );
    final byId = {for (final x in built) x.id: x};
    expect(byId[1]!.rationale, '<p>Why A</p>');
    expect(byId[2]!.rationale, 'Legacy text');
    expect(byId[3]!.rationale, '');
  });

  test('notes belong to their own question and "NULL" means none', () {
    final built = buildStudyQuestions(
      questionRows: [
        q(1, {'notes': 'Note for one'}),
        q(2, {'notes': 'NULL'}),
        q(3, {'notes': null}),
        q(4, {'notes': 'Note for four'}),
      ],
      choiceRows: [
        ...choicesFor(1),
        ...choicesFor(2),
        ...choicesFor(3),
        ...choicesFor(4),
      ],
    );
    final byId = {for (final x in built) x.id: x.notes};
    expect(byId, {1: 'Note for one', 2: '', 3: '', 4: 'Note for four'});
  });
}
