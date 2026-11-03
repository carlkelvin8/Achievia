import 'dart:convert';

import 'package:achievia/data/data_source/progress/progress_remote_datasource.dart';
import 'package:achievia/data/data_source/reviewer/supplemental_remote_datasource.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
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

SupabaseClient _clientFor(
  Future<http.Response> Function(http.Request request) handler,
) {
  final client = SupabaseClient(
    'https://example.test',
    'test-key',
    httpClient: MockClient(handler),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return client;
}

http.Response _json(http.Request request, Object body) => http.Response(
  jsonEncode(body),
  200,
  request: request,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('active days are read page by page, never cut at 1000 rows', () async {
    final offsets = <String>[];
    final client = _clientFor((request) async {
      expect(request.url.path, endsWith('/progress_days'));
      final offset = request.url.queryParameters['offset'] ?? '0';
      offsets.add(offset);
      final start = int.parse(offset);
      final count = start == 0 ? 1000 : 3;
      return _json(request, [
        for (var i = 0; i < count; i++)
          {
            'id': start + i,
            'user_id': _userId,
            'activity_date': '2026-01-01',
            'is_active': true,
          },
      ]);
    });

    final days = await ProgressRemoteDatasource(
      userContext: const _FakeUserContext(),
      client: client,
    ).getActiveDays();

    expect(days, hasLength(1003));
    expect(offsets, ['0', '1000']);
  });

  test('a short first page needs a single request', () async {
    var calls = 0;
    final client = _clientFor((request) async {
      calls++;
      return _json(request, [
        {
          'id': 1,
          'user_id': _userId,
          'activity_date': '2026-01-01',
          'is_active': true,
        },
      ]);
    });

    final days = await ProgressRemoteDatasource(
      userContext: const _FakeUserContext(),
      client: client,
    ).getActiveDays();

    expect(days, hasLength(1));
    expect(calls, 1);
  });

  test('supplemental lists are paged and keep every row', () async {
    final pagesByTable = <String, List<String>>{};
    final client = _clientFor((request) async {
      final table = request.url.pathSegments.last;
      final offset = request.url.queryParameters['offset'] ?? '0';
      pagesByTable.putIfAbsent(table, () => []).add(offset);
      final start = int.parse(offset);
      // `mnemonics` has more than one page; the other tables are short.
      final count = table == 'mnemonics' ? (start == 0 ? 1000 : 2) : 1;
      return _json(request, [
        for (var i = 0; i < count; i++)
          switch (table) {
            'abbreviations' => {
              'id': start + i,
              'subject_id': null,
              'short_form': 'BP',
              'full_form': 'Blood pressure',
            },
            'procedures' => {
              'id': start + i,
              'subject_id': null,
              'title': 'Procedure',
              'file_path': '',
            },
            _ => {
              'id': start + i,
              'subject_id': null,
              'title': 'Mnemonic',
              'file_path': '',
              'description': '',
            },
          },
      ]);
    });

    final items = await SupplementalRemoteDatasource(client: client).getItems();

    expect(items.where((item) => item.kind == 'mnemonic'), hasLength(1002));
    expect(items.where((item) => item.kind == 'abbreviation'), hasLength(1));
    expect(items.where((item) => item.kind == 'procedure'), hasLength(1));
    expect(pagesByTable['mnemonics'], ['0', '1000']);
    expect(pagesByTable['abbreviations'], ['0']);
  });
}
