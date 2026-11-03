import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/core/utils/questions_helpers.dart' show readInt;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The server copy of an unfinished Mock Boards / Pre Boards exam
/// (`public.mock_board_progress`, patch 20261020100000), one row per user
/// and kind.
///
/// Only ids are stored for the board; [load] downloads the question content
/// again from them (so a board continued on another phone shows the current
/// images and rationales).
class SupabaseMockBoardProgressStore implements MockBoardProgressStore {
  SupabaseMockBoardProgressStore({
    SupabaseClient? client,
    MockBoardSource? source,
  }) : _client = client,
       _source = source ?? SupabaseMockBoardSource();

  static const table = 'mock_board_progress';

  final SupabaseClient? _client;
  final MockBoardSource _source;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static String _kind(bool isPreBoard) => isPreBoard ? 'pre' : 'mock';

  @override
  Future<void> saveSession(
    String userId,
    bool isPreBoard,
    MockBoardSession session,
  ) async {
    await _supabase.from(table).upsert({
      'user_id': userId,
      'kind': _kind(isPreBoard),
      'session': session.toCompactJson(),
      'progress': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,kind');
  }

  @override
  Future<void> saveProgress(
    String userId,
    MockBoardProgress progress, {
    bool flush = false,
  }) async {
    await _supabase.from(table).upsert({
      'user_id': userId,
      'kind': _kind(progress.isPreBoard),
      'progress': progress.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,kind');
  }

  @override
  Future<PendingMockBoard?> load(String userId, bool isPreBoard) async {
    final row = await _supabase
        .from(table)
        .select('session, progress')
        .eq('user_id', userId)
        .eq('kind', _kind(isPreBoard))
        .maybeSingle();
    if (row == null) return null;
    final progress = MockBoardProgress.fromJson(row['progress']);
    final compact = row['session'];
    if (progress == null || compact is! Map) return null;
    final session = await rebuildFromCompact(
      Map<String, dynamic>.from(compact),
    );
    if (session == null) return null;
    return PendingMockBoard(session: session, progress: progress);
  }

  @override
  Future<void> clear(String userId, bool isPreBoard) async {
    await _supabase
        .from(table)
        .delete()
        .eq('user_id', userId)
        .eq('kind', _kind(isPreBoard));
  }

  /// Downloads the content of [session]'s board again from its ids.
  Future<MockBoardSession?> rebuild(MockBoardSession session) =>
      rebuildFromCompact(session.toCompactJson());

  /// Builds the full board from its ids. Questions removed since the exam
  /// started are left out; null when nothing usable is left.
  Future<MockBoardSession?> rebuildFromCompact(
    Map<String, dynamic> compact,
  ) async {
    final attemptId = compact['clientAttemptId'];
    final sections = compact['sections'];
    if (attemptId is! String || sections is! List || sections.isEmpty) {
      return null;
    }
    final questionIds = <int>[
      for (final section in sections)
        if (section is Map)
          for (final question in (section['questions'] as List? ?? const []))
            if (question is Map && readInt(question['id']) != null)
              readInt(question['id'])!,
    ];
    if (questionIds.isEmpty) return null;

    final results = await Future.wait([
      _source.questions(questionIds),
      _source.choices(questionIds),
    ]);
    final questionsById = {
      for (final row in results[0])
        if (readInt(row['id']) != null) readInt(row['id'])!: row,
    };
    final choicesById = {
      for (final row in results[1])
        if (readInt(row['id']) != null) readInt(row['id'])!: row,
    };

    final board = <Map<String, dynamic>>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final questions = <Map<String, dynamic>>[];
      for (final question in (section['questions'] as List? ?? const [])) {
        if (question is! Map) continue;
        final id = readInt(question['id']);
        final row = id == null ? null : questionsById[id];
        if (id == null || row == null) continue;
        final choices = <Map<String, dynamic>>[
          // The order the student saw (answers are kept as choice indexes).
          for (final choiceId in (question['choices'] as List? ?? const []))
            if (choicesById[readInt(choiceId)] case final choice?)
              {
                'id': readInt(choice['id']),
                'choiceText': (choice['choice_text'] ?? '').toString(),
                'is_correct': choice['is_correct'] == true,
                'questionId': id,
              },
        ];
        if (choices.isEmpty) continue;
        questions.add({
          'id': id,
          'questionText': (row['question_text'] ?? '').toString(),
          'imagePath': _text(row['image_path']),
          'rationale': _text(row['rationale'], row['correct_description']),
          'choices': choices,
        });
      }
      board.add({
        'id': readInt(section['id']) ?? 0,
        'title': (section['title'] ?? '').toString(),
        'description': (section['description'] ?? '').toString(),
        'createdAt': (section['createdAt'] ?? '').toString(),
        'subjectId': readInt(section['subjectId']) ?? 0,
        'questions': questions,
      });
    }
    if (board.every((section) => (section['questions'] as List).isEmpty)) {
      return null;
    }
    return MockBoardSession(
      board: board,
      clientAttemptId: attemptId,
      startedAttemptId: compact['startedAttemptId'] as String?,
    );
  }
}

/// First value holding real text (not null, empty or the literal "null").
String _text(Object? first, [Object? second]) {
  for (final value in [first, second]) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}
