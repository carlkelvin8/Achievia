import 'dart:convert';

import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Soft-deleted content (deleted_at set by the admin) must never reach a
/// student: every Question Bank read asks the server for live rows only.
void main() {
  late List<http.Request> requests;
  late SupabaseClient client;

  setUp(() {
    requests = [];
    client = SupabaseClient(
      'https://example.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final body = request.url.path.endsWith('/quizzes')
            ? [
                {
                  'id': 1,
                  'title': 'Parasitology Picture-Based Questions',
                  'subject_id': 26,
                  'description': '',
                },
              ]
            : <Object>[];
        return http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
  });

  test('the topic list only asks for live subtopics', () async {
    final topics = await QuestionBankRemoteDatasource(
      client: client,
    ).getTopics(26);

    expect(topics, hasLength(1));
    final request = requests.single;
    expect(request.url.path, endsWith('/quizzes'));
    expect(request.url.queryParameters['deleted_at'], 'is.null');
    expect(request.url.queryParameters['subject_id'], 'eq.26');
  });

  test('subjects are read live-only too', () async {
    await QuestionBankRemoteDatasource(client: client).getAllSubjects();
    expect(requests.single.url.path, endsWith('/subjects'));
    expect(requests.single.url.queryParameters['deleted_at'], 'is.null');
  });

  test('study questions and their choices are live-only', () async {
    await QuestionBankRemoteDatasource(client: client).getStudyQuestions(1);
    final byTable = {
      for (final r in requests) r.url.pathSegments.last: r.url.queryParameters,
    };
    expect(byTable['quizzes']?['deleted_at'], 'is.null');
    expect(byTable['questions']?['deleted_at'], 'is.null');
  });
}
