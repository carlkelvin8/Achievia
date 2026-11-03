import 'dart:async';
import 'dart:convert';

import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'cold selection uses a count and one small page with bounded choices',
    () async {
      final requests = <http.Request>[];
      final now = DateTime.utc(2026, 10, 13, 2);
      const count = 100003;
      final start = QuestionOfTheDayPicker.questionIndex(now, count);
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'HEAD') {
            return http.Response(
              '',
              200,
              request: request,
              headers: {'content-range': '*/$count'},
            );
          }
          final body = request.url.path.endsWith('/quizzes')
              ? [
                  {'id': 7},
                ]
              : request.url.path.endsWith('/questions')
              ? [
                  {'id': 100},
                  {'id': 101},
                ]
              : [
                  {'id': 1, 'question_id': 101, 'is_correct': true},
                  {'id': 2, 'question_id': 101, 'is_correct': false},
                ];
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final selected = await QuestionsRemoteDatasource(
        client: client,
      ).getDailyQuestionId(1, now);
      expect(selected, 101);
      expect(requests, hasLength(4));
      expect(requests[1].method, 'HEAD');
      expect(requests[2].url.queryParameters['offset'], '$start');
      expect(requests[2].url.queryParameters['limit'], '25');
      expect(requests[2].url.queryParameters['select'], 'id');
      expect(requests.last.url.queryParameters['question_id'], 'in.(100,101)');
    },
  );

  test(
    'question text and choices load concurrently and retain the attachment',
    () async {
      final bothStarted = Completer<void>();
      var started = 0;
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          started++;
          if (started == 2) bothStarted.complete();
          await bothStarted.future.timeout(const Duration(seconds: 1));
          final body = request.url.path.endsWith('/questions')
              ? {
                  'id': 10,
                  'quiz_id': 7,
                  'question_text': 'Identify the image',
                  'image_path': 'questions/example.png',
                  'rationale': null,
                  'correct_description':
                      '<p>Explanation of the correct answer.</p>',
                }
              : [
                  {'id': 100, 'choice_text': 'Answer', 'is_correct': true},
                ];
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final question = await QuestionsRemoteDatasource(
        client: client,
      ).getQuestion(10);
      expect(question.imagePath, 'questions/example.png');
      expect(question.rationale, '<p>Explanation of the correct answer.</p>');
      expect(question.choices.single.id, 100);
    },
  );
}
