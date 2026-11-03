import 'dart:async';
import 'dart:convert';

import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One subject per Mock Board section, each with one subtopic configured for
/// exactly 100 questions.
final _subjects = [
  for (final spec in mockBoardSectionSpecs)
    {'id': spec.id, 'title': spec.title, 'created_at': '2026-01-01'},
];

/// Serves a complete board. The very first `liveQuizzes` call (the first
/// generation) waits for [release], so a second generation can run and finish
/// while the first one is still in flight.
class _GatedSource implements MockBoardSource {
  final reachedGate = Completer<void>();
  final release = Completer<void>();
  var _gated = false;

  @override
  Future<List<Map<String, dynamic>>> liveQuizzes(int subjectId) async {
    if (!_gated) {
      _gated = true;
      reachedGate.complete();
      await release.future;
    }
    return [
      {
        'id': subjectId * 10,
        'title': 'Topic $subjectId',
        'subject_id': subjectId,
        'question_count': mockBoardQuestionsPerSubject,
      },
    ];
  }

  @override
  Future<List<int>> liveQuestionIds(int quizId) async => [
    for (var n = 1; n <= mockBoardQuestionsPerSubject; n++) quizId * 1000 + n,
  ];

  @override
  Future<List<Map<String, dynamic>>> questions(List<int> ids) async => [
    for (final id in ids)
      {'id': id, 'quiz_id': id ~/ 1000, 'question_text': 'Q$id'},
  ];

  @override
  Future<List<Map<String, dynamic>>> choices(List<int> questionIds) async => [
    for (final id in questionIds) ...[
      {
        'id': id * 10 + 1,
        'question_id': id,
        'choice_text': 'A',
        'is_correct': true,
      },
      {
        'id': id * 10 + 2,
        'question_id': id,
        'choice_text': 'B',
        'is_correct': false,
      },
    ],
  ];
}

/// [failSubjectRequest] makes the n-th (1-based) subjects request fail.
QuestionsRemoteDatasource _datasource(
  MockBoardSource source, {
  int? failSubjectRequest,
}) {
  var subjectRequests = 0;
  final client = SupabaseClient(
    'https://example.test',
    'test-key',
    httpClient: MockClient((request) async {
      expect(request.url.path, endsWith('/subjects'));
      if (++subjectRequests == failSubjectRequest) {
        return http.Response(
          jsonEncode({'code': '57014', 'message': 'temporary failure'}),
          500,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode(_subjects),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return QuestionsRemoteDatasource(client: client, mockBoardSource: source);
}

void main() {
  setUp(() {
    resetMockBoardAnswers();
  });

  test(
    'a generation that finishes late never replaces a newer board',
    () async {
      final source = _GatedSource();
      final datasource = _datasource(source);

      // First attempt: the caller gives up on it (for example after a timeout).
      final stale = datasource.randomizeQuestion(0);
      Object? staleError;
      final staleDone = stale.then<void>(
        (_) {},
        onError: (Object e) {
          staleError = e;
        },
      );
      await source.reachedGate.future;

      // Retry: completes while the first attempt is still loading.
      await datasource.randomizeQuestion(0);
      final current = await datasource.getTheGeneratedQuiz();
      expect(current, hasLength(mockBoardSubjectCount));

      // The user starts answering the new board.
      final question = current.first.questions.first;
      recordAnswer(
        current.first.title,
        true,
        questionId: question.id,
        choiceId: question.choices.first.id,
      );

      // The abandoned attempt now completes.
      source.release.complete();
      await staleDone;

      expect(
        identical(await datasource.getTheGeneratedQuiz(), current),
        isTrue,
        reason: 'the board on screen must stay the one that gets submitted',
      );
      expect(staleError, isA<StateError>());
      // Nor may it touch the answers given on the newer board.
      expect(mockBoardSelections, {question.id: question.choices.first.id});
      expect(subjectScores[current.first.title]!.correct, 1);
    },
  );

  test(
    'a generation that finishes after a failed retry leaves no board',
    () async {
      final source = _GatedSource();
      final datasource = _datasource(source, failSubjectRequest: 2);

      final stale = datasource.randomizeQuestion(0);
      Object? staleError;
      final staleDone = stale.then<void>(
        (_) {},
        onError: (Object e) {
          staleError = e;
        },
      );
      await source.reachedGate.future;

      // The retry fails, so the user is told the board could not be prepared.
      await expectLater(
        datasource.randomizeQuestion(0),
        throwsA(isA<PostgrestException>()),
      );

      source.release.complete();
      await staleDone;

      // The abandoned attempt must not slip in a board the user never saw.
      expect(await datasource.getTheGeneratedQuiz(), isEmpty);
      expect(staleError, isA<StateError>());
    },
  );

  test('a new board forgets the answers of the previous one', () async {
    final source = _GatedSource()..release.complete();
    final datasource = _datasource(source);
    await datasource.randomizeQuestion(0);
    final board = await datasource.getTheGeneratedQuiz();
    final section = board.first;
    final question = section.questions.first;
    recordAnswer(
      section.title,
      true,
      questionId: question.id,
      choiceId: question.choices.first.id,
    );

    await datasource.randomizeQuestion(0);
    expect(mockBoardSelections, isEmpty);
    expect(subjectScores, isEmpty);

    // The same question on the new board is a first answer, not a change.
    recordAnswer(
      section.title,
      false,
      questionId: question.id,
      choiceId: question.choices.last.id,
    );
    expect(subjectScores[section.title]!.total, 1);
    expect(subjectScores[section.title]!.correct, 0);
  });

  test('a single generation still produces the board', () async {
    final source = _GatedSource()..release.complete();
    final datasource = _datasource(source);

    await datasource.randomizeQuestion(0);

    final board = await datasource.getTheGeneratedQuiz();
    expect(board, hasLength(mockBoardSubjectCount));
    expect(
      board.expand((section) => section.questions),
      hasLength(mockBoardTotalQuestions),
    );
  });
}
