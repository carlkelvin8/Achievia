import 'dart:convert';
import 'package:achievia/data/data_source/chat/chat_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '00000000-0000-0000-0000-000000000001';
const conversationId = '00000000-0000-0000-0000-000000000002';
Map<String, dynamic> message(int id) => {
  'id': '$id',
  'conversation_id': conversationId,
  'sender_id': userId,
  'body': 'Message $id',
  'created_at': '2026-09-27T00:00:00Z',
};

void main() {
  Future<SupabaseClient> clientFor(
    Future<http.Response> Function(http.Request) handler,
  ) async {
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'test',
        'refresh_token': 'test',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': userId,
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'authenticated',
          'created_at': '2026-09-27T00:00:00Z',
        },
      }),
    );
    addTearDown(client.dispose);
    return client;
  }

  test('direct chat decodes the actual JSON object RPC contract', () async {
    final client = await clientFor((request) async {
      expect(request.url.path, endsWith('/rpc/get_or_create_direct_chat'));
      return http.Response(
        jsonEncode({
          'id': conversationId,
          'type': 'direct',
          'title': 'Partner',
          'created_by': userId,
          'created_at': '2026-09-27T00:00:00Z',
          'updated_at': '2026-09-27T00:00:00Z',
        }),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final result = await ChatRemoteDatasource(
      client: client,
    ).startDirectConversation(conversationId);
    expect(result.id, conversationId);
  });

  test(
    'direct chat also accepts the one-element list the database sends',
    () async {
      final client = await clientFor((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': conversationId,
              'type': 'direct',
              'title': 'Partner',
              'created_by': userId,
              'created_at': '2026-09-27T00:00:00Z',
              'updated_at': '2026-09-27T00:00:00Z',
            },
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      final result = await ChatRemoteDatasource(
        client: client,
      ).startDirectConversation(conversationId);
      expect(result.id, conversationId);
      expect(result.title, 'Partner');
    },
  );

  test('an empty direct chat result is a clear failure', () async {
    final client = await clientFor((request) async {
      return http.Response(
        jsonEncode(<Object>[]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    expect(
      () => ChatRemoteDatasource(
        client: client,
      ).startDirectConversation(conversationId),
      throwsException,
    );
  });

  test('loads newest page and returns chronological messages', () async {
    final client = await clientFor((request) async {
      expect(
        request.url.queryParameters['order'],
        startsWith('created_at.desc'),
      );
      expect(request.url.queryParameters['limit'], '100');
      return http.Response(
        jsonEncode([message(102), message(101)]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final rows = await ChatRemoteDatasource(
      client: client,
    ).getMessages(conversationId);
    expect(rows.map((row) => row.id), ['101', '102']);
  });

  test(
    'successful message insert has no fallible follow-up write or broadcast',
    () async {
      var calls = 0;
      final client = await clientFor((request) async {
        calls++;
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/chat_messages'));
        return http.Response(
          jsonEncode(message(1)),
          201,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      final source = ChatRemoteDatasource(client: client);
      expect((await source.sendMessage(conversationId, 'Hello')).id, '1');
      expect(calls, 1);
      await expectLater(
        source.sendMessage(conversationId, 'x' * 10001),
        throwsArgumentError,
      );
      expect(calls, 1);
    },
  );
}
