import 'package:achievia/core/utils/alert_sound.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_overlay.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class CountingSound implements AlertSound {
  CountingSound({this.fail = false});
  final bool fail;
  int plays = 0;

  @override
  Future<void> play() async {
    plays++;
    if (fail) throw Exception('no audio device');
  }
}

const message = "Hello, Ana! It's already 8:00 PM. Time to take a rest!";

class Rig {
  Rig({AlertSound? sound}) : sound = sound ?? CountingSound();

  final AlertSound sound;
  DateTime now = DateTime(2026, 3, 10, 20);
  late final controller = SleepReminderOverlayController(
    slot: ToastSlot(),
    sound: sound,
    clock: () => now,
  );
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pump(WidgetTester t, {Size size = const Size(400, 800)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Center(child: Text('screen'))),
      ),
    );
  }

  bool show() => controller.showIn(navigatorKey.currentState!.overlay, message);

  Future<void> advance(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(d);
  }
}

void main() {
  group('layout', () {
    for (final size in const [
      Size(320, 568), // small phone
      Size(412, 915), // large phone
      Size(800, 1280), // tablet
      Size(915, 412), // landscape
    ]) {
      testWidgets('the card is exactly centered on $size', (t) async {
        final rig = Rig();
        await rig.pump(t, size: size);
        rig.show();
        await t.pump();

        final card = t.getRect(
          find.byKey(const ValueKey('sleep-reminder-card')),
        );
        expect(card.center.dx, closeTo(size.width / 2, 0.5));
        expect(card.center.dy, closeTo(size.height / 2, 0.5));
        // Fits the screen with a margin.
        expect(card.left, greaterThan(0));
        expect(card.right, lessThan(size.width));
        rig.controller.dispose();
      });
    }

    testWidgets('a semi-transparent gray backdrop covers the whole screen', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      await t.pump();
      final backdrop = find.byKey(const ValueKey('sleep-reminder-backdrop'));
      expect(t.getRect(backdrop), const Rect.fromLTWH(0, 0, 400, 800));
      final color = t.widget<ColoredBox>(backdrop).color;
      expect(color.a, inExclusiveRange(0.2, 0.9), reason: 'semi-transparent');
      expect(color.r, closeTo(color.g, 0.02), reason: 'gray');
      expect(color.g, closeTo(color.b, 0.02), reason: 'gray');
      rig.controller.dispose();
    });
  });

  group('duration', () {
    testWidgets('stays exactly 30 seconds, then disappears', (t) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      await t.pump();
      await rig.advance(t, const Duration(milliseconds: 29900));
      expect(find.text(message), findsOneWidget);
      await rig.advance(t, const Duration(milliseconds: 100));
      expect(find.text(message), findsNothing);
      expect(rig.controller.isShowing, isFalse);
    });

    testWidgets('a long background that outlasts it removes it on resume', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      await t.pump();

      // The app was paused: no timer ran, but 45 s of real time passed.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      rig.now = rig.now.add(const Duration(seconds: 45));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.text(message), findsNothing, reason: 'no stale card');
    });

    testWidgets('a short background does not restart the 30 seconds', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      await t.pump();

      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      rig.now = rig.now.add(const Duration(seconds: 6));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.text(message), findsOneWidget);

      // Only the remaining 24 seconds are left.
      await rig.advance(t, const Duration(seconds: 24));
      await t.pump();
      expect(find.text(message), findsNothing);
    });
  });

  group('one occurrence, one card, one sound', () {
    testWidgets('a duplicate trigger is ignored, sound plays once', (t) async {
      final sound = CountingSound();
      final rig = Rig(sound: sound);
      await rig.pump(t);
      expect(rig.show(), isTrue);
      expect(rig.show(), isFalse);
      expect(rig.show(), isFalse);
      await t.pump();
      expect(find.text(message), findsOneWidget);
      expect(sound.plays, 1);

      await rig.advance(t, const Duration(seconds: 30));
      expect(find.text(message), findsNothing);

      // The next occurrence is a new card with its own sound.
      expect(rig.show(), isTrue);
      await t.pump();
      expect(sound.plays, 2);
      rig.controller.dispose();
    });

    testWidgets('a failing sound never breaks the reminder', (t) async {
      final rig = Rig(sound: CountingSound(fail: true));
      await rig.pump(t);
      expect(rig.show(), isTrue);
      await t.pump();
      expect(find.text(message), findsOneWidget);
      expect(t.takeException(), isNull);
      await rig.advance(t, const Duration(seconds: 30));
      expect(find.text(message), findsNothing);
    });
  });

  group('cleanup', () {
    testWidgets('dispose removes it; no timer or callback survives', (t) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      await t.pump();
      rig.controller.dispose();
      await t.pump();
      expect(find.text(message), findsNothing);
      await rig.advance(t, const Duration(minutes: 5));
      expect(t.takeException(), isNull);
    });

    testWidgets('expiry removes only the reminder, never other entries', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      rig.show();
      final other = OverlayEntry(builder: (_) => const Text('other overlay'));
      rig.navigatorKey.currentState!.overlay!.insert(other);
      await t.pump();

      await rig.advance(t, const Duration(seconds: 30));
      expect(find.text(message), findsNothing);
      expect(find.text('other overlay'), findsOneWidget);
      expect(find.text('screen'), findsOneWidget);
      other.remove();
      other.dispose();
    });
  });

  group('back button (app with a router)', () {
    testWidgets('cannot dismiss the reminder or pop the screen below', (
      t,
    ) async {
      final sound = CountingSound();
      var now = DateTime(2026, 3, 10, 20);
      final controller = SleepReminderOverlayController(
        slot: ToastSlot(),
        sound: sound,
        clock: () => now,
      );
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: navigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('first')),
          ),
          GoRoute(
            path: '/second',
            builder: (_, _) => const Scaffold(body: Text('second')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push('/second');
      await t.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      controller.showIn(navigatorKey.currentState!.overlay, message);
      await t.pump();

      // System back during the countdown: swallowed.
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.text(message), findsOneWidget);

      now = now.add(const Duration(seconds: 30));
      await t.pump(const Duration(seconds: 30));
      expect(find.text(message), findsNothing);

      // Afterwards back works normally again.
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('first'), findsOneWidget);
    });
  });
}
