import 'dart:math';

import 'package:achievia/core/utils/alphabetical.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/core/utils/study_questions_builder.dart';
import 'package:achievia/data/data_source/soft_delete_columns.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:flutter/foundation.dart';
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

  /// Random distinct questions from every subtopic of [subjectId]. Returns
  /// fewer than [count] when the subject does not have enough usable ones.
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = subjectExamQuestionCount,
    Random? random,
  });

  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  });

  Future<ExamAttemptSummary> getExamSummary(String attemptId);

  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  });
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
    final rows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'subjects',
      'id, title, course_id, description, image',
    )).order('title', ascending: true);

    return subjectsFromRows(rows);
  }

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async {
    final rows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'subjects',
      'id, title, course_id, description, image',
    )).eq('course_id', courseId).order('title', ascending: true);

    return subjectsFromRows(rows, fallbackCourseId: courseId);
  }

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async {
    final rows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'quizzes',
      'id, title, subject_id, description',
    )).eq('subject_id', subjectId).order('title', ascending: true);

    return topicsFromRows(rows, subjectId);
  }

  /// A subtopic is readable while it exists and is not soft-deleted. Content
  /// reads go through [SoftDeleteColumns.liveSelect], which applies
  /// `deleted_at IS NULL` wherever the column exists.
  Future<bool> _isQuizLive(int quizId) async {
    final row = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'quizzes',
      'id',
    )).eq('id', quizId).maybeSingle();
    return row != null;
  }

  Future<bool> _isSubjectLive(int subjectId) async {
    final row = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'subjects',
      'id',
    )).eq('id', subjectId).maybeSingle();
    return row != null;
  }

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async {
    if (!await _isQuizLive(quizId)) return [];
    // Paged: a single response is capped by the API, and truncated choices
    // would silently turn questions into ones with missing options.
    final (questionRows, choiceRows) = await _fetchQuizRows(quizId);
    if (questionRows.isEmpty) return [];

    return buildQuestionBankPracticeQuestions(
      questionRows: questionRows,
      choiceRows: choiceRows,
      limit: limit,
      random: random,
    );
  }

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  _fetchQuizRows(int quizId) async {
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = await (await SoftDeleteColumns.liveSelect(
        _supabase,
        'questions',
        '*',
      )).eq('quiz_id', quizId).order('id').range(from, from + pageSize - 1);
      rows.addAll(page.map((r) => Map<String, dynamic>.from(r)));
      if (page.length < pageSize) break;
    }
    final questionRows = scopeQuestionRows(rows, quizId);
    final ids = [
      for (final row in questionRows)
        if (_readInt(row['id']) != null) _readInt(row['id'])!,
    ];
    final choices = <Map<String, dynamic>>[];
    for (var start = 0; start < ids.length; start += 150) {
      final chunk = ids.sublist(start, min(start + 150, ids.length));
      for (var from = 0; ; from += pageSize) {
        final page =
            await (await SoftDeleteColumns.liveSelect(
                  _supabase,
                  'choices',
                  'id, question_id, choice_text, is_correct',
                ))
                .inFilter('question_id', chunk)
                .order('id')
                .range(from, from + pageSize - 1);
        choices.addAll(page.map((r) => Map<String, dynamic>.from(r)));
        if (page.length < pageSize) break;
      }
    }
    return (questionRows, choices);
  }

  /// All eligible questions of one subtopic for Study Mode (no sampling, no
  /// limit). Uses `select('*')` so `questions.rationale` is read when present.
  Future<List<QuestionItemEntity>> getStudyQuestions(int quizId) async {
    // Both queries are paged: the API caps a single response, and a silently
    // truncated choices page would make whole questions look unusable.
    if (!await _isQuizLive(quizId)) return [];
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = await (await SoftDeleteColumns.liveSelect(
        _supabase,
        'questions',
        '*',
      )).eq('quiz_id', quizId).order('id').range(from, from + pageSize - 1);
      rows.addAll(page.map((r) => Map<String, dynamic>.from(r)));
      if (page.length < pageSize) break;
    }
    final questionRows = scopeQuestionRows(rows, quizId);
    final ids = [
      for (final row in questionRows)
        if (_readInt(row['id']) != null) _readInt(row['id'])!,
    ];
    if (ids.isEmpty) return [];
    final choices = <Map<String, dynamic>>[];
    // Chunked so the id list never blows past URL length limits.
    for (var start = 0; start < ids.length; start += 150) {
      final chunk = ids.sublist(start, min(start + 150, ids.length));
      for (var from = 0; ; from += pageSize) {
        final page =
            await (await SoftDeleteColumns.liveSelect(
                  _supabase,
                  'choices',
                  'id, question_id, choice_text, is_correct',
                ))
                .inFilter('question_id', chunk)
                .order('id')
                .range(from, from + pageSize - 1);
        choices.addAll(page.map((r) => Map<String, dynamic>.from(r)));
        if (page.length < pageSize) break;
      }
    }
    return buildStudyQuestions(questionRows: questionRows, choiceRows: choices);
  }

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = subjectExamQuestionCount,
    Random? random,
  }) async {
    if (!await _isSubjectLive(subjectId)) return [];
    final quizRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'quizzes',
      'id',
    )).eq('subject_id', subjectId);
    final quizIds = quizRows
        .map((row) => _readInt(row['id']))
        .whereType<int>()
        .toList();
    if (quizIds.isEmpty) return [];

    final candidateIds = <int>[];
    const pageSize = 1000;
    for (var from = 0; ; from += pageSize) {
      final page =
          await (await SoftDeleteColumns.liveSelect(
                _supabase,
                'questions',
                'id',
              ))
              .inFilter('quiz_id', quizIds)
              .order('id')
              .range(from, from + pageSize - 1);
      candidateIds.addAll(
        page.map((row) => _readInt(row['id'])).whereType<int>(),
      );
      if (page.length < pageSize) break;
    }

    return assembleExamQuestions(
      candidateIds: candidateIds,
      count: count,
      random: random,
      loadUsable: _loadUsableQuestions,
    );
  }

  Future<List<QuestionItemEntity>> _loadUsableQuestions(List<int> ids) async {
    final questionRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'questions',
      '*',
    )).inFilter('id', ids);
    final choiceRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'choices',
      'id, question_id, choice_text, is_correct',
    )).inFilter('question_id', ids).order('id');
    return buildQuestionBankPracticeQuestions(
      questionRows: questionRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      choiceRows: choiceRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      limit: ids.length,
    );
  }

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  }) async {
    if (selection.isSubjectExam && snapshot != null) {
      final persisted = await _saveExamWithSnapshot(selection, snapshot);
      if (persisted != null) return persisted;
      // The snapshot function is not deployed (migration not applied): keep
      // saving the score so results still work. No summary is persisted.
    }
    final userId = await userContext.currentUserId();
    final score = questionBankScore(
      correct: correctAnswers,
      total: totalQuestions,
    );
    final Map<String, dynamic> row;
    try {
      row = await _supabase
          .from('question_bank_attempts')
          .insert({
            'user_id': userId,
            'subject_id': selection.subject.id,
            'quiz_id': selection.topic?.id,
            'attempt_type': selection.attemptType,
            'correct_answers': correctAnswers,
            'total_questions': totalQuestions,
            'score': score,
          })
          .select(_attemptColumns)
          .single();
    } on PostgrestException catch (error) {
      // Exam attempts are server-authoritative: a refused direct insert means
      // this incomplete exam is simply not recorded, never a crash.
      if (error.code != '42501' || !selection.isSubjectExam) rethrow;
      debugPrint('Incomplete exam not recorded: ${error.code}');
      return QuestionBankAttempt(
        id: '',
        userId: userId,
        subjectId: selection.subject.id,
        topicId: null,
        subjectTitle: selection.subject.title,
        topicTitle: subjectExamTitle,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        score: score,
        completedAt: DateTime.now().toUtc(),
        attemptType: selection.attemptType,
        hasSummary: false,
      );
    }

    return _attemptFromRow(
      row,
      subjectTitle: selection.subject.title,
      topicTitle: selection.topic?.title ?? subjectExamTitle,
    );
  }

  /// Saves the attempt and all item snapshots atomically through the
  /// `save_subject_exam_attempt` function; the session id makes it idempotent.
  /// Returns null when that function does not exist yet, or when the exam is
  /// not a complete 100-item exam (saved score-only instead).
  Future<QuestionBankAttempt?> _saveExamWithSnapshot(
    QuestionBankSelection selection,
    ExamAttemptSnapshot snapshot,
  ) async {
    // The server only accepts a complete 100-item exam. A smaller exam (the
    // subject has fewer usable questions) is saved score-only, by design.
    if (snapshot.items.length != subjectExamQuestionCount) return null;
    try {
      final id = await _supabase.rpc(
        'save_subject_exam_attempt',
        params: {
          'p_subject_id': selection.subject.id,
          'p_client_attempt_id': snapshot.clientAttemptId,
          'p_items': [for (final i in snapshot.items) i.toRpcJson()],
        },
      );
      final row = await _supabase
          .from('question_bank_attempts')
          .select(_attemptColumns)
          .eq('id', id.toString())
          .single();
      return _attemptFromRow(
        row,
        subjectTitle: selection.subject.title,
        topicTitle: subjectExamTitle,
        hasSummary: true,
      );
    } on PostgrestException catch (error) {
      if (isSnapshotFunctionMissing(error)) {
        debugPrint('Exam summary storage is not available: ${error.code}');
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ExamAttemptSummary> getExamSummary(String attemptId) async {
    if (!isValidExamAttemptId(attemptId)) {
      throw const ExamSummaryException(ExamSummaryFailure.invalidId);
    }
    try {
      return await _loadExamSummary(attemptId);
    } on PostgrestException catch (error) {
      debugPrint('Exam summary query failed: ${error.code}');
      final failure = examSummaryFailureFor(error);
      if (failure != null) throw ExamSummaryException(failure);
      rethrow;
    }
  }

  Future<ExamAttemptSummary> _loadExamSummary(String attemptId) async {
    // Row level security limits both queries to the signed-in user's own rows.
    final attempt = await _supabase
        .from('question_bank_attempts')
        .select('id, correct_answers, total_questions, attempt_type')
        .eq('id', attemptId)
        .maybeSingle();
    if (attempt == null) {
      throw const ExamSummaryException(ExamSummaryFailure.notFound);
    }
    final rows = await _supabase
        .from('question_bank_attempt_items')
        // `*` so the image_path / rationale kept in the snapshot (patch
        // 20261020) are read where they exist without breaking older schemas.
        .select('*')
        .eq('attempt_id', attemptId)
        .order('position', ascending: true);
    if (rows.isEmpty) {
      throw const ExamSummaryException(ExamSummaryFailure.unavailable);
    }
    final summary = examSummaryFromRows(
      attemptId: attemptId,
      rows: rows,
      savedCorrect: _readInt(attempt['correct_answers']) ?? -1,
      savedTotal: _readInt(attempt['total_questions']) ?? -1,
      requiredCount:
          attempt['attempt_type'] == QuestionBankAttempt.subjectExamType
          ? subjectExamQuestionCount
          : null,
    );
    return _withQuestionExtras(summary);
  }

  /// Items whose snapshot has no attachment or rationale (saved before patch
  /// 20261020) get them from the question itself (by id). What the snapshot
  /// kept always wins. A failure here never hides the summary: the items just
  /// show without them.
  Future<ExamAttemptSummary> _withQuestionExtras(
    ExamAttemptSummary summary,
  ) async {
    final ids = [
      for (final item in summary.items)
        if (item.questionId != null &&
            (item.imagePath.isEmpty || item.rationale.isEmpty))
          item.questionId!,
    ];
    if (ids.isEmpty) return summary;
    try {
      final extras = <int, Map<String, dynamic>>{};
      for (var start = 0; start < ids.length; start += 150) {
        final chunk = ids.sublist(start, min(start + 150, ids.length));
        final rows = await _supabase
            .from('questions')
            .select('*')
            .inFilter('id', chunk);
        for (final row in rows) {
          final id = _readInt(row['id']);
          if (id != null) extras[id] = Map<String, dynamic>.from(row);
        }
      }
      return ExamAttemptSummary(
        attemptId: summary.attemptId,
        items: [
          for (final item in summary.items)
            if (extras[item.questionId] case final row?)
              item.withExtras(
                imagePath: item.imagePath.isNotEmpty
                    ? item.imagePath
                    : _cleanText(row['image_path']),
                rationale: item.rationale.isNotEmpty
                    ? item.rationale
                    : _cleanText(row['rationale'], row['correct_description']),
              )
            else
              item,
        ],
      );
    } catch (error) {
      debugPrint('Exam summary extras unavailable: $error');
      return summary;
    }
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async {
    final userId = await userContext.currentUserId();
    var query = _supabase
        .from('question_bank_attempts')
        .select(
          'id, user_id, subject_id, quiz_id, correct_answers, total_questions, score, completed_at, attempt_type, client_attempt_id, subjects(title), quizzes(title)',
        )
        .eq('user_id', userId);
    // Filter first, then order and limit, so other attempt types can never
    // crowd valid results out of the window.
    if (attemptType != null) query = query.eq('attempt_type', attemptType);
    final rows = await query
        .order('completed_at', ascending: false)
        .limit(limit);

    return rows
        .map(
          (row) => _attemptFromRow(
            row,
            subjectTitle: _relatedTitle(row['subjects'], 'Unknown subject'),
            topicTitle:
                row['attempt_type'] == QuestionBankAttempt.subjectExamType
                ? subjectExamTitle
                : _relatedTitle(row['quizzes'], 'Unknown topic'),
          ),
        )
        .toList();
  }
}

/// Topics (quizzes) of exactly [subjectId]; the query already filters by
/// subject, this guards against any row of another subject slipping through.
List<QuestionBankTopic> topicsFromRows(
  List<Map<String, dynamic>> rows,
  int subjectId,
) {
  return rows
      .where((row) => _readInt(row['subject_id']) == subjectId)
      .map(
        (row) => QuestionBankTopic(
          id: _readInt(row['id']) ?? 0,
          subjectId: subjectId,
          title: (row['title'] ?? '').toString(),
          description: (row['description'] ?? '').toString(),
        ),
      )
      .toList()
    // A-Z by title, case-insensitive (the database collation may differ).
    ..sort(
      (a, b) => compareTitlesAlphabetically(
        a.title,
        b.title,
        tieBreakA: a.id,
        tieBreakB: b.id,
      ),
    );
}

/// Questions of exactly [quizId] (a quiz belongs to a single subject).
List<Map<String, dynamic>> scopeQuestionRows(
  List<Map<String, dynamic>> rows,
  int quizId,
) {
  return rows
      .where((row) => _readInt(row['quiz_id']) == quizId)
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

/// Subjects of the Question Bank, A-Z by title.
List<QuestionBankSubject> subjectsFromRows(
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
      .toList()
    // A-Z by title, case-insensitive (the database collation may differ).
    ..sort(
      (a, b) => compareTitlesAlphabetically(
        a.title,
        b.title,
        tieBreakA: a.id,
        tieBreakB: b.id,
      ),
    );
}

const subjectExamTitle = 'Subject Exam';

/// First value holding real text (not null, empty or the literal "null").
String _cleanText(Object? first, [Object? second]) {
  for (final value in [first, second]) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

/// Maps backend errors that mean a permanent answer (not found / access
/// denied) to a summary failure; other errors (network, server) stay generic
/// load errors so the screen offers Retry.
ExamSummaryFailure? examSummaryFailureFor(PostgrestException error) {
  switch (error.code) {
    case '42501':
    case 'PGRST301':
      return ExamSummaryFailure.denied;
    case '22P02': // malformed uuid reached the database
      return ExamSummaryFailure.notFound;
  }
  return null;
}

/// True only when the error clearly says the snapshot function is not
/// deployed. Permission, RLS, network, validation and any other server error
/// must stay real errors, never a silent score-only fallback.
bool isSnapshotFunctionMissing(PostgrestException error) {
  if (error.code == 'PGRST202') return true;
  return error.code == '42883' &&
      error.message.contains('save_subject_exam_attempt');
}

const _attemptColumns =
    'id, user_id, subject_id, quiz_id, correct_answers, total_questions, score, completed_at, attempt_type';

/// Parses persisted item rows into a validated summary. Any inconsistency
/// (count, order, duplicates, malformed snapshot, score mismatch) throws
/// [ExamSummaryException] instead of showing partial or mismatched data.
ExamAttemptSummary examSummaryFromRows({
  required String attemptId,
  required List<Map<String, dynamic>> rows,
  required int savedCorrect,
  required int savedTotal,
  int? requiredCount,
}) {
  // A persisted subject exam always has exactly [requiredCount] items; fewer
  // rows mean an incomplete snapshot, which is never shown as if it were valid.
  if (requiredCount != null && rows.length != requiredCount) {
    throw ExamSummaryException(ExamSummaryFailure.malformed, [
      'Expected $requiredCount items but found ${rows.length}.',
    ]);
  }
  // Never rely on the query's order (supabase `order` defaults to descending):
  // the summary always reads 1..N.
  rows = [...rows]
    ..sort(
      (a, b) => (_readInt(a['position']) ?? 0).compareTo(
        _readInt(b['position']) ?? 0,
      ),
    );
  final items = <ExamSummaryItem>[];
  try {
    for (final row in rows) {
      final rawChoices = row['choices_snapshot'];
      if (rawChoices is! List) throw const FormatException('choices');
      final choices = [
        for (final c in rawChoices)
          ExamSummaryChoice(
            id: _readInt((c as Map)['id']),
            text: c['text'].toString(),
            isCorrect: c['is_correct'] == true,
          ),
      ];
      items.add(
        ExamSummaryItem(
          position: _readInt(row['position']) ?? 0,
          questionId: _readInt(row['question_id']),
          questionText: (row['question_text'] ?? '').toString(),
          choices: choices,
          selectedIndex: _readInt(row['selected_index']),
          correctIndex: _readInt(row['correct_index']) ?? -1,
          imagePath: _cleanText(row['image_path']),
          rationale: _cleanText(row['rationale']),
        ),
      );
    }
  } catch (_) {
    throw const ExamSummaryException(ExamSummaryFailure.malformed, [
      'An item could not be read.',
    ]);
  }
  final issues = ExamSummaryValidator.validate(
    items,
    savedCorrect: savedCorrect,
    savedTotal: savedTotal,
  );
  if (issues.isNotEmpty) {
    throw ExamSummaryException(ExamSummaryFailure.malformed, issues);
  }
  return ExamAttemptSummary(attemptId: attemptId, items: items);
}

QuestionBankAttempt _attemptFromRow(
  Map<String, dynamic> row, {
  required String subjectTitle,
  required String topicTitle,
  bool? hasSummary,
}) {
  return QuestionBankAttempt(
    id: (row['id'] ?? '').toString(),
    userId: (row['user_id'] ?? '').toString(),
    subjectId: _readInt(row['subject_id']) ?? 0,
    topicId: _readInt(row['quiz_id']),
    subjectTitle: subjectTitle,
    topicTitle: topicTitle,
    correctAnswers: _readInt(row['correct_answers']) ?? 0,
    totalQuestions: _readInt(row['total_questions']) ?? 0,
    score: _readDouble(row['score']),
    completedAt:
        DateTime.tryParse((row['completed_at'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    attemptType:
        row['attempt_type']?.toString() ?? QuestionBankAttempt.practiceType,
    hasSummary: hasSummary ?? row['client_attempt_id'] != null,
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
