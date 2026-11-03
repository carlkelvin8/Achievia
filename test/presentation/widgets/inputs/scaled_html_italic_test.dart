import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('<em> uses the real Poppins italic face, not upright glyphs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
          home: Scaffold(
            body: DefaultTextStyle(
              style: GoogleFonts.poppins(),
              child: ScaledHtml(
                data:
                    '<p>1. What is the optimal temperature range for '
                    '<em>Campylobacter</em> species growth?</p>',
                style: {'p': Style(fontWeight: FontWeight.w600)},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextStyle? styleOf(String word) {
      TextStyle? found;
      for (final p in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        p.text.visitChildren((span) {
          if (span is TextSpan && (span.text ?? '').contains(word)) {
            found = span.style;
          }
          return true;
        });
      }
      return found;
    }

    final italic = styleOf('Campylobacter')!;
    expect(italic.fontStyle, FontStyle.italic);
    expect(italic.fontFamily, contains('italic'));
    expect(styleOf('optimal')!.fontFamily, isNot(contains('italic')));
  });

  testWidgets('bold markup is drawn in the regular weight, italics kept', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
          home: Scaffold(
            body: DefaultTextStyle(
              style: GoogleFonts.poppins(),
              child: const ScaledHtml(
                data:
                    '<p>Features of <strong><em>Nocardia</em></strong> '
                    '<b>brasiliensis</b> and '
                    '<span style="font-weight: 700;">tetani</span> '
                    'CO<sub>2</sub></p><h3>Heading</h3>',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final styles = <String, TextStyle?>{};
    for (final p in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      p.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').trim().isNotEmpty) {
          styles[span.text!.trim()] = span.style;
        }
        return true;
      });
    }

    for (final word in ['Nocardia', 'brasiliensis', 'tetani', 'Heading']) {
      final style = styles.entries
          .firstWhere((e) => e.key.contains(word))
          .value;
      final weight = style?.fontWeight ?? FontWeight.normal;
      expect(weight.value, lessThanOrEqualTo(400), reason: word);
      expect(style?.fontFamily ?? '', isNot(contains('700')), reason: word);
    }
    final italic = styles.entries
        .firstWhere((e) => e.key.contains('Nocardia'))
        .value!;
    expect(italic.fontStyle, FontStyle.italic);
    expect(italic.fontFamily, contains('italic'));
  });
}
