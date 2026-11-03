import 'package:achievia/core/utils/module_file_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('resolves uploaded paths and preserves full signed URLs', () {
    expect(
      resolveModuleFileUri('/uploads/Study notes.docx')!.path,
      '/storage/v1/object/public/admin/uploads/Study%20notes.docx',
    );
    const full = 'https://example.com/notes.pdf?token=abc';
    expect(resolveModuleFileUri(full).toString(), full);
    expect(resolveModuleFileUri(null), isNull);
    expect(resolveModuleFileUri('javascript:alert(1)'), isNull);
  });

  test('available file passes the preview check', () async {
    final client = MockClient((request) async {
      expect(request.method, 'HEAD');
      return http.Response('', 200);
    });
    addTearDown(client.close);
    await checkModuleFileAccess(
      Uri.parse('https://example.com/notes.docx'),
      client,
    );
  });

  test('admin PDF URL is preserved and opens as a PDF', () async {
    const url =
        'https://bcxvjfxrdfzqzmoseegx.storage.supabase.co/storage/v1/object/public/admin/uploads/I9DO4Bqtnte3j15hJdAfpPLgKEhb1PFXiOsnHFXX.pdf';
    final client = MockClient(
      (_) async =>
          http.Response('', 200, headers: {'content-type': 'application/pdf'}),
    );
    addTearDown(client.close);
    expect(resolveModuleFileUri(url).toString(), url);
    expect(
      await checkModuleFileAccess(resolveModuleFileUri(url)!, client),
      isTrue,
    );
  });

  test(
    'recognizes PDF content without an extension and keeps DOCX separate',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          '',
          200,
          headers: {
            'content-type': request.url.path.endsWith('download')
                ? 'application/pdf; charset=binary'
                : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          },
        ),
      );
      addTearDown(client.close);
      expect(
        await checkModuleFileAccess(
          Uri.parse('https://example.com/download'),
          client,
        ),
        isTrue,
      );
      expect(
        await checkModuleFileAccess(
          Uri.parse('https://example.com/notes.docx'),
          client,
        ),
        isFalse,
      );
    },
  );

  for (final status in [400, 404, 403, 500]) {
    test('HTTP $status prevents launching a blank viewer', () async {
      final client = MockClient((_) async => http.Response('', status));
      addTearDown(client.close);
      await expectLater(
        checkModuleFileAccess(
          Uri.parse('https://example.com/notes.docx'),
          client,
        ),
        throwsA(isA<ModuleFileException>()),
      );
    });
  }
}
