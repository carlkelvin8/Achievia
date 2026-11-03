import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/presentation/widgets/supplementals/abbreviation_list.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<TextSpan> leaves(TextSpan root) {
  final out = <TextSpan>[];
  void walk(InlineSpan s) {
    if (s is TextSpan) {
      if (s.text != null) out.add(s);
      for (final c in s.children ?? const <InlineSpan>[]) {
        walk(c);
      }
    }
  }

  walk(root);
  return out;
}

void main() {
  test('em text is italic and no tag stays in the text', () {
    final spans = leaves(
      InlineHtml.span('<em>Yersinia pestis</em>', const TextStyle()),
    );
    expect(spans.map((s) => s.text).join(), 'Yersinia pestis');
    expect(spans.single.style?.fontStyle, FontStyle.italic);
  });

  test('only the tagged part is italic', () {
    final spans = leaves(
      InlineHtml.span('Infection by <em>E. coli</em> in urine', null),
    );
    expect(spans.map((s) => s.text).toList(), [
      'Infection by ',
      'E. coli',
      ' in urine',
    ]);
    expect(spans[0].style?.fontStyle, isNot(FontStyle.italic));
    expect(spans[1].style?.fontStyle, FontStyle.italic);
    expect(spans[2].style?.fontStyle, isNot(FontStyle.italic));
  });

  test('entities and unknown tags', () {
    expect(InlineHtml.plain('&beta;2-macroglobulin'), 'β2-macroglobulin');
    expect(InlineHtml.plain('Waldenstr&ouml;m'), 'Waldenström');
    expect(InlineHtml.plain('&unknownthing;'), '&unknownthing;');
    expect(InlineHtml.plain('3,3&acute;-diiodo'), '3,3´-diiodo');
    expect(InlineHtml.plain('x&sup2;'), 'x²');
    expect(InlineHtml.plain('A &amp; B &#946; &#x3b2;'), 'A & B β β');
    expect(InlineHtml.plain('<span class="x">kept</span>'), 'kept');
    expect(InlineHtml.plain('<i>a</i><br/>b'), 'a\nb');
  });

  testWidgets('abbreviation rows render <em> without showing the tag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AbbreviationList(
            items: [
              MedicalAbbreviation(
                abbreviation: 'YP',
                expansion: '<em>Yersinia pestis</em>',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('<em>', findRichText: true), findsNothing);
    expect(find.textContaining('</em>', findRichText: true), findsNothing);
    expect(
      find.textContaining('Yersinia pestis', findRichText: true),
      findsOneWidget,
    );
  });
}
