import 'dart:math';

import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class QuestionBankDataSource {
  Future<List<QuestionBankSubject>> getAllSubjects();

  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId);

  Future<List<QuestionBankTopic>> getTopics(int subjectId);

  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  });

  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  });

  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5});
}

class QuestionBankRemoteDatasource implements QuestionBankDataSource {
  final SupabaseClient? _client;
  final SupabaseUserContext userContext;

  QuestionBankRemoteDatasource({
    SupabaseClient? client,
    this.userContext = const SupabaseUserContext(),
  }) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async {
    final rows = await _supabase
        .from('subjects')
        .select('id, title, course_id, description, image')
        .order('title');

    return _subjectsFromRows(rows);
  }

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async {
    final rows = await _supabase
        .from('subjects')
        .select('id, title, course_id, description, image')
        .eq('course_id', courseId)
        .order('title');

    return _subjectsFromRows(rows, fallbackCourseId: courseId);
  }

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async {
    final rows = await _supabase
        .from('quizzes')
        .select('id, title, subject_id, description')
        .eq('subject_id', subjectId)
        .order('title');

    return rows
        .map(
          (row) => QuestionBankTopic(
            id: _readInt(row['id']) ?? 0,
            subjectId: _readInt(row['subject_id']) ?? subjectId,
            title: (row['title'] ?? '').toString(),
            description: (row['description'] ?? '').toString(),
          ),
        )
        .toList();
  }

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async {
    final rows = await _supabase
        .from('questions')
        .select('id, quiz_id, question_text')
        .eq('quiz_id', quizId);
    final questionRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    final questionIds = questionRows
        .map((row) => _readInt(row['id']))
        .whereType<int>()
        .toList();

    if (questionIds.isEmpty) return [];

    final choiceResponse = await _supabase
        .from('choices')
        .select('id, question_id, choice_text, is_correct')
        .inFilter('question_id', questionIds)
        .order('id');
    final choiceRows = choiceResponse
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    return buildQuestionBankPracticeQuestions(
      questionRows: questionRows,
      choiceRows: choiceRows,
      limit: limit,
      random: random,
    );
  }

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final userId = await userContext.currentUserId();
    final score = questionBankScore(
      correct: correctAnswers,
      total: totalQuestions,
    );
    final row = await _supabase
        .from('question_bank_attempts')
        .insert({
          'user_id': userId,
          'subject_id': selection.subject.id,
          'quiz_id': selection.topic.id,
          'correct_answers': correctAnswers,
          'total_questions': totalQuestions,
          'score': score,
        })
        .select(
          'id, user_id, subject_id, quiz_id, correct_answers, total_questions, score, completed_at',
        )
        .single();

    return _attemptFromRow(
      row,
      subjectTitle: selection.subject.title,
      topicTitle: selection.topic.title,
    );
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5}) async {
    final userId = await userContext.currentUserId();
    final rows = await _supabase
        .from('question_bank_attempts')
        .select(
          'id, user_id, subject_id, quiz_id, correct_answers, total_questions, score, completed_at, subjects(title), quizzes(title)',
        )
        .eq('user_id', userId)
        .order('completed_at', ascending: false)
        .limit(limit);

    return rows
        .map(
          (row) => _attemptFromRow(
            row,
            subjectTitle: _relatedTitle(row['subjects'], 'Unknown subject'),
            topicTitle: _relatedTitle(row['quizzes'], 'Unknown topic'),
          ),
        )
        .toList();
  }
}

List<QuestionBankSubject> _subjectsFromRows(
  List<Map<String, dynamic>> rows, {
  int fallbackCourseId = 0,
}) {
  return rows
      .map(
        (row) => QuestionBankSubject(
          id: _readInt(row['id']) ?? 0,
          courseId: _readInt(row['course_id']) ?? fallbackCourseId,
          title: (row['title'] ?? '').toString(),
          description: normalizeQuestionBankOptionalText(row['description']),
          image: (row['image'] ?? '').toString(),
        ),
      )
      .toList();
}

QuestionBankAttempt _attemptFromRow(
  Map<String, dynamic> row, {
  required String subjectTitle,
  required String topicTitle,
}) {
  return QuestionBankAttempt(
    id: (row['id'] ?? '').toString(),
    userId: (row['user_id'] ?? '').toString(),
    subjectId: _readInt(row['subject_id']) ?? 0,
    topicId: _readInt(row['quiz_id']) ?? 0,
    subjectTitle: subjectTitle,
    topicTitle: topicTitle,
    correctAnswers: _readInt(row['correct_answers']) ?? 0,
    totalQuestions: _readInt(row['total_questions']) ?? 0,
    score: _readDouble(row['score']),
    completedAt:
        DateTime.tryParse((row['completed_at'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

String _relatedTitle(dynamic relation, String fallback) {
  if (relation is Map && relation['title'] != null) {
    return relation['title'].toString();
  }
  if (relation is List && relation.isNotEmpty && relation.first is Map) {
    final title = (relation.first as Map)['title'];
    if (title != null) return title.toString();
  }
  return fallback;
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
