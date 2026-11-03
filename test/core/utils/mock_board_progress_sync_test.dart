import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/data/data_source/home/mock_board_progress_remote.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements MockBoardProgressStore {
  final sessions = <String, MockBoardSession>{};
  final progress = <String, MockBoardProgress>{};
  int progressWrites = 0;
  bool failing = false;

  String _key(String user, bool pre) => '$user-$pre';

  @override
  Future<void> saveSession(String u, bool pre, MockBoardSession s) async {
    if (failing) throw StateError('offline');
    sessions[_key(u, pre)] = s;
  }

  @override
  Future<void> saveProgress(
    String u,
    MockBoardProgress p, {
    bool flush = false,
  }) async {
    if (failing) throw StateError('offline');
    progressWrites++;
    progress[_key(u, p.isPreBoard)] = p;
  }

  @override
  Future<PendingMockBoard?> load(String u, bool pre) async {
    if (failing) throw StateError('offline');
    final s = sessions[_key(u, pre)];
    final p = progress[_key(u, pre)];
    if (s == null || p == null) return null;
    return PendingMockBoard(session: s, progress: p);
  }

  @override
  Future<void> clear(String u, bool pre) async {
    sessions.remove(_key(u, pre));
    progress.remove(_key(u, pre));
  }
}

/// Serves question and choice rows the way the database does.
class _Source implements MockBoardSource {
  final questionRows = <Map<String, dynamic>>[];
  final choiceRows = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> questions(List<int> ids) async =>
      questionRows.where((r) => ids.contains(r['id'])).toList();

  @override
  Future<List<Map<String, dynamic>>> choices(List<int> ids) async =>
      choiceRows.where((r) => ids.contains(r['question_id'])).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

MockBoardSession _session({bool withRationale = true}) => MockBoardSession(
  clientAttemptId: 'attempt-1',
  startedAttemptId: 'attempt-1',
  board: [
    {
      'id': 1,
      'title': 'Clinical Chemistry',
      'description': '',
      'createdAt': '',
      'subjectId': 1,
      'questions': [
        {
          'id': 10,
          'questionText': 'Q10',
          'imagePath': '',
          if (withRationale) 'rationale': 'Old',
          'choices': [
            {
              'id': 102,
              'choiceText': 'B',
              'is_correct': false,
              'questionId': 10,
            },
            {
              'id': 101,
              'choiceText': 'A',
              'is_correct': true,
              'questionId': 10,
            },
          ],
        },
      ],
    },
  ],
);

MockBoardProgress _progress() => MockBoardProgress(
  isPreBoard: false,
  selectedAnswers: const {'1:10': 1},
  subjectIndex: 0,
  questionIndex: 0,
  remaining: const Duration(minutes: 90),
  savedAt: DateTime(2026, 10, 20),
);

void main() {
  test('another phone continues from the server copy', () async {
    final server = _MemoryStore();
    final phoneA = SyncedMockBoardProgressStore(
      local: _MemoryStore(),
      remote: server,
    );
    await phoneA.saveSession('u', false, _session());
    await phoneA.saveProgress('u', _progress(), flush: true);

    final phoneBLocal = _MemoryStore();
    final phoneB = SyncedMockBoardProgressStore(
      local: phoneBLocal,
      remote: server,
    );
    final pending = await phoneB.load('u', false);
    expect(pending, isNotNull);
    expect(pending!.progress.selectedAnswers, {'1:10': 1});
    expect(pending.progress.remaining, const Duration(minutes: 90));
    // Kept on the new phone too from now on.
    expect(await phoneBLocal.load('u', false), isNotNull);

    await phoneB.clear('u', false);
    expect(await phoneA.load('u', false), isNotNull, reason: 'A has a copy');
    expect(await server.load('u', false), isNull, reason: 'submitted');
  });

  test(
    'answers reach the server at most every interval, always on leave',
    () async {
      var now = DateTime(2026, 10, 20, 9);
      final server = _MemoryStore();
      final store = SyncedMockBoardProgressStore(
        local: _MemoryStore(),
        remote: server,
        clock: () => now,
      );
      await store.saveProgress('u', _progress());
      await store.saveProgress('u', _progress());
      expect(server.progressWrites, 1);
      now = now.add(const Duration(seconds: 16));
      await store.saveProgress('u', _progress());
      expect(server.progressWrites, 2);
      await store.saveProgress('u', _progress(), flush: true);
      expect(server.progressWrites, 3);
    },
  );

  test('an unreachable server never breaks the exam', () async {
    final server = _MemoryStore()..failing = true;
    final local = _MemoryStore();
    final store = SyncedMockBoardProgressStore(local: local, remote: server);
    await store.saveSession('u', false, _session());
    await store.saveProgress('u', _progress(), flush: true);
    expect(await store.load('u', false), isNotNull);
  });

  test('a board is rebuilt from ids, keeping the choice order shown', () async {
    final source = _Source()
      ..questionRows.add({
        'id': 10,
        'question_text': 'Q10 with <em>Campylobacter</em>',
        'image_path': 'questions/q10.png',
        'rationale': null,
        'correct_description': '<p>Because.</p>',
      })
      ..choiceRows.addAll([
        {'id': 101, 'question_id': 10, 'choice_text': 'A', 'is_correct': true},
        {'id': 102, 'question_id': 10, 'choice_text': 'B', 'is_correct': false},
      ]);
    final remote = SupabaseMockBoardProgressStore(source: source);

    final fresh = await remote.rebuild(_session(withRationale: false));
    final question = (fresh!.board.single['questions'] as List).single as Map;
    expect(fresh.clientAttemptId, 'attempt-1');
    expect(question['imagePath'], 'questions/q10.png');
    expect(question['rationale'], '<p>Because.</p>');
    expect([for (final c in question['choices'] as List) c['id']], [102, 101]);
  });

  test('an old device board without rationales is refreshed on load', () async {
    final local = _MemoryStore();
    await local.saveSession('u', false, _session(withRationale: false));
    await local.saveProgress('u', _progress());
    final store = SyncedMockBoardProgressStore(
      local: local,
      rebuild: (_) async => _session(),
    );
    final pending = await store.load('u', false);
    expect(pending!.session.lacksRationale, isFalse);
    expect((await local.load('u', false))!.session.lacksRationale, isFalse);
  });
}
