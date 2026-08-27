import 'dart:math';

import 'package:achievia/core/utils/guards.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/quiz/mockboards_paused_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
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
  Future<MockboardsPausedDto> upsertPaused(MockboardsPausedDto dto);
  Future<MockboardsPausedDto> getCurrentPaused(MockboardsPausedDto dto);
  Future<List<ExaminationResult>> getRecentAttemptResults();
}

@lazySingleton
@injectable
class QuestionsRemoteDatasource implements QuestionRepoDataSource {
  final SupabaseUserContext userContext;
  List<QuizDtoItems> _generatedQuiz = const [];

  QuestionsRemoteDatasource({this.userContext = const SupabaseUserContext()});

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
          .map((json) => QuestionsDto.fromJson(normalizeSubject(json)))
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

      final questionId = readInt(question['id']) ?? 0;
      final quizId = readInt(question['quiz_id']) ?? 0;
      final choices = await getChoicesForQuestion(questionId);

      return QotdDto.fromJson({
        'quizId': quizId,
        'id': questionId,
        'title': await getQuizTitle(quizId),
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

      final questionId = readInt(choice['question_id']);
      if (questionId == null) return answerDto;

      final question = await _supabase
          .from('questions')
          .select('quiz_id')
          .eq('id', questionId)
          .maybeSingle();
      final quizId = readInt(question?['quiz_id']);
      final subjectName = quizId == null ? '' : await getQuizTitle(quizId);
      final userId = answerDto.student_id.isEmpty
          ? await userContext.currentUserId()
          : answerDto.student_id;
      if (quizId != null) {
        await _supabase.from('qotd_answers').insert({
          'user_id': userId,
          'question_id': questionId,
          'quiz_id': quizId,
          'choice_id': readInt(choice['id']),
          'is_correct': choice['is_correct'] == true,
        });
      }
      recordAnswer(subjectName, choice['is_correct'] == true);

      return answerDto;
    } catch (e) {
      debugPrint("Exception: $e");
      return QotdDtoPost(chosen_answer: '', quiz_id: 0, student_id: '');
    }
  }

  @override
  Future<List<QuestionsDto>> randomizeQuestion(int index) async {
    try {
      subjectScores.clear();

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
      final quizItems = await buildQuizItems(selectedSubjects);
      final questions = selectedSubjects
          .map((subject) => QuestionsDto.fromJson(normalizeSubject(subject)))
          .toList();

      debugPrint(
        'Quiz Titles: ${quizItems.map((quiz) => quiz.title).toList()}',
        wrapWidth: 1024,
      );
      _generatedQuiz = List<QuizDtoItems>.unmodifiable(quizItems);
      return questions;
    } catch (e) {
      debugPrint("Exception: $e");
      rethrow;
    }
  }

  @override
  Future<List<QuizDtoItems>> getTheGeneratedQuiz() async {
    try {
      return _generatedQuiz;
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

      if (attempt == null) return emptyScoreResponse();

      final answers = normalizeAnswers(attempt['answer']);
      return scoreResponse(answers);
    } catch (e) {
      debugPrint(e.toString());
      return emptyScoreResponse();
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
      final answers = currentAnswerPayload();
      final evaluation = evaluateMtleResult(answers);

      await _supabase.from('quiz_attempts').insert({
        'student_id': userId,
        'score': evaluation.gwa,
        'attempted_at': DateTime.now().toIso8601String(),
        'answer': answers,
        'no_of_attempt': attemptNumber,
        'summary': answers,
      });

      subjectScores.clear();
      debugPrint('from datasource: $attemptNumber');
      return attemptNumber;
    } catch (e) {
      debugPrint("Exception: $e");
      return 0;
    }
  }

  @override
  Future<MockboardsPausedDto> upsertPaused(MockboardsPausedDto dto) async {
    try {
      final id = await guardFunction();
      final response = await _supabase
          .from('mockboards_paused')
          .upsert({...dto.toJson(), 'user_id': id['user_id']})
          .eq('user_id', id['user_id'])
          .maybeSingle();
      return MockboardsPausedDto.fromJson(response ?? {});
    } on PostgrestException catch (e) {
      debugPrint(e.toString());
      throw Exception(e.toString());
    }
  }

  @override
  Future<MockboardsPausedDto> getCurrentPaused(MockboardsPausedDto dto) async {
    try {
      final guard = await guardFunction();
      final response = await _supabase
          .from('mockboards_paused')
          .select('*')
          .eq('user_id', guard['user_id'])
          .maybeSingle();
      if (response!.isEmpty) {
        return MockboardsPausedDto.fromJson({});
      }
      return MockboardsPausedDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<List<ExaminationResult>> getRecentAttemptResults() async {
    final userId = await userContext.currentUserId();
    final rows = await _supabase
        .from('quiz_attempts')
        .select('score, attempted_at, no_of_attempt')
        .eq('student_id', userId)
        .order('attempted_at', ascending: false);
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final attemptNo = readInt(data['no_of_attempt']);
      return ExaminationResult(
        examName: attemptNo == null ? 'Mock Board' : 'Mock Board $attemptNo',
        date: data['attempted_at']?.toString() ?? '',
        score: double.tryParse(data['score'].toString()) ?? 0,
        passingScore: 75,
      );
    }).toList();
  }
}
