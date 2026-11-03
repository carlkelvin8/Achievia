import 'dart:async';

import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_host.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const reminder = "Hello, Ana! It's already 8:00 PM. Time to take a rest!";
const generic = "Hello! It's already 8:00 PM. Time to take a rest!";

final testUser = StateProvider<String?>((ref) => 'a');

class Fixture {
  Fixture({this.start = const StartTime(19, 59, 30), this.withProfile = true});

  final StartTime start;
  final bool withProfile;
  late DateTime now = DateTime(2026, 3, 10, start.h, start.m, start.s);
  final navigatorKey = GlobalKey<NavigatorState>();
  final Widget home = const SizedBox();

  Future<void> pump(WidgetTester t, {Widget? body}) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          taskClockProvider.overrideWithValue(() => now),
          sleepTimeUserProvider.overrideWith((ref) => ref.watch(testUser)),
          if (withProfile)
            profileProvider.overrideWith(
              (ref) async => const ProfileEntity(firstName: 'Ana'),
            ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              SleepReminderHost(navigatorKey: navigatorKey, child: child!),
          home: Scaffold(body: body ?? home),
        ),
      ),
    );
    if (withProfile) {
      ProviderScope.containerOf(
        t.element(find.byType(Scaffold)),
      ).read(profileProvider);
    }
    await settle(t);
  }

  /// Lets async hydration and scheduling finish without moving the clock.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.pump();
    }
  }

  Future<void> advance(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(d);
  }

  ProviderContainer container(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byType(Scaffold)));
}

