import 'dart:io';

import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the official logo asset exists and its colors are inlined', () {
    final raw = File(logo).readAsStringSync();
    expect(raw, contains('<style>'), reason: 'the source uses CSS classes');
    final svg = inlineSimpleFillStyles(raw);
    expect(svg, isNot(contains('<style')));
    expect(svg, isNot(contains('class="cls-')));
    // Brand navy, brand cyan and white survive as real fills.
    expect(svg, contains('fill="#081351"'));
    expect(svg, contains('fill="#009dc5"'));
    expect(svg, contains('fill="#fff"'));
    expect(svg, contains('viewBox="0 0 2000 2000"'));
  });

  test('the login screen uses the official logo, not an icon', () {
    final source = File(
      'lib/presentation/screens/auth/login_screen.dart',
    ).readAsStringSync();
    expect(source, contains('InlineStyleSvg('));
    expect(source, contains('assetPath: logo'));
    expect(source, isNot(contains('Icons.school')));
  });

  testWidgets('the logo renders square, with the same box while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: InlineStyleSvg(
              key: ValueKey('logo'),
              assetPath: logo,
              width: 150,
              height: 150,
            ),
          ),
        ),
      ),
    );
    // The placeholder already has the final size: no layout jump.
    expect(
      tester.getSize(find.byKey(const ValueKey('logo'))),
      const Size(150, 150),
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(150, 150));
    expect(
      tester.getCenter(find.byType(SvgPicture)),
      tester.getCenter(find.byType(Scaffold)),
    );
    expect(tester.takeException(), isNull);
  });
}
