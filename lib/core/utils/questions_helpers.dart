import 'dart:convert';
import 'dart:math';

import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';

final Map<String, SubjectScore> subjectScores = {};

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

Future<List<QuizDtoItems>> buildQuizItems(
  List<Map<String, dynamic>> subjects,
) async {
  final limitedSubjects = subjects;
  final quizzesBySubject = <int, List<Map<String, dynamic>>>{};
  final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
  final choicesByQuestion = <int, List<Map<String, dynamic>>>{};

  for (final subject in limitedSubjects) {
    final subjectId = readInt(subject['id']);
    if (subjectId == null) continue;

    final quizRows = await supabase
        .from('quizzes')
        .select('*')
        .eq('subject_id', subjectId)
        .order('created_at');
    final quizzes = quizRows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    quizzesBySubject[subjectId] = quizzes;
    final quizIds = quizzes
        .map((quiz) => readInt(quiz['id']))
        .whereType<int>()
        .toList();
    if (quizIds.isEmpty) continue;

    final questionRows = await supabase
        .from('questions')
        .select('id, quiz_id, question_text')
        .inFilter('quiz_id', quizIds);
    final questions = questionRows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final questionIds = questions
        .map((question) => readInt(question['id']))
        .whereType<int>()
        .toList();

    for (final question in questions) {
      final quizId = readInt(question['quiz_id']);
      if (quizId == null) continue;
      questionsByQuiz.putIfAbsent(quizId, () => []).add(question);
    }

    final groupedChoices = await _getChoicesByQuestion(questionIds);
    choicesByQuestion.addAll(groupedChoices);
  }

  return buildMockBoardQuizItemsFromRows(
    subjects: limitedSubjects,
    quizzesBySubject: quizzesBySubject,
    questionsByQuiz: questionsByQuiz,
    choicesByQuestion: choicesByQuestion,
  );
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

  for (final spec in mockBoardSectionSpecs) {
    final sourceSubjects = _subjectsForSection(subjects, spec);
    if (sourceSubjects.isEmpty) {
      throw StateError('${spec.title} has no configured database section');
    }

    final sourceQuizzes = <Map<String, dynamic>>[];
    var createdAt = '';
    for (final subject in sourceSubjects) {
      final subjectId = readInt(subject['id']);
      if (subjectId == null) continue;
      createdAt = createdAt.isEmpty
          ? (subject['created_at'] ?? subject['createdAt'] ?? '').toString()
          : createdAt;
      sourceQuizzes.addAll(quizzesBySubject[subjectId] ?? []);
    }

    if (sourceQuizzes.isEmpty) {
      throw StateError('${spec.title} has no configured topics');
    }

    final topicCounts = _configuredTopicCounts(
      quizzes: sourceQuizzes,
      label: spec.title,
    );
    final subjectQuestions = <Map<String, dynamic>>[];

    for (final quiz in sourceQuizzes) {
      final quizId = readInt(quiz['id']);
      if (quizId == null) continue;

      final requiredCount = topicCounts[quizId] ?? 0;
      if (requiredCount == 0) continue;

      final availableQuestions = (questionsByQuiz[quizId] ?? []).where((
        question,
      ) {
        final questionId = readInt(question['id']);
        return questionId != null && !usedQuestionIds.contains(questionId);
      }).toList();
      final selected = selectRandomRows(
        rows: availableQuestions,
        count: requiredCount,
        label: quiz['title']?.toString() ?? 'Topic $quizId',
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
          'choices': (choicesByQuestion[questionId] ?? [])
              .map((choice) => _normalizeChoice(choice))
              .toList(),
        });
      }
    }

    shuffleRows(subjectQuestions, rng);
    validateQuestionCount(
      actual: subjectQuestions.length,
      expected: mockBoardQuestionsPerSubject,
      label: spec.title,
    );

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
  );
  validateQuestionCount(
    actual: sections.expand((section) => section.questions).length,
    expected: mockBoardTotalQuestions,
    label: 'Mock Board final question count',
  );
  return sections;
}

List<Map<String, dynamic>> _subjectsForSection(
  List<Map<String, dynamic>> subjects,
  MockBoardSectionSpec spec,
) {
  return subjects.where((subject) {
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
    throw StateError(
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
}) {
  if (actual != expected) {
    throw StateError(
      '$label must contain exactly $expected item(s), found $actual',
    );
  }
}

Map<int, int> _configuredTopicCounts({
  required List<Map<String, dynamic>> quizzes,
  required String label,
}) {
  final counts = <int, int>{};

  for (final quiz in quizzes) {
    final quizId = readInt(quiz['id']);
    if (quizId == null) continue;
    final count = _readConfiguredQuestionCount(quiz);
    if (count == null) {
      throw StateError(
        '${quiz['title'] ?? 'Topic $quizId'} must define a configured question count',
      );
    }
    counts[quizId] = count;
  }

  final total = counts.values.fold<int>(0, (sum, count) => sum + count);
  validateQuestionCount(
    actual: total,
    expected: mockBoardQuestionsPerSubject,
    label: 'Configured topic question total',
  );
  return counts;
}

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

Future<List<Map<String, dynamic>>> getChoicesForQuestion(int questionId) async {
  final rows = await supabase
      .from('choices')
      .select('id, choice_text, is_correct, question_id')
      .eq('question_id', questionId)
      .order('id');

  return rows.map((row) => _normalizeChoice(row)).toList();
}

Future<Map<int, List<Map<String, dynamic>>>> _getChoicesByQuestion(
  List<int> questionIds,
) async {
  if (questionIds.isEmpty) return {};

  final rows = await supabase
      .from('choices')
      .select('id, choice_text, is_correct, question_id')
      .inFilter('question_id', questionIds)
      .order('id');
  final grouped = <int, List<Map<String, dynamic>>>{};

  for (final row in rows) {
    final normalized = _normalizeChoice(row);
    final questionId = readInt(normalized['questionId']);
    if (questionId == null) continue;
    grouped.putIfAbsent(questionId, () => []).add(normalized);
  }

  return grouped;
}

Future<String> getQuizTitle(int quizId) async {
  final quiz = await supabase
      .from('quizzes')
      .select('title')
      .eq('id', quizId)
      .maybeSingle();

  return quiz?['title']?.toString() ?? '';
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
    'is_correct': row['is_correct'] ?? row['is_correct'] ?? false,
    'questionId': readInt(row['question_id'] ?? row['questionId']) ?? 0,
  };
}

void recordAnswer(String subjectName, bool isCorrect) {
  final normalizedSubject = subjectName.isEmpty ? 'Unknown' : subjectName;
  final score = subjectScores.putIfAbsent(
    normalizedSubject,
    () => SubjectScore(),
  );
  score.total += 1;
  if (isCorrect) score.correct += 1;
}

List<Map<String, dynamic>> currentAnswerPayload() {
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

  const weights = [20, 20, 20, 20, 10, 10];
  const majorIndexes = {0, 1, 2, 3};
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
