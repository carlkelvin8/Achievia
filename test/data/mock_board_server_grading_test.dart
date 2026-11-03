import 'dart:convert';

import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '00000000-0000-0000-0000-000000000001';

class _FakeUserContext extends SupabaseUserContext {
  const _FakeUserContext();

  @override
  Future<String> currentUserId() async => _userId;
}

/// Six sections (ids 1..6) with two questions each; question ids are
/// `section * 10 + n` and choice ids `question * 10 + k` (k = 1 is correct).
List<QuizDtoItems> _board() => [
  for (var section = 1; section <= 6; section++)
    QuizDtoItems(
      id: section,
      title: 'Section $section',
      description: '',
      createdAt: '',
      subjectId: section,
      questions: [
        for (var n = 1; n <= 2; n++)
          QuestionsItemsDto(
            id: section * 10 + n,
            questionText: 'Q',
            choices: [
              for (var k = 1; k <= 4; k++)
                ChoicesDto(
                  id: (section * 10 + n) * 10 + k,
                  choiceText: 'C$k',
                  isCorrect: k == 1,
                  questionId: section * 10 + n,
                ),
            ],
          ),
      ],
    ),
];

class _Recorder {
  final calls = <http.Request>[];

  List<http.Request> where(String pathEnd, {String? method}) => calls
      .where(
        (r) =>
            r.url.path.endsWith(pathEnd) &&
            (method == null || r.method == method),
      )
      .toList();
}

