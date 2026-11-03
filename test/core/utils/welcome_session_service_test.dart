import 'package:achievia/core/utils/welcome_session_service.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<WelcomeSessionService> _newSession() async =>
    WelcomeSessionService(await SharedPreferences.getInstance());

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WelcomeSessionService', () {
    test('first launch hides, second and third show', () async {
      expect(await (await _newSession()).shouldShowWelcome('a'), isFalse);
      expect(await (await _newSession()).shouldShowWelcome('a'), isTrue);
      expect(await (await _newSession()).shouldShowWelcome('a'), isTrue);
    });

    test('key is user specific and accounts are independent', () async {
      expect(WelcomeSessionService.storageKey('u1'), 'welcome_launch_count_u1');
      final s = await _newSession();
      await s.shouldShowWelcome('A');
      final next = await _newSession();
      expect(await next.shouldShowWelcome('A'), isTrue);
      expect(await next.shouldShowWelcome('B'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('welcome_launch_count_A'), 2);
      expect(prefs.getInt('welcome_launch_count_B'), 1);
    });

    test('repeated and concurrent calls increment once per session', () async {
      final s = await _newSession();
      await Future.wait([
        s.registerLaunch('a'),
        s.registerLaunch('a'),
        s.shouldShowWelcome('a'),
      ]);
      await s.shouldShowWelcome('a');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('welcome_launch_count_a'), 1);
    });

    test('welcome is shown only once per session', () async {
      await (await _newSession()).registerLaunch('a');
      final s = await _newSession();
      expect(await s.shouldShowWelcome('a'), isTrue);
      expect(await s.shouldShowWelcome('a'), isFalse);
    });

    test('message uses first name or falls back', () {
      expect(
        WelcomeSessionService.buildMessage('Charlesjoven'),
        'Welcome back, Charlesjoven!\nKeep going, future RMT!',
      );
      for (final v in [null, '', '  ', 'null', 'Unknown', 'User']) {
        expect(
          WelcomeSessionService.buildMessage(v),
          'Welcome back!\nKeep going, future RMT!',
        );
      }
    });
  });

  group('WelcomeToast', () {
    late WelcomeToastController controller;
    late int taps;
    const msg = 'Hello\nthere';

    Future<void> pump(WidgetTester tester) async {
      taps = 0;
      controller = WelcomeToastController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Shown programmatically, like MainScreen does.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) controller.show(context, msg);
                });
                return ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('go'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('auto dismisses after ~5s and no timer is left', (t) async {
      await pump(t);
      expect(find.text(msg), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      expect(find.text(msg), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.text(msg), findsNothing);
      expect(controller.isShowing, isFalse);
    });

    testWidgets('first outside tap only dismisses; dashboard works after', (
      t,
    ) async {
      await pump(t);
      await t.tap(find.text('go'), warnIfMissed: false);
      await t.pump();
      expect(taps, 0);
      // Barrier ignores hits as soon as dismissal starts (mid fade-out).
      await t.tap(find.text('go'));
      expect(taps, 1);
      await t.pumpAndSettle();
      expect(find.text(msg), findsNothing);
      expect(controller.isShowing, isFalse);
      await t.tap(find.text('go'));
      expect(taps, 2);
    });

    testWidgets('no duplicate overlay; dismissNow/dispose remove it', (
      t,
    ) async {
      await pump(t);
      controller.show(t.element(find.byType(Scaffold)), msg);
      await t.pump();
      expect(find.text(msg), findsOneWidget);
      controller.dispose();
      await t.pump();
      expect(find.text(msg), findsNothing);
    });
  });

  group('WelcomeToastHost route scoping', () {
    late WelcomeToastController controller;
    late GlobalKey<NavigatorState> nav;
    const msg = 'Hello\nthere';

    Future<void> pumpApp(WidgetTester t) async {
      controller = WelcomeToastController();
      nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: WelcomeToastHost(
            controller: controller,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted && !controller.isShowing) {
                    controller.show(context, msg);
                  }
                });
                return const Scaffold(body: Text('home'));
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.text(msg), findsOneWidget);
    }

    testWidgets('pushing another route removes it immediately', (t) async {
      await pumpApp(t);
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('other')),
        ),
      );
      await t.pump(); // no settle: removal must not wait for fade or timer
      expect(controller.isShowing, isFalse);
      await t.pumpAndSettle();
      expect(find.text(msg), findsNothing);
      expect(find.text('other'), findsOneWidget);
      // Timer was cancelled: no callback fires after the original 5s.
      await t.pump(const Duration(seconds: 6));
    });

    testWidgets('a dialog removes it', (t) async {
      await pumpApp(t);
      showDialog<void>(
        context: nav.currentContext!,
        builder: (_) => const AlertDialog(content: Text('dlg')),
      );
      await t.pumpAndSettle();
      expect(find.text(msg), findsNothing);
      expect(find.text('dlg'), findsOneWidget);
    });

    testWidgets('disposing the host removes the entry and timer', (t) async {
      await pumpApp(t);
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(controller.isShowing, isFalse);
      expect(find.text(msg), findsNothing);
      await t.pump(const Duration(seconds: 6)); // no callback on disposed state
    });
  });
}
