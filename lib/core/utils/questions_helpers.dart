import 'dart:convert';

import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';
final Map<String, SubjectScore> subjectScores = {};

Future<List<QuizDtoItems>> buildQuizItems(
    List<Map<String, dynamic>> subjects,
  ) async {
    const totalQuestions = 20;
    final basePerSubject = totalQuestions ~/ subjects.length;
    final extra = totalQuestions % subjects.length;
    final quizItems = <QuizDtoItems>[];

    for (var subjectIndex = 0; subjectIndex < subjects.length; subjectIndex++) {
      final subject = subjects[subjectIndex];
      final subjectId = readInt(subject['id']);
      if (subjectId == null) continue;

      final takeCount = basePerSubject + (subjectIndex < extra ? 1 : 0);
      final quizRows = await supabase
          .from('quizzes')
          .select('id, title, description, created_at, subject_id')
          .eq('subject_id', subjectId);
      final quizzes = quizRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final quizIds = quizzes
          .map((quiz) => readInt(quiz['id']))
          .whereType<int>()
          .toList();
      if (quizIds.isEmpty) continue;

      final questionRows = await supabase
          .from('questions')
          .select('id, quiz_id, question_text')
          .inFilter('quiz_id', quizIds)
          .limit(takeCount);
      final questions = questionRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final questionIds = questions
          .map((question) => readInt(question['id']))
          .whereType<int>()
          .toList();
      final choicesByQuestion = await _getChoicesByQuestion(questionIds);
      final questionsByQuiz = _groupQuestionsByQuiz(
        questions,
        choicesByQuestion,
      );

      for (final quiz in quizzes) {
        final quizId = readInt(quiz['id']);
        if (quizId == null) continue;

        final quizQuestions = questionsByQuiz[quizId] ?? [];
        if (quizQuestions.isEmpty) continue;

        quizItems.add(
          QuizDtoItems.fromJson({
            'id': quizId,
            'title': quiz['title'] ?? '',
            'description': quiz['description'] ?? '',
            'createdAt': quiz['created_at'] ?? '',
            'subjectId': readInt(quiz['subject_id']) ?? 0,
            'questions': quizQuestions,
          }),
        );
      }
    }

    return quizItems;
  }

  Future<List<Map<String, dynamic>>> getChoicesForQuestion(
    int questionId,
  ) async {
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

  Map<int, List<Map<String, dynamic>>> _groupQuestionsByQuiz(
    List<Map<String, dynamic>> questions,
    Map<int, List<Map<String, dynamic>>> choicesByQuestion,
  ) {
    final grouped = <int, List<Map<String, dynamic>>>{};

    for (final question in questions) {
      final quizId = readInt(question['quiz_id']);
      final questionId = readInt(question['id']);
      if (quizId == null || questionId == null) continue;

      grouped.putIfAbsent(quizId, () => []).add({
        'id': questionId,
        'questionText': question['question_text'] ?? '',
        'choices': choicesByQuestion[questionId] ?? [],
      });
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

  _MtleEvaluation evaluateMtleResult(List<Map<String, dynamic>> answers) {
    if (answers.length != 6) {
      return _MtleEvaluation(
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

    return _MtleEvaluation(
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

class _MtleEvaluation {
  final double gwa;
  final bool passed;
  final double failedWeight;
  final bool hasMajorBelow50;
  final List<String> reasons;

  const _MtleEvaluation({
    required this.gwa,
    required this.passed,
    required this.failedWeight,
    required this.hasMajorBelow50,
    required this.reasons,
  });
}
