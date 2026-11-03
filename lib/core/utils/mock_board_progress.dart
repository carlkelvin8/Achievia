import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The generated board of an exam in progress and its attempt ids, as plain
/// JSON so it can be stored and handed back to the data source unchanged.
class MockBoardSession {
  /// One entry per subject, in exam order (`QuizDtoItems.toJson`).
  final List<Map<String, dynamic>> board;
  final String clientAttemptId;

  /// The attempt id whose start the server already recorded, if any.
  final String? startedAttemptId;

  const MockBoardSession({
    required this.board,
    required this.clientAttemptId,
    this.startedAttemptId,
  });

  Map<String, dynamic> toJson() => {
    'board': board,
    'clientAttemptId': clientAttemptId,
    'startedAttemptId': startedAttemptId,
  };

  /// The board as ids only (section info, question ids and each question's
  /// choice order), for the server copy. The content is downloaded again from
  /// these ids, see [MockBoardSessionRebuilder].
  Map<String, dynamic> toCompactJson() => {
    'clientAttemptId': clientAttemptId,
    'startedAttemptId': startedAttemptId,
    'sections': [
      for (final section in board)
        {
          'id': section['id'],
          'title': section['title'],
          'description': section['description'],
          'createdAt': section['createdAt'],
          'subjectId': section['subjectId'],
          'questions': [
            for (final question in (section['questions'] as List? ?? const []))
              if (question is Map)
                {
                  'id': question['id'],
                  'choices': [
                    for (final choice
                        in (question['choices'] as List? ?? const []))
                      if (choice is Map) choice['id'],
                  ],
                },
          ],
        },
    ],
  };

  /// True for a board kept before rationales were stored with it; its
  /// content is downloaded again so the summary can show them.
  bool get lacksRationale => board.any(
    (section) => (section['questions'] as List? ?? const []).any(
      (question) => question is Map && !question.containsKey('rationale'),
    ),
  );

  static MockBoardSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final board = json['board'];
    final attemptId = json['clientAttemptId'];
    if (board is! List || board.isEmpty || attemptId is! String) return null;
    return MockBoardSession(
      board: [
        for (final section in board)
          if (section is Map) Map<String, dynamic>.from(section),
      ],
      clientAttemptId: attemptId,
      startedAttemptId: json['startedAttemptId'] as String?,
    );
  }
}

/// Where the student was in an unfinished Mock Boards (or Pre Boards) exam:
/// the answers picked so far, the subject and question on screen and the time
/// left on the current subject's clock.
class MockBoardProgress {
  final bool isPreBoard;

  /// Choice index per question, keyed `'<subjectBatchId>:<questionId>'`.
  final Map<String, int> selectedAnswers;

  /// Questions marked to revisit, keyed like [selectedAnswers].
  final Set<String> markedQuestions;
  final int subjectIndex;
  final int questionIndex;
  final Duration remaining;
  final DateTime savedAt;