http.Response _json(http.Request request, Object body, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

QuestionsRemoteDatasource _datasource(
  _Recorder recorder,
  Future<http.Response> Function(http.Request request) respond,
) {
  final client = SupabaseClient(
    'https://example.test',
    'test-key',
    httpClient: MockClient((request) async {
      recorder.calls.add(request);
      return respond(request);
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return QuestionsRemoteDatasource(
    userContext: const _FakeUserContext(),
    client: client,
  )..seedGeneratedQuiz(_board());
}

Map<String, dynamic> _rpcBody(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

void main() {
  setUp(() {
    resetMockBoardAnswers();
  });

  group('submission payload', () {
    test('carries only what was answered, never correctness or a score', () {
      mockBoardSelections[11] = 111;
      mockBoardSelections[62] = 622;

      final items = mockBoardSubmissionItems(_board(), mockBoardSelections);

      expect(items, hasLength(12));
      expect(items.first, {
        'section': 1,
        'question_id': 11,
        'selected_choice_id': 111,
      });
      expect(items.last, {
        'section': 6,
        'question_id': 62,
        'selected_choice_id': 622,
      });
      // Unanswered questions are explicit nulls, not omitted or "wrong".
      expect(items[1]['selected_choice_id'], isNull);
      for (final item in items) {
        expect(item.keys.toSet(), {
          'section',
          'question_id',
          'selected_choice_id',
        });
      }
    });

    test('recordAnswer keeps the picked choice only when ids are known', () {
      recordAnswer('Hematology', true);
      expect(mockBoardSelections, isEmpty);

      recordAnswer('Hematology', false, questionId: 41, choiceId: 412);
      expect(mockBoardSelections, {41: 412});
      expect(subjectScores['Hematology']!.total, 2);
    });
  });

  group('putToAttempt', () {
    test(
      'sends answers to the grading RPC and trusts only its result',
      () async {
        mockBoardSelections[11] = 111;
        final recorder = _Recorder();
        final source = _datasource(recorder, (request) async {
          expect(request.url.path, endsWith('/rpc/save_mock_board_attempt'));
          return _json(request, 7);
        });

        final number = await source.putToAttempt();

        expect(number, 7);
        expect(recorder.calls, hasLength(1));
        final body = _rpcBody(recorder.calls.single);
        expect(body.keys.toSet(), {'p_client_attempt_id', 'p_items'});
        expect(body['p_client_attempt_id'], isNotEmpty);
        final items = body['p_items'] as List;
        expect(items, hasLength(12));
        expect((items.first as Map)['selected_choice_id'], 111);
        // The local state is reset only after the server accepted the board.
        expect(mockBoardSelections, isEmpty);
        // No table write: the client cannot store a score itself.
        expect(recorder.where('/quiz_attempts'), isEmpty);
      },
    );

    test('a saved board forgets its answers before the next one', () async {
      recordAnswer('Section 1', true, questionId: 11, choiceId: 111);
      final source = _datasource(_Recorder(), (r) async => _json(r, 7));

      expect(await source.putToAttempt(), 7);
      expect(mockBoardSelections, isEmpty);
      expect(subjectScores, isEmpty);

      // Answering the same question again is a first answer, not a change.
      recordAnswer('Section 1', false, questionId: 11, choiceId: 112);
      expect(subjectScores['Section 1']!.total, 1);
      expect(subjectScores['Section 1']!.correct, 0);
    });

    test('a failed submit keeps the tallies for the retry', () async {
      recordAnswer('Section 1', true, questionId: 11, choiceId: 111);
      final source = _datasource(
        _Recorder(),
        (r) async => _json(r, {'code': '57014', 'message': 'x'}, 500),
      );

      expect(await source.putToAttempt(), 0);
      expect(mockBoardSelections, {11: 111});
      // Changing the answer before retrying still replaces it.
      recordAnswer('Section 1', false, questionId: 11, choiceId: 112);
      expect(subjectScores['Section 1']!.total, 1);
      expect(subjectScores['Section 1']!.correct, 0);
    });

    test(
      'a failed submit keeps answers and retries with the same id',
      () async {
        mockBoardSelections[11] = 111;
        final recorder = _Recorder();
        var attempt = 0;
        final source = _datasource(recorder, (request) async {
          attempt++;
          if (attempt == 1) {
            return _json(request, {
              'code': '57014',
              'message': 'temporary failure',
            }, 500);
          }
          return _json(request, 3);
        });

        expect(await source.putToAttempt(), 0);
        expect(mockBoardSelections, {11: 111});

        expect(await source.putToAttempt(), 3);

        final ids = recorder.calls
            .map((r) => _rpcBody(r)['p_client_attempt_id'])
            .toSet();
        expect(
          ids,
          hasLength(1),
          reason: 'retry must reuse the idempotency key',
        );
        expect(mockBoardSelections, isEmpty);
      },
    );

    test('a refused submission is not saved from the client', () async {
      final recorder = _Recorder();
      final source = _datasource(recorder, (request) async {
        return _json(request, {
          'code': '22023',
          'message': 'duplicate question in mock board',
        }, 400);
      });

      expect(await source.putToAttempt(), 0);
      // No fallback insert for ordinary errors.
      expect(recorder.where('/quiz_attempts'), isEmpty);
      expect(recorder.calls, hasLength(1));
    });

    test('permission errors never fall back to a client insert', () async {
      final recorder = _Recorder();
      final source = _datasource(recorder, (request) async {
        return _json(request, {
          'code': '42501',
          'message': 'permission denied for function save_mock_board_attempt',
        }, 403);
      });

      expect(await source.putToAttempt(), 0);
      expect(recorder.where('/quiz_attempts'), isEmpty);
    });

    test(
      'falls back to the legacy save only while the RPC is not deployed',
      () async {
        mockBoardSelections[11] = 111;
        final recorder = _Recorder();
        final source = _datasource(recorder, (request) async {
          if (request.url.path.endsWith('/rpc/save_mock_board_attempt')) {
            return _json(request, {
              'code': 'PGRST202',
              'message':
                  'Could not find the function '
                  'public.save_mock_board_attempt(p_client_attempt_id, '
                  'p_items) in the schema cache',
            }, 404);
          }
          if (request.method == 'GET') return _json(request, <Object>[]);
          return http.Response('', 201, request: request);
        });

        final number = await source.putToAttempt();

        expect(number, 1);
        expect(recorder.where('/quiz_attempts', method: 'POST'), hasLength(1));
      },
    );
  });

  group('legacy fallback is only for a missing RPC', () {
    Future<_Recorder> failWith(
      Future<http.Response> Function(http.Request request) respond,
    ) async {
      mockBoardSelections[11] = 111;
      final recorder = _Recorder();
      final source = _datasource(recorder, respond);
      expect(await source.putToAttempt(), 0);
      return recorder;
    }

    for (final failure in <String, List<Object>>{
      'expired JWT': [401, 'PGRST301', 'JWT expired'],
      'permission denied': [403, '42501', 'permission denied'],
      'validation': [400, '22023', 'duplicate question in mock board'],
      'not authenticated': [400, '28000', 'Not authenticated'],
      'unique violation': [409, '23505', 'duplicate key value'],
      'unrelated missing function': [
        404,
        'PGRST202',
        'Could not find the function public.some_other_fn() in the schema cache',
      ],
      'server error': [500, 'XX000', 'internal error'],
    }.entries) {
      test('${failure.key} never writes to quiz_attempts', () async {
        final recorder = await failWith((request) async {
          return _json(request, {
            'code': failure.value[1],
            'message': failure.value[2],
          }, failure.value[0] as int);
        });
        expect(recorder.where('/quiz_attempts'), isEmpty);
        expect(recorder.calls, hasLength(1));
        // The answers are kept so the user can retry.
        expect(mockBoardSelections, {11: 111});
      });
    }

    test('a network failure never writes to quiz_attempts', () async {
      final recorder = await failWith((request) async {
        throw http.ClientException('connection reset', request.url);
      });
      expect(recorder.where('/quiz_attempts'), isEmpty);
      expect(mockBoardSelections, {11: 111});
    });
  });

  group('server session start', () {
    test('is requested once per board, with the id used at submit', () async {
      final recorder = _Recorder();
      final source = _datasource(recorder, (request) async {
        if (request.url.path.endsWith('/rpc/start_mock_board_attempt')) {
          return _json(request, '2026-10-11T00:00:00Z');
        }
        return _json(request, 5);
      });

      expect(await source.startMockBoardAttempt(), isTrue);
      expect(await source.startMockBoardAttempt(), isTrue);
      expect(await source.putToAttempt(), 5);

      final starts = recorder.where('/rpc/start_mock_board_attempt');
      expect(starts, hasLength(1));
      final submit = recorder.where('/rpc/save_mock_board_attempt').single;
      expect(
        _rpcBody(starts.single)['p_client_attempt_id'],
        _rpcBody(submit)['p_client_attempt_id'],
      );
    });

    test('a failed start never throws and can be retried', () async {
      final recorder = _Recorder();
      var calls = 0;
      final source = _datasource(recorder, (request) async {
        calls++;
        if (calls == 1) throw http.ClientException('offline', request.url);
        return _json(request, '2026-10-11T00:00:00Z');
      });

      expect(await source.startMockBoardAttempt(), isFalse);
      expect(await source.startMockBoardAttempt(), isTrue);

      expect(recorder.where('/rpc/start_mock_board_attempt'), hasLength(2));
    });

    test('a server without the patch does not block the exam', () async {
      final recorder = _Recorder();
      final source = _datasource(recorder, (request) async {
        return _json(request, {
          'code': 'PGRST202',
          'message':
              'Could not find the function public.start_mock_board_attempt',
        }, 404);
      });

      // No "Ranking unavailable" warning: nothing requires the start yet.
      expect(await source.startMockBoardAttempt(), isTrue);

      expect(recorder.calls, hasLength(1));
    });
  });

  test(
    'a full board on the production schema saves, grades and dates right',
    () async {
      const titles = [
        'Clinical Chemistry',
        'Microbiology and Parasitology',
        'Clinical Microscopy',
        'Hematology',
        'Blood Banking and Serology',
        'Histopathology and Medical Technology Laws/Ethics',
      ];
      const correctCounts = [32, 26, 19, 21, 28, 31];
      final board = [
        for (var section = 0; section < 6; section++)
          QuizDtoItems(
            id: section + 1,
            title: titles[section],
            description: '',
            createdAt: '',
            subjectId: section + 1,
            questions: [
              for (var n = 0; n < 100; n++)
                QuestionsItemsDto(
                  id: (section + 1) * 1000 + n,
                  questionText: 'Q',
                  choices: [
                    ChoicesDto(
                      id: ((section + 1) * 1000 + n) * 10 + 1,
                      choiceText: 'right',
                      isCorrect: true,
                      questionId: (section + 1) * 1000 + n,
                    ),
                    ChoicesDto(
                      id: ((section + 1) * 1000 + n) * 10 + 2,
                      choiceText: 'wrong',
                      isCorrect: false,
                      questionId: (section + 1) * 1000 + n,
                    ),
                  ],
                ),
            ],
          ),
      ];

      // Neither RPC is deployed; attempted_at comes back as timestamptz.
      final rows = <Map<String, dynamic>>[];
      final recorder = _Recorder();
      final source = _datasource(recorder, (request) async {
        if (request.url.path.contains('/rpc/')) {
          final function = request.url.pathSegments.last;
          return _json(request, {
            'code': 'PGRST202',
            'message': 'Could not find the function public.$function',
          }, 404);
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body);
          rows.add(
            Map<String, dynamic>.from(body is List ? body.single as Map : body),
          );
          return http.Response('', 201, request: request);
        }
        return _json(request, [
          for (final row in rows)
            {
              ...row,
              'attempted_at': DateTime.parse(
                row['attempted_at'] as String,
              ).toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
            },
        ]);
      })..seedGeneratedQuiz(board);

      // START EXAM opens the exam: the dialog would need a BuildContext, so a
      // false here is what would show it.
      expect(await source.startMockBoardAttempt(), isTrue);

      for (var section = 0; section < 6; section++) {
        for (var n = 0; n < 100; n++) {
          final question = board[section].questions[n];
          final isCorrect = n < correctCounts[section];
          recordAnswer(
            titles[section],
            isCorrect,
            questionId: question.id,
            choiceId: question.choices[isCorrect ? 0 : 1].id,
          );
        }
      }

      final before = DateTime.now().toUtc();
      expect(await source.putToAttempt(), 1);

      final saved = rows.single;
      expect(saved['score'], 26.4);
      expect(saved['no_of_attempt'], 1);
      expect((saved['attempted_at'] as String).endsWith('Z'), isTrue);

      final result = await source.getResults(1);
      expect(result.data.score.score, '26.40');
      expect(result.success, isFalse);

      final recent = (await source.getRecentAttemptResults()).single;
      expect(recent.score, 26.4);
      expect(
        DateTime.parse(recent.date).difference(before).inSeconds.abs(),
        lessThan(60),
      );
    },
  );

  test('recent results read attempted_at without an offset as UTC', () async {
    final source = _datasource(_Recorder(), (request) async {
      return _json(request, [
        {
          'score': 26.4,
          'attempted_at': '2026-11-03T02:59:46.482',
          'no_of_attempt': 10,
        },
      ]);
    });

    final result = (await source.getRecentAttemptResults()).single;

    expect(
      DateTime.parse(result.date),
      DateTime.utc(2026, 11, 3, 2, 59, 46, 482),
    );
  });

  test('missing-function detection names the function', () {
    expect(
      isMockBoardRpcMissing(
        const PostgrestException(
          message:
              'Could not find the function public.save_mock_board_attempt(a)',
          code: 'PGRST202',
        ),
      ),
      isTrue,
    );
    expect(
      isMockBoardRpcMissing(
        const PostgrestException(
          message: 'function public.save_mock_board_attempt does not exist',
          code: '42883',
        ),
      ),
      isTrue,
    );
    // The same codes for anything else are real failures.
    expect(
      isMockBoardRpcMissing(
        const PostgrestException(message: 'x', code: 'PGRST202'),
      ),
      isFalse,
    );
    expect(
      isMockBoardRpcMissing(
        const PostgrestException(
          message: 'function other() does not exist',
          code: '42883',
        ),
      ),
      isFalse,
    );
    // Same name, different cause: never a fallback.
    for (final code in ['42501', 'PGRST301', '22023', '23505', '28000']) {
      expect(
        isMockBoardRpcMissing(
          PostgrestException(
            message: 'save_mock_board_attempt: refused',
            code: code,
          ),
        ),
        isFalse,
        reason: code,
      );
    }
  });
}
