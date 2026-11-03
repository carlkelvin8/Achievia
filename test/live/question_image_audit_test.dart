// Run after `node scripts/audit_question_images.mjs`:
// flutter test --dart-define=RUN_LIVE_IMAGE_AUDIT=true test/live/question_image_audit_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

class _LiveHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every audited question attachment decodes as a Flutter image',
    () async {
      final report =
          jsonDecode(
                await File('docs/audits/question_images.json').readAsString(),
              )
              as Map<String, dynamic>;
      final urls = <String>{
        for (final deck in report['decks'] as List)
          for (final question in deck['questions'] as List)
            question['url'] as String,
      }.toList();
      expect(urls, isNotEmpty);
      final client = HttpOverrides.runWithHttpOverrides(
        () => HttpClient(),
        _LiveHttpOverrides(),
      );
      try {
        for (var start = 0; start < urls.length; start += 8) {
          await Future.wait(
            urls.skip(start).take(8).map((url) async {
              final request = await client.getUrl(Uri.parse(url));
              final response = await request.close();
              expect(response.statusCode, 200, reason: url);
              final bytes = BytesBuilder();
              await for (final chunk in response) {
                bytes.add(chunk);
              }
              final codec = await ui.instantiateImageCodec(
                bytes.takeBytes(),
                targetWidth: 100,
              );
              try {
                final frame = await codec.getNextFrame();
                expect(frame.image.width, greaterThan(0), reason: url);
                expect(frame.image.height, greaterThan(0), reason: url);
                frame.image.dispose();
              } finally {
                codec.dispose();
              }
            }),
          ).timeout(const Duration(seconds: 60));
        }
      } finally {
        client.close(force: true);
      }
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_IMAGE_AUDIT'),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