  const MockBoardProgress({
    required this.isPreBoard,
    required this.selectedAnswers,
    this.markedQuestions = const {},
    required this.subjectIndex,
    required this.questionIndex,
    required this.remaining,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': 1,
    'isPreBoard': isPreBoard,
    'selectedAnswers': selectedAnswers,
    'markedQuestions': markedQuestions.toList(),
    'subjectIndex': subjectIndex,
    'questionIndex': questionIndex,
    'remainingSeconds': remaining.inSeconds,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };

  static MockBoardProgress? fromJson(Object? json) {
    if (json is! Map) return null;
    final answers = json['selectedAnswers'];
    final seconds = json['remainingSeconds'];
    if (answers is! Map || seconds is! int) return null;
    return MockBoardProgress(
      isPreBoard: json['isPreBoard'] == true,
      selectedAnswers: {
        for (final entry in answers.entries)
          if (entry.value is int) entry.key.toString(): entry.value as int,
      },
      markedQuestions: {
        if (json['markedQuestions'] case final List marked)
          for (final key in marked) key.toString(),
      },
      subjectIndex: (json['subjectIndex'] as int?) ?? 0,
      questionIndex: (json['questionIndex'] as int?) ?? 0,
      remaining: Duration(seconds: seconds < 0 ? 0 : seconds),
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// A pending exam: the board it was generated with and where it was left.
class PendingMockBoard {
  final MockBoardSession session;
  final MockBoardProgress progress;

  const PendingMockBoard({required this.session, required this.progress});
}

/// Stores the unfinished exam on the device, per signed-in user and per kind
/// (Mock Boards / Pre Boards), so leaving the exam, closing the app or
/// signing out and back in never loses it.
///
/// The board (hundreds of questions) is written once when the exam starts;
/// the small progress record is rewritten as the student answers.
abstract class MockBoardProgressStore {
  Future<void> saveSession(
    String userId,
    bool isPreBoard,
    MockBoardSession session,
  );

  /// [flush] asks a store that throttles network writes to write now (the
  /// student is leaving the exam or the app).
  Future<void> saveProgress(
    String userId,
    MockBoardProgress progress, {
    bool flush = false,
  });
  Future<PendingMockBoard?> load(String userId, bool isPreBoard);
  Future<void> clear(String userId, bool isPreBoard);
}

/// Downloads a board's content again from its ids (the server copy keeps
/// only ids). Returns null when it cannot be rebuilt.
typedef MockBoardSessionRebuilder =
    Future<MockBoardSession?> Function(MockBoardSession session);

class SharedPrefsMockBoardProgressStore implements MockBoardProgressStore {
  const SharedPrefsMockBoardProgressStore();

  static String _kind(bool isPreBoard) => isPreBoard ? 'pre' : 'mock';
  static String sessionKey(String userId, bool isPreBoard) =>
      'mock_board_session_${_kind(isPreBoard)}_$userId';
  static String progressKey(String userId, bool isPreBoard) =>
      'mock_board_progress_${_kind(isPreBoard)}_$userId';

  @override
  Future<void> saveSession(
    String userId,
    bool isPreBoard,
    MockBoardSession session,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      sessionKey(userId, isPreBoard),
      jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> saveProgress(
    String userId,
    MockBoardProgress progress, {
    bool flush = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      progressKey(userId, progress.isPreBoard),
      jsonEncode(progress.toJson()),
    );
  }

  @override
  Future<PendingMockBoard?> load(String userId, bool isPreBoard) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final session = MockBoardSession.fromJson(
        jsonDecode(prefs.getString(sessionKey(userId, isPreBoard)) ?? 'null'),
      );
      final progress = MockBoardProgress.fromJson(
        jsonDecode(prefs.getString(progressKey(userId, isPreBoard)) ?? 'null'),
      );
      if (session == null || progress == null) return null;
      return PendingMockBoard(session: session, progress: progress);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> clear(String userId, bool isPreBoard) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey(userId, isPreBoard));
    await prefs.remove(progressKey(userId, isPreBoard));
  }
}

/// The device copy first (fast, works offline) and the server copy too, so
/// an unfinished exam also survives reinstalling the app or switching
/// phones. Server writes are best effort: a failure (offline, table not
/// deployed) never affects the exam. Answers reach the server at most every
/// [remoteInterval], and always when the student leaves.
class SyncedMockBoardProgressStore implements MockBoardProgressStore {
  SyncedMockBoardProgressStore({
    required this.local,
    this.remote,
    this.rebuild,
    this.remoteInterval = const Duration(seconds: 15),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MockBoardProgressStore local;
  final MockBoardProgressStore? remote;

  /// Refreshes an old device board that has no rationales stored.
  final MockBoardSessionRebuilder? rebuild;
  final Duration remoteInterval;
  final DateTime Function() _clock;
  DateTime? _lastRemoteProgress;

  Future<void> _remote(
    Future<void> Function(MockBoardProgressStore) write,
  ) async {
    final store = remote;
    if (store == null) return;
    try {
      await write(store);
    } catch (error) {
      debugPrint('Unfinished exam not synced to the server: $error');
    }
  }

  @override
  Future<void> saveSession(
    String userId,
    bool isPreBoard,
    MockBoardSession session,
  ) async {
    await local.saveSession(userId, isPreBoard, session);
    await _remote((s) => s.saveSession(userId, isPreBoard, session));
  }

  @override
  Future<void> saveProgress(
    String userId,
    MockBoardProgress progress, {
    bool flush = false,
  }) async {
    await local.saveProgress(userId, progress, flush: flush);
    final now = _clock();
    final last = _lastRemoteProgress;
    if (!flush && last != null && now.difference(last) < remoteInterval) {
      return;
    }
    _lastRemoteProgress = now;
    await _remote((s) => s.saveProgress(userId, progress, flush: true));
  }

  @override
  Future<PendingMockBoard?> load(String userId, bool isPreBoard) async {
    var pending = await local.load(userId, isPreBoard);
    if (pending == null) {
      // Not on this device: continue from the server copy, if any.
      final store = remote;
      if (store == null) return null;
      try {
        pending = await store.load(userId, isPreBoard);
      } catch (error) {
        debugPrint('Unfinished exam could not be read from the server: $error');
        return null;
      }
      if (pending != null) {
        await local.saveSession(userId, isPreBoard, pending.session);
        await local.saveProgress(userId, pending.progress);
      }
      return pending;
    }
    final refresh = rebuild;
    if (refresh != null && pending.session.lacksRationale) {
      try {
        final fresh = await refresh(pending.session);
        if (fresh != null) {
          await local.saveSession(userId, isPreBoard, fresh);
          pending = PendingMockBoard(
            session: fresh,
            progress: pending.progress,
          );
        }
      } catch (error) {
        debugPrint('Old exam content could not be refreshed: $error');
      }
    }
    return pending;
  }

  @override
  Future<void> clear(String userId, bool isPreBoard) async {
    _lastRemoteProgress = null;
    await local.clear(userId, isPreBoard);
    await _remote((s) => s.clear(userId, isPreBoard));
  }
}
