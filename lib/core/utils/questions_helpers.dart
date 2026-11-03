import 'dart:convert';
import 'dart:math';

import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/question_eligibility.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';

final Map<String, SubjectScore> subjectScores = {};

/// The choice the user picked for each question of the Mock Board in progress
/// (question id -> choice id). The server grades these; the score kept in
/// [subjectScores] is only used for on-screen progress.
final Map<int, int> mockBoardSelections = {};

const int mockBoardSubjectCount = 6;
const int mockBoardQuestionsPerSubject = 100;
const int mockBoardTotalQuestions =
    mockBoardSubjectCount * mockBoardQuestionsPerSubject;
const List<MockBoardSectionSpec> mockBoardSectionSpecs = [
  MockBoardSectionSpec(
    id: 1,
    title: 'Clinical Chemistry',
    matchers: ['clinical chemistry'],
  ),
  MockBoardSectionSpec(
    id: 2,
    title: 'Microbiology and Parasitology',
    matchers: [
      'microbiology parasitology',
      'microbiology and parasitology',
      'bacteriology',
      'parasitology',
      'mycology',
      'virology',
    ],
  ),
  MockBoardSectionSpec(
    id: 3,
    title: 'Clinical Microscopy',
    matchers: ['clinical microscopy'],
  ),
  MockBoardSectionSpec(id: 4, title: 'Hematology', matchers: ['hematology']),
  MockBoardSectionSpec(
    id: 5,
    title: 'Blood Banking and Serology',
    matchers: [
      'blood banking serology',
      'blood banking and serology',
      'blood banking',
      'immunology serology',
      'immunology and serology',
      'serology',
      'immunohematology',
    ],
  ),
  MockBoardSectionSpec(
    id: 6,
    title: 'Histopathology and Medical Technology Laws/Ethics',
    matchers: [
      'histopathology medical technology laws ethics',
      'histopathology medical technology laws and ethics',
      'histopathology',
      'histopath',
      'medtech laws',
      'medical technology laws',
      'medical technology laws ethics',
      'medical technology laws and ethics',
      'laws ethics',
    ],
  ),
];

class MockBoardSectionSpec {
  final int id;
  final String title;
  final List<String> matchers;

  const MockBoardSectionSpec({
    required this.id,
    required this.title,
    required this.matchers,
  });
}

List<Map<String, dynamic>> selectMockBoardSubjects(
  List<Map<String, dynamic>> subjects,
) {
  return subjects.where((subject) {
    return mockBoardSectionSpecs.any(
      (spec) => _subjectsForSection([subject], spec).isNotEmpty,
    );
  }).toList();
}