class StartTime {
  const StartTime(this.h, this.m, this.s);
  final int h, m, s;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('appears at the configured time with the first name and '
      'auto-dismisses after exactly thirty seconds', (t) async {
    final f = Fixture();
    await f.pump(t);
    expect(find.text(reminder), findsNothing);

    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);

    await f.advance(t, const Duration(seconds: 29));
    expect(find.text(reminder), findsOneWidget);
    await f.advance(t, const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text(reminder), findsNothing);
  });

  testWidgets('falls back to a generic greeting without a usable name', (
    t,
  ) async {
    final f = Fixture(withProfile: false);
    await f.pump(t);
    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(generic), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets('recurs the next day and never twice for one occurrence', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();

    await f.advance(t, const Duration(hours: 12));
    expect(find.text(reminder), findsNothing);
    await f.advance(t, const Duration(hours: 12));
    expect(find.text(reminder), findsOneWidget);
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets(
    'taps never dismiss it; controls work again after thirty seconds',
    (t) async {
      final f = Fixture();
      var taps = 0;
      await f.pump(
        t,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Skip'),
          ),
        ),
      );
      await f.advance(t, const Duration(seconds: 30));
      expect(find.text(reminder), findsOneWidget);

      // Outside taps (even repeated) and taps on the card itself.
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Skip'), warnIfMissed: false);
        await t.tap(find.text(reminder), warnIfMissed: false);
        await f.advance(t, const Duration(seconds: 1));
      }
      expect(taps, 0, reason: 'the screen below is blocked');
      expect(find.text(reminder), findsOneWidget, reason: 'not dismissed');

      // Tapping did not restart the countdown: 3 s passed, 27 s are left.
      await f.advance(t, const Duration(seconds: 27));
      await t.pumpAndSettle();
      expect(find.text(reminder), findsNothing);

      await t.tap(find.text('Skip'));
      expect(taps, 1);
    },
  );

  testWidgets('changing the Sleep Time reschedules and drops the old time', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    await f
        .container(t)
        .read(sleepTimeProvider.notifier)
        .save(const TimeOfDay(hour: 21, minute: 0));
    await f.settle(t);

    await f.advance(t, const Duration(seconds: 30)); // old 8:00 PM passes
    expect(find.textContaining('Time to take a rest'), findsNothing);

    await f.advance(t, const Duration(hours: 1));
    expect(
      find.text("Hello, Ana! It's already 9:00 PM. Time to take a rest!"),
      findsOneWidget,
    );
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets('logout removes the visible reminder and cancels the schedule', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);

    f.container(t).read(testUser.notifier).state = null;
    await t.pump();
    await f.settle(t);
    expect(find.text(reminder), findsNothing);

    await f.advance(t, const Duration(days: 1, hours: 1));
    expect(find.textContaining('Time to take a rest'), findsNothing);
  });

  testWidgets('account switch uses the new account time and state', (t) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_b_hour': 21,
      'sleep_time_b_minute': 30,
    });
    final f = Fixture();
    await f.pump(t);

    f.container(t).read(testUser.notifier).state = 'b';
    await t.pump();
    await f.settle(t);

    await f.advance(t, const Duration(seconds: 30)); // a's 8:00 PM
    expect(find.textContaining('Time to take a rest'), findsNothing);
    await f.advance(t, const Duration(hours: 1, minutes: 30));
    expect(
      find.text("Hello, Ana! It's already 9:30 PM. Time to take a rest!"),
      findsOneWidget,
    );
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets('disposing the app removes the reminder and its timers', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    expect(find.text(reminder), findsNothing);
    await t.pump(const Duration(days: 2)); // no timer or callback survives
  });

  testWidgets('replaces a visible welcome message instead of stacking', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    final slot = f.container(t).read(toastSlotProvider);
    final welcome = WelcomeToastController(slot: slot);
    welcome.showIn(f.navigatorKey.currentState!.overlay, 'Welcome back!');
    await t.pump();
    expect(find.text('Welcome back!'), findsOneWidget);

    await f.advance(t, const Duration(seconds: 30));
    expect(find.text('Welcome back!'), findsNothing);
    expect(welcome.isShowing, isFalse);
    expect(find.text(reminder), findsOneWidget);

    // While the reminder is up, a welcome message is not shown on top of it.
    welcome.showIn(f.navigatorKey.currentState!.overlay, 'Welcome back!');
    await t.pump();
    expect(find.text('Welcome back!'), findsNothing);
    expect(find.text(reminder), findsOneWidget);

    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets('shows above an open dialog without touching navigation', (
    t,
  ) async {
    final f = Fixture();
    await f.pump(t);
    var pressed = 0;
    showDialog<void>(
      context: f.navigatorKey.currentContext!,
      builder: (_) => AlertDialog(
        content: const Text('Leave exam?'),
        actions: [
          TextButton(onPressed: () => pressed++, child: const Text('Yes')),
        ],
      ),
    );
    await t.pumpAndSettle();
    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);

    await t.tap(find.text('Yes'), warnIfMissed: false);
    await t.pump();
    expect(pressed, 0);
    expect(find.text(reminder), findsOneWidget);

    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
    // Only the reminder went away: the dialog below is still there and works.
    expect(find.text(reminder), findsNothing);
    expect(find.text('Leave exam?'), findsOneWidget);
    await t.tap(find.text('Yes'));
    expect(pressed, 1);
  });

  testWidgets('does not disturb a running exam screen', (t) async {
    final f = Fixture();
    final exam = ExamProbe();
    addTearDown(exam.dispose);
    await f.pump(t, body: ExamHarness(probe: exam));
    await t.tap(find.text('Next'));
    await t.pump();
    final before = exam.snapshot();
    final remainingBefore = exam.remaining.value;

    await f.advance(t, const Duration(seconds: 30));
    expect(find.text(reminder), findsOneWidget);
    // A tap on the Skip button while the reminder is up must not activate it.
    await t.tap(find.text('Skip'), warnIfMissed: false);
    await t.pump();
    expect(exam.snapshot(), before);
    expect(find.text(reminder), findsOneWidget);
    await f.advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
    expect(find.text(reminder), findsNothing);

    // Timer kept running independently through the whole time.
    expect(exam.remaining.value, lessThan(remainingBefore));
    expect(exam.snapshot(), before);

    // Normal interaction resumes immediately.
    await t.tap(find.text('Skip'));
    expect(exam.skipped, before.skipped + 1);
  });
}

/// Stand-in for the exam state that the reminder must never touch.
class ExamProbe {
  int question = 1;
  int score = 0;
  int skipped = 0;
  int answers = 0;
  final remaining = ValueNotifier<int>(3600);

  ({int question, int score, int skipped, int answers}) snapshot() =>
      (question: question, score: score, skipped: skipped, answers: answers);

  void dispose() => remaining.dispose();
}

class ExamHarness extends StatefulWidget {
  const ExamHarness({super.key, required this.probe});
  final ExamProbe probe;

  @override
  State<ExamHarness> createState() => _ExamHarnessState();
}

class _ExamHarnessState extends State<ExamHarness> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => widget.probe.remaining.value--,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.probe;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => p.answers++,
          child: const Text('Answer'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => p.skipped++,
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => p.question++,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
