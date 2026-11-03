import 'package:achievia/core/utils/guards.dart';
import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/core/utils/question_eligibility.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/core/utils/recent_results.dart' show examHistoryLimit;
import 'package:achievia/data/data_source/soft_delete_columns.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/quiz/mockboards_paused_dto.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart'
    show newClientAttemptId;
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class QuestionRepoDataSource {
  Future<List<QuestionsDto>> getAllQuestions();
  Future<List<QotdSubject>> getSubjects();
  Future<Set<int>> getSubjectIdsWithQuestions();
  Future<List<int>> getLiveQuestionIds(int subjectId);
  Future<Set<int>> filterEligibleQuestionIds(List<int> ids);
  Future<QotdDailyQuestion> getQuestion(int questionId);
  Future<QotdUserAnswer?> getTodaysAnswer({
    required int questionId,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  });
  Future<void> submitAnswer({
    required String userId,
    required int questionId,
    required int quizId,
    required int choiceId,
    required bool isCorrect,
  });
  Future<List<QuizDtoItems>> getTheGeneratedQuiz();

  /// Asks the server to record when the board started. Returns false when
  /// the start could not be recorded (offline, patch not deployed, ...).
  Future<bool> startMockBoardAttempt();

  /// The board in progress and its attempt ids, so it can be kept on the
  /// device; null when no board was generated.
  MockBoardSession? exportMockBoardSession();

  /// Makes a previously exported board the one in progress again (the exam is
  /// continued, not regenerated). Answers are restored by the caller.
  void restoreMockBoardSession(MockBoardSession session);
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
  final SupabaseClient? _client;
  final MockBoardSource? _mockBoardSource;
  List<QuizDtoItems> _generatedQuiz = const [];

  /// Bumped whenever a board generation starts. A generation that finishes
  /// after a newer one began (for example one the caller already gave up on
  /// after a timeout) must not replace the newer board.
  int _generation = 0;

  /// Idempotency key of the board in progress. The server returns the first
  /// saved attempt for a repeated key, so a retry can never double-submit.
  String _clientAttemptId = newClientAttemptId();

  /// The attempt id for which the server was already asked to record the
  /// start of the board (so it is requested once per board).
  String? _startedAttemptId;

  QuestionsRemoteDatasource({
    this.userContext = const SupabaseUserContext(),
    @ignoreParam SupabaseClient? client,
    @ignoreParam MockBoardSource? mockBoardSource,
  }) : _client = client,
       _mockBoardSource = mockBoardSource;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @visibleForTesting
  void seedGeneratedQuiz(List<QuizDtoItems> sections) {
    _generatedQuiz = List<QuizDtoItems>.unmodifiable(sections);
  }

  @override
  Future<List<QuestionsDto>> getAllQuestions() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        throw Exception("Session Expired");
      }
      final response = await (await SoftDeleteColumns.liveSelect(
        _supabase,
        'subjects',
        'id, title, course_id, description, image, day_subject, created_at',
      )).order('created_at');

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
  Future<List<QotdSubject>> getSubjects() async {
    final response = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'subjects',
      'id, title',
    )).order('created_at').order('id');
    return response.map((row) {
      return QotdSubject(
        id: readInt(row['id']) ?? 0,
        title: row['title']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<Set<int>> getSubjectIdsWithQuestions() async {
    // One row per live subtopic with at most one live question embedded: the
    // payload is the number of subtopics, not the size of the Question Bank.
    const pageSize = 1000;
    final subjectIds = <int>{};
    for (var from = 0; ; from += pageSize) {
      final quizzes = await SoftDeleteColumns.liveSelect(
        _supabase,
        'quizzes',
        'id, subject_id, questions(id)',
      );
      // Soft-deleted questions must not make a subject look like it has some.
      final page = await quizzes
          .isFilter('questions.deleted_at', null)
          .limit(1, referencedTable: 'questions')
          .order('id')
          .range(from, from + pageSize - 1);
      for (final quiz in page) {
        final subjectId = readInt(quiz['subject_id']);
        final questions = quiz['questions'];
        if (subjectId != null && questions is List && questions.isNotEmpty) {
          subjectIds.add(subjectId);
        }
      }
      if (page.length < pageSize) break;
    }
    return subjectIds;
  }

  @override
  Future<List<int>> getLiveQuestionIds(int subjectId) async {
    final quizRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'quizzes',
      'id',
    )).eq('subject_id', subjectId);
    final quizIds = quizRows
        .map((row) => readInt(row['id']))
        .whereType<int>()
        .toList();
    if (quizIds.isEmpty) return const [];
    const pageSize = 1000;
    final ids = <int>[];
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
      ids.addAll(page.map((row) => readInt(row['id'])).whereType<int>());
      if (page.length < pageSize) break;
    }
    return ids;
  }

  Future<int?> getDailyQuestionId(int subjectId, DateTime now) async {
    final quizzes = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'quizzes',
      'id',
    )).eq('subject_id', subjectId);
    final quizIds = quizzes
        .map((row) => readInt(row['id']))
        .whereType<int>()
        .toList();
    if (quizIds.isEmpty) return null;
    // Counted over live questions only, so it matches the live pages below.
    final count = await _supabase
        .from('questions')
        .count(CountOption.exact)
        .inFilter('quiz_id', quizIds)
        .isFilter('deleted_at', null);
    return QuestionOfTheDayPicker.pickEligibleQuestionIdPaged(
      now: now,
      questionCount: count,
      loadPage: (start, size) async {
        final rows =
            await (await SoftDeleteColumns.liveSelect(
                  _supabase,
                  'questions',
                  'id',
                ))
                .inFilter('quiz_id', quizIds)
                .order('id')
                .range(start, start + size - 1);
        final ids = rows
            .map((row) => readInt(row['id']))
            .whereType<int>()
            .toList();
        if (ids.isEmpty) return [];
        // Deployed databases may not expose a choices -> questions foreign
        // key to PostgREST, so use a separate bounded query instead of an embed.
        final choices = await (await SoftDeleteColumns.liveSelect(
          _supabase,
          'choices',
          'id, question_id, is_correct',
        )).inFilter('question_id', ids);
        final valid = validQuestionIdsFromChoices(
          choices.map((row) => Map<String, dynamic>.from(row)),
          minChoices: 2,
        );
        return [
          for (final row in rows)
            if (readInt(row['id']) case final int id)
              (id: id, eligible: valid.contains(id)),
        ];
      },
    );
  }

  @override
  Future<Set<int>> filterEligibleQuestionIds(List<int> ids) async {
    if (ids.isEmpty) return const {};
    final questionRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'questions',
      'id',
    )).inFilter('id', ids);
    final live = questionRows
        .map((row) => readInt(row['id']))
        .whereType<int>()
        .toSet();
    if (live.isEmpty) return const {};
    final choiceRows = await (await SoftDeleteColumns.liveSelect(
      _supabase,
      'choices',
      'id, question_id, is_correct',
    )).inFilter('question_id', live.toList());
    final valid = validQuestionIdsFromChoices(
      choiceRows.map((row) => Map<String, dynamic>.from(row)),
      minChoices: 2,
    );
    return live.intersection(valid);
  }

  @override
  Future<QotdDailyQuestion> getQuestion(int questionId) async {
    // The question and its choices are independent: fetch them together.
    final (row, choicesRows) = await (
      (await SoftDeleteColumns.liveSelect(
        _supabase,
        'questions',
        '*',
      )).eq('id', questionId).maybeSingle(),
      (await SoftDeleteColumns.liveSelect(
        _supabase,
        'choices',
        'id, choice_text, is_correct',
      )).eq('question_id', questionId).order('id'),
    ).wait;
    if (row == null) {
      throw StateError('Daily question $questionId was not found');
    }
    String explanation(Object? value) {
      final text = value?.toString().trim() ?? '';
      final plain = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .trim()
          .toLowerCase();
      return plain.isEmpty || plain == 'null' ? '' : text;
    }

    final rationale = explanation(row['rationale']);
    return QotdDailyQuestion(
      questionId: readInt(row['id']) ?? questionId,
      quizId: readInt(row['quiz_id']) ?? 0,
      questionText: row['question_text']?.toString() ?? '',
      imagePath: (row['image_path'] ?? '').toString().trim(),
      rationale: rationale.isNotEmpty
          ? rationale
          : explanation(row['correct_description']),
      choices: choicesRows.map((choice) {
        return QotdChoice(
          id: readInt(choice['id']) ?? 0,
          text: choice['choice_text']?.toString() ?? '',
          isCorrect: choice['is_correct'] == true,
        );
      }).toList(),
    );
  }

  @override
  Future<QotdUserAnswer?> getTodaysAnswer({
    required int questionId,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  }) async {
    final userId = await userContext.currentUserId();
    final row = await _supabase
        .from('qotd_answers')
        .select('choice_id, is_correct, answered_at')
        .eq('user_id', userId)
        .eq('question_id', questionId)
        .gte('answered_at', dayStartUtc.toUtc().toIso8601String())
        .lt('answered_at', dayEndUtc.toUtc().toIso8601String())
        .order('answered_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return QotdUserAnswer(
      choiceId: readInt(row['choice_id']) ?? 0,
      isCorrect: row['is_correct'] == true,
      answeredAt:
          DateTime.tryParse(row['answered_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<void> submitAnswer({
    required String userId,
    required int questionId,
    required int quizId,
    required int choiceId,
    required bool isCorrect,
  }) async {
    try {
      await _supabase.from('qotd_answers').insert({
        'user_id': userId,
        'question_id': questionId,
        'quiz_id': quizId,
        'choice_id': choiceId,
        'is_correct': isCorrect,
      });
    } on PostgrestException catch (error) {
      // Already answered today (unique violation): the first answer stands.
      if (error.code != '23505') rethrow;
    }
  }

  @override
  Future<List<QuestionsDto>> randomizeQuestion(int index) async {
    final generation = ++_generation;
    try {
      resetMockBoardAnswers();
      _generatedQuiz = const [];
      _clientAttemptId = newClientAttemptId();

      // `*` so mock_board_pool_count is read where it exists without
      // breaking projects that have not added the column yet.
      final response = await (await SoftDeleteColumns.liveSelect(
        _supabase,
        'subjects',
        '*',
      )).order('created_at');
      final subjects = response
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final selectedSubjects = selectMockBoardSubjects(subjects);
      if (selectedSubjects.isEmpty) {
        throw MockBoardException(
          MockBoardFailure.notConfigured,
          'No Mock Board subjects are available',
        );
      }
      final quizItems = await loadMockBoardQuizItems(
        selectedSubjects,
        source: _mockBoardSource,
      );
      if (generation != _generation) {
        throw StateError('Mock Board generation was superseded');
      }
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

  /// Asks the server to record when this board started (called when the user
  /// presses START EXAM). Returns false when it could not be recorded; the UI
  /// then warns that the attempt is not eligible for ranking, and the server
  /// will not time verify it either.
  @override
  Future<bool> startMockBoardAttempt() async {
    final attemptId = _clientAttemptId;
    if (_startedAttemptId == attemptId) return true;
    try {
      await _supabase
          .rpc(
            'start_mock_board_attempt',
            params: {'p_client_attempt_id': attemptId},
          )
          .timeout(const Duration(seconds: 10));
      _startedAttemptId = attemptId;
      return true;
    } on PostgrestException catch (error) {
      // Not deployed yet: the leaderboards do not require a recorded start
      // until the server patch is applied, so there is nothing to warn about.
      if (_isRpcMissing(error, 'start_mock_board_attempt')) return true;
      debugPrint('Mock Board start not recorded: $error');
      return false;
    } catch (e) {
      debugPrint('Mock Board start not recorded: $e');
      return false;
    }
  }

  @override
  MockBoardSession? exportMockBoardSession() {
    if (_generatedQuiz.isEmpty) return null;
    return MockBoardSession(
      board: [for (final section in _generatedQuiz) section.toJson()],
      clientAttemptId: _clientAttemptId,
      startedAttemptId: _startedAttemptId,
    );
  }

  @override
  void restoreMockBoardSession(MockBoardSession session) {
    // A generation still running must not replace the restored board.
    _generation++;
    resetMockBoardAnswers();
    _generatedQuiz = List<QuizDtoItems>.unmodifiable(
      session.board.map(QuizDtoItems.fromJson),
    );
    _clientAttemptId = session.clientAttemptId;
    _startedAttemptId = session.startedAttemptId;
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
      // Surface load failures: an empty response would be shown to the user as
      // a failing 0.00 grade for an exam that was actually saved.
      debugPrint(e.toString());
      rethrow;
    }
  }

  /// Submits the finished Mock Board and returns its attempt number (0 when it
  /// could not be saved).
  ///
  /// The server grades: only the chosen answers are sent, and the section
  /// scores, GWA, attempt number and timestamp are computed by
  /// `save_mock_board_attempt`. Retrying with the same board is idempotent.
  @override
  Future<int> putToAttempt() async {
    try {
      final items = mockBoardSubmissionItems(
        _generatedQuiz,
        mockBoardSelections,
      );
      int attemptNumber;
      try {
        final result = await _supabase.rpc(
          'save_mock_board_attempt',
          params: {'p_client_attempt_id': _clientAttemptId, 'p_items': items},
        );
        attemptNumber = readInt(result) ?? 0;
        if (attemptNumber <= 0) {
          throw StateError('The server returned no attempt number');
        }
      } on PostgrestException catch (error) {
        if (!isMockBoardRpcMissing(error)) rethrow;
        // Staged rollout only: the RPC is not deployed yet. Once the server
        // patch is applied clients cannot insert, so this path never writes.
        debugPrint('Server grading unavailable (${error.code}); legacy save');
        attemptNumber = await _legacyInsertAttempt();
      }

      resetMockBoardAnswers();
      _clientAttemptId = newClientAttemptId();
      debugPrint('from datasource: $attemptNumber');
      return attemptNumber;
    } catch (e) {
      debugPrint("Exception: $e");
      return 0;
    }
  }

  /// Pre-migration behaviour: the device computes and inserts the result.
  /// Kept only so an app update can ship before the database patch.
  Future<int> _legacyInsertAttempt() async {
    final userId = await userContext.currentUserId();
    // Highest existing number + 1: a row count would repeat a number after
    // any attempt was removed, and results are looked up by that number.
    final lastAttempt = await _supabase
        .from('quiz_attempts')
        .select('no_of_attempt')
        .eq('student_id', userId)
        .order('no_of_attempt', ascending: false)
        .limit(1)
        .maybeSingle();
    final attemptNumber = (readInt(lastAttempt?['no_of_attempt']) ?? 0) + 1;
    final answers = currentAnswerPayload(sections: _generatedQuiz);
    final evaluation = evaluateMtleResult(answers);

    await _supabase.from('quiz_attempts').insert({
      'student_id': userId,
      'score': evaluation.gwa,
      'attempted_at': DateTime.now().toUtc().toIso8601String(),
      'answer': answers,
      'no_of_attempt': attemptNumber,
      'summary': answers,
    });
    return attemptNumber;
  }

  /// One paused exam per user. The table has no unique key on `user_id`, so
  /// the row is updated when it exists and inserted otherwise; the client DTO
  /// is never sent as-is because its id and timestamps are empty for a new
  /// pause.
  @override
  Future<MockboardsPausedDto> upsertPaused(MockboardsPausedDto dto) async {
    try {
      final userId = (await guardFunction())['user_id'] as String;
      final existing = await _latestPausedRow(userId);
      final values = {
        'quiz_id': dto.quiz_id,
        'current_page': dto.current_page,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      final Map<String, dynamic> row;
      if (existing == null) {
        row = await _supabase
            .from('mockboards_paused')
            .insert({...values, 'user_id': userId})
            .select()
            .single();
      } else {
        row = await _supabase
            .from('mockboards_paused')
            .update(values)
            .eq('id', existing['id'])
            .select()
            .single();
      }
      return _pausedFromRow(row, userId);
    } on PostgrestException catch (e) {
      debugPrint(e.toString());
      throw Exception(e.toString());
    }
  }

  @override
  Future<MockboardsPausedDto> getCurrentPaused(MockboardsPausedDto dto) async {
    try {
      final userId = (await guardFunction())['user_id'] as String;
      final row = await _latestPausedRow(userId);
      // No paused exam: an empty DTO, never a parse error.
      return _pausedFromRow(row ?? const {}, userId);
    } on PostgrestException catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>?> _latestPausedRow(String userId) async {
    final row = await _supabase
        .from('mockboards_paused')
        .select('*')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  MockboardsPausedDto _pausedFromRow(Map<String, dynamic> row, String userId) {
    return MockboardsPausedDto(
      id: (row['id'] ?? '').toString(),
      user_id: userId,
      quiz_id: readInt(row['quiz_id']) ?? 0,
      current_page: (row['current_page'] as num?)?.toDouble() ?? 0,
      created_at: (row['created_at'] ?? '').toString(),
      updated_at: (row['updated_at'] ?? '').toString(),
    );
  }

  @override
  Future<List<ExaminationResult>> getRecentAttemptResults() async {
    final userId = await userContext.currentUserId();
    final rows = await _supabase
        .from('quiz_attempts')
        .select('score, attempted_at, no_of_attempt')
        .eq('student_id', userId)
        .order('attempted_at', ascending: false)
        .limit(examHistoryLimit);
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final attemptNo = readInt(data['no_of_attempt']);
      return ExaminationResult(
        examName: attemptNo == null ? 'Mock Board' : 'Mock Board $attemptNo',
        date: utcTimestampText(data['attempted_at']),
        score: double.tryParse(data['score'].toString()) ?? 0,
        passingScore: 75,
        mockBoardAttemptNo: attemptNo,
      );
    }).toList();
  }
}

/// True only when the error clearly says `save_mock_board_attempt` is not
/// deployed. Permission, validation, network and any other server error must
/// stay real failures, never a silent client-side save.
bool isMockBoardRpcMissing(PostgrestException error) =>
    _isRpcMissing(error, 'save_mock_board_attempt');

bool _isRpcMissing(PostgrestException error, String function) {
  // Both PostgREST (PGRST202, "Could not find the function ...") and
  // PostgreSQL (42883) name the function. Requiring the name keeps every
  // other failure - authorization (42501, JWT), validation (22023), conflicts
  // or an unrelated missing function - from ever reaching the legacy save.
  final names = error.message.contains(function);
  return names && (error.code == 'PGRST202' || error.code == '42883');
}