List<QuizDtoItems> buildMockBoardQuizItemsFromRows({
  required List<Map<String, dynamic>> subjects,
  required Map<int, List<Map<String, dynamic>>> quizzesBySubject,
  required Map<int, List<Map<String, dynamic>>> questionsByQuiz,
  required Map<int, List<Map<String, dynamic>>> choicesByQuestion,
  Random? random,
}) {
  final rng = random ?? Random();
  final sections = <QuizDtoItems>[];
  final usedQuestionIds = <int>{};
  var expectedTotal = 0;

  for (final spec in mockBoardSectionSpecs) {
    final sourceSubjects = _subjectsForSection(subjects, spec);
    if (sourceSubjects.isEmpty) {
      throw MockBoardException(
        MockBoardFailure.notConfigured,
        '${spec.title} has no configured database section',
      );
    }

    final sourceQuizzes = <Map<String, dynamic>>[];
    var createdAt = '';
    for (final subject in sourceSubjects) {
      final subjectId = readInt(subject['id']);
      if (subjectId == null) continue;
      createdAt = createdAt.isEmpty
          ? (subject['created_at'] ?? subject['createdAt'] ?? '').toString()
          : createdAt;
      sourceQuizzes.addAll(
        (quizzesBySubject[subjectId] ?? []).where((q) => !isSoftDeleted(q)),
      );
    }

    if (sourceQuizzes.isEmpty) {
      throw MockBoardException(
        MockBoardFailure.notConfigured,
        '${spec.title} has no configured topics',
      );
    }

    final blueprint = mockBoardSectionBlueprint(
      subjects: sourceSubjects,
      quizzesBySubject: quizzesBySubject,
      label: spec.title,
    );
    final subjectQuestions = <Map<String, dynamic>>[];

    void take(Iterable<int> quizIds, int count, String label) {
      if (count == 0) return;
      final availableQuestions = [
        for (final quizId in quizIds)
          ...(questionsByQuiz[quizId] ?? []).where((question) {
            final questionId = readInt(question['id']);
            return questionId != null &&
                !usedQuestionIds.contains(questionId) &&
                isEligibleMockBoardQuestion(
                  question,
                  choicesByQuestion[questionId] ?? const [],
                );
          }),
      ];
      final selected = selectRandomRows(
        rows: availableQuestions,
        count: count,
        label: label,
        random: rng,
      );

      for (final question in selected) {
        final questionId = readInt(question['id']);
        if (questionId == null) continue;
        usedQuestionIds.add(questionId);
        subjectQuestions.add({
          'id': questionId,
          'questionText':
              question['question_text'] ?? question['questionText'] ?? '',
          'imagePath': (question['image_path'] ?? question['imagePath'] ?? '')
              .toString(),
          // The admin panel stores the explanation in `correct_description`;
          // the older `rationale` column is used only when it is filled.
          'rationale': _firstFilledText(
            question['rationale'],
            question['correct_description'],
          ),
          'choices': (choicesByQuestion[questionId] ?? [])
              .where((choice) => !isSoftDeleted(choice))
              .map((choice) => _normalizeChoice(choice))
              .toList(),
        });
      }
    }

    for (final quiz in sourceQuizzes) {
      final quizId = readInt(quiz['id']);
      if (quizId == null) continue;
      take(
        [quizId],
        blueprint.topicCounts[quizId] ?? 0,
        quiz['title']?.toString() ?? 'Topic $quizId',
      );
    }
    for (final pool in blueprint.pools) {
      take(pool.quizIds, pool.count, pool.label);
    }

    shuffleRows(subjectQuestions, rng);
    validateQuestionCount(
      actual: subjectQuestions.length,
      expected: blueprint.total,
      label: spec.title,
    );
    expectedTotal += blueprint.total;

    sections.add(
      QuizDtoItems.fromJson({
        'id': spec.id,
        'title': spec.title,
        'description': '',
        'createdAt': createdAt,
        'subjectId': spec.id,
        'questions': subjectQuestions,
      }),
    );
  }

  validateQuestionCount(
    actual: sections.length,
    expected: mockBoardSubjectCount,
    label: 'Mock Board subject count',
    failure: MockBoardFailure.notConfigured,
  );
  validateQuestionCount(
    actual: sections.expand((section) => section.questions).length,
    expected: expectedTotal,
    label: 'Mock Board final question count',
  );
  return sections;
}

/// True when [subject] belongs to the Mock Board section [spec].
bool isMockBoardSectionSubject(
  Map<String, dynamic> subject,
  MockBoardSectionSpec spec,
) => _subjectsForSection([subject], spec).isNotEmpty;

List<Map<String, dynamic>> _subjectsForSection(
  List<Map<String, dynamic>> subjects,
  MockBoardSectionSpec spec,
) {
  return subjects.where((subject) {
    if (isSoftDeleted(subject)) return false;
    final title = _normalizeBoardTitle(subject['title']?.toString() ?? '');
    if (spec.title == 'Hematology' && title.contains('immunohematology')) {
      return false;
    }
    return spec.matchers.any((matcher) => title.contains(matcher));
  }).toList();
}

