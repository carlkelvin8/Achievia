import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const message = 'Welcome back, QA!\nKeep going, future RMT!';

Future<void> pump(
  WidgetTester tester,
  Size size, {
  required VoidCallback onFinished,
  VoidCallback? onUnderTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: TextButton(
                onPressed: onUnderTap ?? () {},
                child: const Text('under'),
              ),
            ),
            WelcomeToast(message: message, onFinished: onFinished),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final size in const [
    Size(320, 568),
    Size(412, 915),
    Size(800, 1280),
    Size(915, 412),
  ]) {
    testWidgets('the greeting is exactly centered on $size', (tester) async {
      await pump(tester, size, onFinished: () {});
      final card = tester.getRect(find.byKey(const ValueKey('welcome-card')));
      expect(card.center.dx, closeTo(size.width / 2, 0.5));
      expect(card.center.dy, closeTo(size.height / 2, 0.5));
      expect(card.left, greaterThan(0));
      expect(card.right, lessThan(size.width));
      await tester.pump(const Duration(seconds: 6));
    });
  }

  testWidgets('a gray, semi-transparent backdrop covers the screen', (
    tester,
  ) async {
    await pump(tester, const Size(400, 800), onFinished: () {});
    final backdrop = find.byKey(const ValueKey('welcome-backdrop'));
    expect(tester.getRect(backdrop), const Rect.fromLTWH(0, 0, 400, 800));
    final color = tester.widget<ColoredBox>(backdrop).color;
    expect(color.a, inExclusiveRange(0.2, 0.9));
    expect(color.r, closeTo(color.g, 0.02));
    expect(color.g, closeTo(color.b, 0.02));
    // The greeting itself stays on the bright surface color.
    final card = tester.widget<Material>(
      find.byKey(const ValueKey('welcome-card')),
    );
    expect(card.color, isNot(equals(color)));
    expect(card.color!.a, 1.0);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('it still ends after five seconds', (tester) async {
    var finished = 0;
    await pump(tester, const Size(400, 800), onFinished: () => finished++);
    await tester.pump(const Duration(seconds: 4));
    expect(finished, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });

  testWidgets('a tap dismisses it and never reaches the screen below', (
    tester,
  ) async {
    var finished = 0;
    var underTaps = 0;
    await pump(
      tester,
      const Size(400, 800),
      onFinished: () => finished++,
      onUnderTap: () => underTaps++,
    );
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(underTaps, 0);
  });
}
