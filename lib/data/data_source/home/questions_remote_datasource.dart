import 'dart:convert';
import 'dart:math';

import 'package:achievia/core/network/offline_caching.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class QuestionRepoDataSource {
  Future<List<QuestionsDto>> getAllQuestions();
  Future<QotdDto> getQotd();
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto);
  Future<List<QuizDtoItems>> getTheGeneratedQuiz();
  Future<List<QuestionsDto>> randomizeQuestion(int index);
  Future<QuizScoreResponse> getResults(int noOfAttempt);
  Future<int> putToAttempt();
}

@lazySingleton
@injectable
class QuestionsRemoteDatasource implements QuestionRepoDataSource {
  final SupabaseUserContext userContext;
  final OfflineCaching local;
  final Map<String, _SubjectScore> _subjectScores = {};

  QuestionsRemoteDatasource(
    this.local, {
    this.userContext = const SupabaseUserContext(),
  });

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<QuestionsDto>> getAllQuestions() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        throw Exception("Session Expired");
      }
      final response = await _supabase
          .from('subjects')
          .select(
            'id, title, course_id, description, image, day_subject, created_at',
          )
          .order('created_at');

      if (response.isEmpty) {
        return [];
      }
      return response
          .map((json) => QuestionsDto.fromJson(_normalizeSubject(json)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QotdDto> getQotd() async {
    try {
      final question = await _supabase
          .from('questions')
          .select('id, quiz_id, question_text')
          .order('id')
          .limit(1)
          .maybeSingle();

      if (question == null) return QotdDto.fromJson({});

      final questionId = _readInt(question['id']) ?? 0;
      final quizId = _readInt(question['quiz_id']) ?? 0;
      final choices = await _getChoicesForQuestion(questionId);

      return QotdDto.fromJson({
        'quizId': quizId,
        'id': questionId,
        'title': await _getQuizTitle(quizId),
        'questionText': question['question_text'] ?? '',
        'choices': choices,
      });
    } catch (e) {
      debugPrint(e.toString());
      return QotdDto.fromJson({});
    }
  }

  @override
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto) async {
    try {
      final answerDto = dto.student_id.isEmpty
          ? QotdDtoPost(
              chosen_answer: dto.chosen_answer,
              quiz_id: dto.quiz_id,
              student_id: await userContext.currentUserId(),
            )
          : dto;
      final choice = await _supabase
          .from('choices')
          .select('id, choice_text, is_correct, question_id')
          .eq('choice_text', answerDto.chosen_answer)
          .order('id')
          .limit(1)
          .maybeSingle();

      if (choice == null) return answerDto;

      final questionId = _readInt(choice['question_id']);
      if (questionId == null) return answerDto;

      final question = await _supabase
          .from('questions')
          .select('quiz_id')
          .eq('id', questionId)
          .maybeSingle();
      final quizId = _readInt(question?['quiz_id']);
      final subjectName = quizId == null ? '' : await _getQuizTitle(quizId);
      _recordAnswer(subjectName, choice['is_correct'] == true);

      return answerDto;
    } catch (e) {
      debugPrint("Exception: $e");
      return QotdDtoPost(chosen_answer: '', quiz_id: 0, student_id: '');
    }
  }

  @override
  Future<List<QuestionsDto>> randomizeQuestion(int index) async {
    try {
      _subjectScores.clear();

      final response = await _supabase
          .from('subjects')
          .select(
            'id, title, course_id, description, image, day_subject, created_at',
          )
          .order('created_at');
      final subjects = response
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (subjects.isEmpty) return [];

      final shuffledSubjects = [...subjects]..shuffle(Random());
      final selectedSubjects = shuffledSubjects
          .take(min(6, shuffledSubjects.length))
          .toList();
      final quizItems = await _buildQuizItems(selectedSubjects);
      final questions = selectedSubjects
          .map((subject) => QuestionsDto.fromJson(_normalizeSubject(subject)))
          .toList();

      debugPrint(
        'Quiz Titles: ${quizItems.map((quiz) => quiz.title).toList()}',
        wrapWidth: 1024,
      );
      await local.replaceGeneratedMockboardCache(
        questions: questions,
        quizItems: quizItems,
      );
      return questions;
    } catch (e) {
      debugPrint("Exception: $e");
      return [];
    }
  }

  @override
  Future<List<QuizDtoItems>> getTheGeneratedQuiz() async {
    try {
      final cache = await local.getQuizFromCache();
      return cache;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  @override
  Future<QuizScoreResponse> getResults(int noOfAttempt) async {
    debugPrint('from quiz: $noOfAttempt');
    try {
      final userId = await userContext.currentUserId();
      final attempt = await _supabase
          .from('quiz_attempts')
          .select('score, answer')
          .eq('student_id', userId)
          .eq('no_of_attempt', noOfAttempt)
          .maybeSingle();

      if (attempt == null) return _emptyScoreResponse();

      final answers = _normalizeAnswers(attempt['answer']);
      return _scoreResponse(answers);
    } catch (e) {
      debugPrint(e.toString());
      return _emptyScoreResponse();
    }
  }

  @override
  Future<int> putToAttempt() async {
    try {
      final userId = await userContext.currentUserId();
      final previousAttempts = await _supabase
          .from('quiz_attempts')
          .select('id')
          .eq('student_id', userId);
      final attemptNumber = previousAttempts.length + 1;
      final answers = _currentAnswerPayload();
      final evaluation = _evaluateMtleResult(answers);

      await _supabase.from('quiz_attempts').insert({
        'student_id': userId,
        'score': evaluation.gwa,
        'attempted_at': DateTime.now().toIso8601String(),
        'answer': answers,
        'no_of_attempt': attemptNumber,
        'summary': answers,
      });

      _subjectScores.clear();
      debugPrint('from datasource: $attemptNumber');
      return attemptNumber;
    } catch (e) {
      debugPrint("Exception: $e");
      return 0;
    }
  }

  Future<List<QuizDtoItems>> _buildQuizItems(
    List<Map<String, dynamic>> subjects,
  ) async {
    const totalQuestions = 20;
    final basePerSubject = totalQuestions ~/ subjects.length;
    final extra = totalQuestions % subjects.length;
    final quizItems = <QuizDtoItems>[];

    for (var subjectIndex = 0; subjectIndex < subjects.length; subjectIndex++) {
      final subject = subjects[subjectIndex];
      final subjectId = _readInt(subject['id']);
      if (subjectId == null) continue;

      final takeCount = basePerSubject + (subjectIndex < extra ? 1 : 0);
      final quizRows = await _supabase
          .from('quizzes')
          .select('id, title, description, created_at, subject_id')
          .eq('subject_id', subjectId);
      final quizzes = quizRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final quizIds = quizzes
          .map((quiz) => _readInt(quiz['id']))
          .whereType<int>()
          .toList();
      if (quizIds.isEmpty) continue;

      final questionRows = await _supabase
          .from('questions')
          .select('id, quiz_id, question_text')
          .inFilter('quiz_id', quizIds)
          .limit(takeCount);
      final questions = questionRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final questionIds = questions
          .map((question) => _readInt(question['id']))
          .whereType<int>()
          .toList();
      final choicesByQuestion = await _getChoicesByQuestion(questionIds);
      final questionsByQuiz = _groupQuestionsByQuiz(
        questions,
        choicesByQuestion,
      );

      for (final quiz in quizzes) {
        final quizId = _readInt(quiz['id']);
        if (quizId == null) continue;

        final quizQuestions = questionsByQuiz[quizId] ?? [];
        if (quizQuestions.isEmpty) continue;

        quizItems.add(
          QuizDtoItems.fromJson({
            'id': quizId,
            'title': quiz['title'] ?? '',
            'description': quiz['description'] ?? '',
            'createdAt': quiz['created_at'] ?? '',
            'subjectId': _readInt(quiz['subject_id']) ?? 0,
            'questions': quizQuestions,
          }),
        );
      }
    }

    return quizItems;
  }

  Future<List<Map<String, dynamic>>> _getChoicesForQuestion(
    int questionId,
  ) async {
    final rows = await _supabase
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

    final rows = await _supabase
        .from('choices')
        .select('id, choice_text, is_correct, question_id')
        .inFilter('question_id', questionIds)
        .order('id');
    final grouped = <int, List<Map<String, dynamic>>>{};

    for (final row in rows) {
      final normalized = _normalizeChoice(row);
      final questionId = _readInt(normalized['questionId']);
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
      final quizId = _readInt(question['quiz_id']);
      final questionId = _readInt(question['id']);
      if (quizId == null || questionId == null) continue;

      grouped.putIfAbsent(quizId, () => []).add({
        'id': questionId,
        'questionText': question['question_text'] ?? '',
        'choices': choicesByQuestion[questionId] ?? [],
      });
    }

    return grouped;
  }

  Future<String> _getQuizTitle(int quizId) async {
    final quiz = await _supabase
        .from('quizzes')
        .select('title')
        .eq('id', quizId)
        .maybeSingle();

    return quiz?['title']?.toString() ?? '';
  }

  Map<String, dynamic> _normalizeSubject(Map<String, dynamic> row) {
    return {
      ...row,
      'courseId': row['course_id'] ?? row['courseId'] ?? 0,
      'description': row['description'] ?? '',
      'createdAt': row['created_at'] ?? row['createdAt'] ?? '',
    };
  }

  Map<String, dynamic> _normalizeChoice(Map<String, dynamic> row) {
    return {
      'id': _readInt(row['id']) ?? 0,
      'choiceText': row['choice_text'] ?? row['choiceText'] ?? '',
      'is_correct': row['is_correct'] ?? row['is_correct'] ?? false,
      'questionId': _readInt(row['question_id'] ?? row['questionId']) ?? 0,
    };
  }

  void _recordAnswer(String subjectName, bool isCorrect) {
    final normalizedSubject = subjectName.isEmpty ? 'Unknown' : subjectName;
    final score = _subjectScores.putIfAbsent(
      normalizedSubject,
      () => _SubjectScore(),
    );
    score.total += 1;
    if (isCorrect) score.correct += 1;
  }

  List<Map<String, dynamic>> _currentAnswerPayload() {
    return _subjectScores.entries.map((entry) {
      final score = entry.value;
      return {
        'is_correct': score.correct > 0,
        'name': entry.key,
        'score': score.rating,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _normalizeAnswers(dynamic rawAnswer) {
    final decoded = rawAnswer is String ? jsonDecode(rawAnswer) : rawAnswer;
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((answer) => Map<String, dynamic>.from(answer))
        .toList();
  }

  QuizScoreResponse _scoreResponse(List<Map<String, dynamic>> answers) {
    final evaluation = _evaluateMtleResult(answers);

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

  QuizScoreResponse _emptyScoreResponse() => _scoreResponse([]);

  _MtleEvaluation _evaluateMtleResult(List<Map<String, dynamic>> answers) {
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

  int? _readInt(dynamic value) {
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
}

class _SubjectScore {
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