String _normalizeBoardTitle(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll('/', ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<Map<String, dynamic>> selectRandomRows({
  required List<Map<String, dynamic>> rows,
  required int count,
  required String label,
  Random? random,
}) {
  if (rows.length < count) {
    throw MockBoardException(
      MockBoardFailure.notEnoughQuestions,
      '$label needs $count questions but only ${rows.length} are available',
    );
  }

  final copy = rows.toList();
  shuffleRows(copy, random ?? Random());
  return copy.take(count).toList();
}

void shuffleRows(List<Map<String, dynamic>> rows, Random random) {
  for (var i = rows.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final current = rows[i];
    rows[i] = rows[j];
    rows[j] = current;
  }
}

void validateQuestionCount({
  required int actual,
  required int expected,
  required String label,
  MockBoardFailure failure = MockBoardFailure.notEnoughQuestions,
}) {
  if (actual != expected) {
    throw MockBoardException(
      failure,
      '$label must contain exactly $expected item(s), found $actual',
    );
  }
}

/// A question may enter a Mock Board only when it and its choices are not
/// soft-deleted and the live choices have exactly one correct answer (the
/// same rule as exams, Study Mode and the Question of the Day).
bool isEligibleMockBoardQuestion(
  Map<String, dynamic> question,
  Iterable<Map<String, dynamic>> choices,
) {
  if (isSoftDeleted(question)) return false;
  final live = choices.where((choice) => !isSoftDeleted(choice)).toList();
  return isValidSingleAnswer(
    total: live.length,
    correct: live.where((c) => c['is_correct'] == true).length,
    minChoices: 2,
  );
}

/// A subject whose live topics form one pool: [count] questions are drawn at
/// random from any of them (e.g. "2 Mycology questions from any topic").
class MockBoardTopicPool {
  final List<int> quizIds;
  final int count;
  final String label;

  const MockBoardTopicPool({
    required this.quizIds,
    required this.count,
    required this.label,
  });
}

/// How one section's 100 questions are split: a fixed count per topic
/// ([topicCounts]) plus pooled subjects ([pools]).
class MockBoardBlueprint {
  final Map<int, int> topicCounts;
  final List<MockBoardTopicPool> pools;

  const MockBoardBlueprint({required this.topicCounts, required this.pools});

  int get total =>
      topicCounts.values.fold<int>(0, (sum, count) => sum + count) +
      pools.fold<int>(0, (sum, pool) => sum + pool.count);

  /// Every topic that supplies questions, with the most it may supply.
  Map<int, int> get maxNeedByQuiz => {
    ...topicCounts,
    for (final pool in pools)
      for (final quizId in pool.quizIds) quizId: pool.count,
  };
}

/// Blueprint of one section built from its (live) [subjects]. A subject with
/// `mock_board_pool_count` set is a pool and its topics' own counts are
/// ignored; every other live topic must have a configured count. The section
/// must add up to exactly [mockBoardQuestionsPerSubject].
MockBoardBlueprint mockBoardSectionBlueprint({
  required List<Map<String, dynamic>> subjects,
  required Map<int, List<Map<String, dynamic>>> quizzesBySubject,
  required String label,
}) {
  final counts = <int, int>{};
  final pools = <MockBoardTopicPool>[];

  for (final subject in subjects) {
    final subjectId = readInt(subject['id']);
    if (subjectId == null) continue;
    final quizzes = (quizzesBySubject[subjectId] ?? const [])
        .where((quiz) => !isSoftDeleted(quiz))
        .toList();
    final subjectTitle = subject['title']?.toString() ?? 'Subject $subjectId';

    final poolCount = readMockBoardPoolCount(subject);
    if (poolCount != null) {
      final quizIds = quizzes.map((q) => readInt(q['id'])).whereType<int>();
      if (poolCount > 0 && quizIds.isEmpty) {
        throw MockBoardException(
          MockBoardFailure.notConfigured,
          '$subjectTitle has no topics for its question pool',
        );
      }
      pools.add(
        MockBoardTopicPool(
          quizIds: quizIds.toList(),
          count: poolCount,
          label: subjectTitle,
        ),
      );
      continue;
    }

    for (final quiz in quizzes) {
      final quizId = readInt(quiz['id']);
      if (quizId == null) continue;
      final count = _readConfiguredQuestionCount(quiz);
      if (count == null) {
        throw MockBoardException(
          MockBoardFailure.notConfigured,
          '${quiz['title'] ?? 'Topic $quizId'} must define a configured question count',
        );
      }
      counts[quizId] = count;
    }
  }

  final total =
      counts.values.fold<int>(0, (sum, count) => sum + count) +
      pools.fold<int>(0, (sum, pool) => sum + pool.count);
  validateQuestionCount(
    actual: total,
    expected: _expectedSectionTotal(subjects, quizzesBySubject),
    label: '$label configured question total',
    failure: MockBoardFailure.notConfigured,
  );
  return MockBoardBlueprint(topicCounts: counts, pools: pools);
}

/// Questions the Medtech Laws and Ethics topics will add to Section 6. Until
/// that subject has live topics, Section 6 runs short by this much instead of
/// blocking every Mock Board. It disappears by itself once the topics exist.
const int mockBoardPendingLawsQuestions = 35;

/// 100, except while a "Laws" subject in the section has no live topics yet.
int _expectedSectionTotal(
  List<Map<String, dynamic>> subjects,
  Map<int, List<Map<String, dynamic>>> quizzesBySubject,
) {
  final lawsPending = subjects.any((subject) {
    final title = _normalizeBoardTitle(subject['title']?.toString() ?? '');
    if (!title.contains('laws')) return false;
    final quizzes = quizzesBySubject[readInt(subject['id'])] ?? const [];
    return quizzes.every(isSoftDeleted);
  });
  return lawsPending
      ? mockBoardQuestionsPerSubject - mockBoardPendingLawsQuestions
      : mockBoardQuestionsPerSubject;
}

/// `subjects.mock_board_pool_count`: null when the subject is not a pool.
int? readMockBoardPoolCount(Map<String, dynamic> subject) =>
    readInt(subject['mock_board_pool_count'] ?? subject['mockBoardPoolCount']);

int? _readConfiguredQuestionCount(Map<String, dynamic> row) {
  const keys = [
    'configured_question_count',
    'configuredQuestionCount',
    'question_count',
    'questionCount',
    'mock_board_question_count',
    'mockBoardQuestionCount',
    'number_of_questions',
    'numberOfQuestions',
  ];

  for (final key in keys) {
    final value = readInt(row[key]);
    if (value != null) return value;
  }
  return null;
}

Map<String, dynamic> normalizeSubject(Map<String, dynamic> row) {
  return {
    ...row,
    'courseId': row['course_id'] ?? row['courseId'] ?? 0,
    'description': row['description'] ?? '',
    'createdAt': row['created_at'] ?? row['createdAt'] ?? '',
  };
}

Map<String, dynamic> _normalizeChoice(Map<String, dynamic> row) {
  return {
    'id': readInt(row['id']) ?? 0,
    'choiceText': row['choice_text'] ?? row['choiceText'] ?? '',
    'is_correct': row['is_correct'] ?? false,
    'questionId': readInt(row['question_id'] ?? row['questionId']) ?? 0,
  };
}

void recordAnswer(
  String subjectName,
  bool isCorrect, {
  int? questionId,
  int? choiceId,
}) {
  final normalizedSubject = subjectName.isEmpty ? 'Unknown' : subjectName;
  if (questionId != null && choiceId != null) {
    // Changing an answer replaces the earlier one: its contribution is taken
    // back out of the tally it was added to before the new one is added.
    final previous = _recordedAnswers[questionId];
    if (previous != null) {
      final earlier = subjectScores[previous.subject]!;
      earlier.total -= 1;
      if (previous.isCorrect) earlier.correct -= 1;
    }
    mockBoardSelections[questionId] = choiceId;
    _recordedAnswers[questionId] = (
      subject: normalizedSubject,
      isCorrect: isCorrect,
    );
  }
  final score = subjectScores.putIfAbsent(
    normalizedSubject,
    () => SubjectScore(),
  );
  score.total += 1;
  if (isCorrect) score.correct += 1;
}

/// What each question currently contributes to [subjectScores], so that
/// changing an answer replaces its tally instead of adding to it. Only
/// [resetMockBoardAnswers] clears it, together with the tallies it describes.
final Map<int, ({String subject, bool isCorrect})> _recordedAnswers = {};

/// Forgets every answer of the Mock Board in progress: selections, score
/// tallies and the per-question contributions behind them, always together.
void resetMockBoardAnswers() {
  subjectScores.clear();
  mockBoardSelections.clear();
  _recordedAnswers.clear();
}

/// Items for the `save_mock_board_attempt` RPC: what the user answered, never
/// what is correct. Unanswered questions carry a null `selected_choice_id`.
/// Section ids follow the Mock Board blueprint (1..6).
List<Map<String, dynamic>> mockBoardSubmissionItems(
  List<QuizDtoItems> sections,
  Map<int, int> selections,
) {
  return [
    for (final section in sections)
      for (final question in section.questions)
        {
          'section': section.id,
          'question_id': question.id,
          'selected_choice_id': selections[question.id],
        },
  ];
}

/// Answer payload for scoring. When the generated [sections] are known, the
/// payload follows the section order (the MTLE weights are positional) and a
/// section's rating is correct answers over ALL its questions, so unanswered
/// or skipped questions count as wrong instead of inflating the score.
List<Map<String, dynamic>> currentAnswerPayload({
  List<QuizDtoItems> sections = const [],
}) {
  if (sections.isNotEmpty) {
    return [
      for (final section in sections)
        () {
          final total = section.questions.length;
          final correct = subjectScores[section.title]?.correct ?? 0;
          final rating = total == 0 ? 0.0 : (correct / total) * 100;
          return {
            'is_correct': correct > 0,
            'name': section.title,
            'score': rating,
          };
        }(),
    ];
  }
  return subjectScores.entries.map((entry) {
    final score = entry.value;
    return {
      'is_correct': score.correct > 0,
      'name': entry.key,
      'score': score.rating,
    };
  }).toList();
}

List<Map<String, dynamic>> normalizeAnswers(dynamic rawAnswer) {
  final decoded = rawAnswer is String ? jsonDecode(rawAnswer) : rawAnswer;
  if (decoded is! List) return [];

  return decoded
      .whereType<Map>()
      .map((answer) => Map<String, dynamic>.from(answer))
      .toList();
}

QuizScoreResponse scoreResponse(List<Map<String, dynamic>> answers) {
  final evaluation = evaluateMtleResult(answers);

  return QuizScoreResponse.fromJson({
    'success': evaluation.passed,
    'data': {
      'score': {
        'score': evaluation.gwa.toStringAsFixed(2),
        'answer': jsonEncode(answers),
        'passed': evaluation.passed,
        'failedWeight': evaluation.failedWeight,
        'hasMajorBelow50': evaluation.hasMajorBelow50,
        'reasons': evaluation.reasons,
      },
    },
  });
}

QuizScoreResponse emptyScoreResponse() => scoreResponse([]);

MtleEvaluation evaluateMtleResult(List<Map<String, dynamic>> answers) {
  if (answers.length != 6) {
    return MtleEvaluation(
      gwa: 0,
      passed: false,
      failedWeight: 0,
      hasMajorBelow50: false,
      reasons: ['Incomplete MTLE subject set'],
    );
  }

  // Positional, in mockBoardSectionSpecs order: Clinical Microscopy (index 2)
  // and Histopathology/Laws (index 5) are the two 10% subjects.
  const weights = [20, 20, 10, 20, 20, 10];
  const majorIndexes = {0, 1, 3, 4};
  var weightedTotal = 0.0;
  var failedWeight = 0.0;
  var hasMajorBelow50 = false;

  for (var answerIndex = 0; answerIndex < answers.length; answerIndex++) {
    final score = _readDouble(answers[answerIndex]['score']);
    final weight = weights[answerIndex].toDouble();
    weightedTotal += score * weight;

    if (score < 75) failedWeight += weight;
    if (majorIndexes.contains(answerIndex) && score < 50) {
      hasMajorBelow50 = true;
    }
  }

  final gwa = double.parse((weightedTotal / 100).toStringAsFixed(2));
  final reasons = <String>[];

  if (gwa < 75) reasons.add('GWA is below 75%');
  if (hasMajorBelow50) {
    reasons.add('At least one major subject is below 50%');
  }
  if (failedWeight >= 60) {
    reasons.add('Failed subjects reach 60% or more of total exam weight');
  }

  return MtleEvaluation(
    gwa: gwa,
    passed: reasons.isEmpty,
    failedWeight: failedWeight,
    hasMajorBelow50: hasMajorBelow50,
    reasons: reasons,
  );
}

int? readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

final _timestampWithoutOffset = RegExp(
  r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?$',
);

/// `quiz_attempts.attempted_at` holds UTC, but a column without a time zone
/// returns it with no offset, which DateTime.parse would read as local time.
/// Values that carry an offset, and date-only values, are left as they are.
String utcTimestampText(Object? value) {
  final text = value?.toString() ?? '';
  return _timestampWithoutOffset.hasMatch(text) ? '${text}Z' : text;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class SubjectScore {
  int correct = 0;
  int total = 0;

  double get rating => total == 0 ? 0 : (correct / total) * 100;
}

class MtleEvaluation {
  final double gwa;
  final bool passed;
  final double failedWeight;
  final bool hasMajorBelow50;
  final List<String> reasons;

  const MtleEvaluation({
    required this.gwa,
    required this.passed,
    required this.failedWeight,
    required this.hasMajorBelow50,
    required this.reasons,
  });
}

/// First value holding real text (not null, empty or the literal "null").
String _firstFilledText(Object? first, [Object? second]) {
  for (final value in [first, second]) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}
