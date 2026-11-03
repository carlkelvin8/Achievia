import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final flowUser = StateProvider<String?>((ref) => 'a');

/// End-to-end behaviour of the Sleep Time Reminder with the real notifier,
/// scheduler, host and overlay. Only the clock is fake, so no test waits for
/// real minutes.
class App {
  App(this.start);

  DateTime start;
  late DateTime now = start;
  final navigatorKey = GlobalKey<NavigatorState>();
  int homeTaps = 0;

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          taskClockProvider.overrideWithValue(() => now),
          sleepTimeUserProvider.overrideWith((ref) => ref.watch(flowUser)),
          profileProvider.overrideWith(
            (ref) async => const ProfileEntity(firstName: 'Ana'),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              SleepReminderHost(navigatorKey: navigatorKey, child: child!),
          home: Scaffold(
            body: TextButton(
              onPressed: () => homeTaps++,
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    );
    ProviderScope.containerOf(
      t.element(find.byType(Scaffold)),
    ).read(profileProvider);
    await settle(t);
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 10));
    }
  }

  ProviderContainer container(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byType(Scaffold).first));

  Future<void> advance(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(d);
    await t.pump();
  }

  /// Dismisses a visible reminder by letting its 30 seconds pass.
  Future<void> letItExpire(WidgetTester t) async {
    await advance(t, const Duration(seconds: 30));
    await t.pumpAndSettle();
  }

  Future<void> push(WidgetTester t, String label) async {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: Center(child: Text(label))),
      ),
    );
    await t.pumpAndSettle();
  }
}

Finder reminderText(String time) =>
    find.text("Hello, Ana! It's already $time. Time to take a rest!");

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a time set in the running app fires without a restart', (
    t,
  ) async {
    final app = App(DateTime(2026, 3, 10, 14, 0, 0));
    await app.pump(t);

    await app
        .container(t)
        .read(sleepTimeProvider.notifier)
        .save(const TimeOfDay(hour: 14, minute: 2));
    await app.settle(t);
    expect(find.textContaining('Time to take a rest'), findsNothing);

    await app.advance(t, const Duration(minutes: 1));
    expect(find.textContaining('Time to take a rest'), findsNothing);
    await app.advance(t, const Duration(minutes: 1));
    expect(reminderText('2:02 PM'), findsOneWidget);
    await app.letItExpire(t);
    expect(find.textContaining('Time to take a rest'), findsNothing);
  });

  testWidgets('changing the time twice leaves only the last schedule', (
    t,
  ) async {
    final app = App(DateTime(2026, 3, 10, 14, 0, 0));
    await app.pump(t);
    final notifier = app.container(t).read(sleepTimeProvider.notifier);

    await notifier.save(const TimeOfDay(hour: 14, minute: 1));
    await app.settle(t);
    await notifier.save(const TimeOfDay(hour: 14, minute: 3));
    await app.settle(t);

    await app.advance(t, const Duration(minutes: 1));
    expect(
      find.textContaining('Time to take a rest'),
      findsNothing,
      reason: 'the replaced 2:01 PM schedule must be gone',
    );
    await app.advance(t, const Duration(minutes: 2));
    expect(reminderText('2:03 PM'), findsOneWidget);
    await app.letItExpire(t);
  });

  testWidgets('a time that already passed waits for tomorrow', (t) async {
    final app = App(DateTime(2026, 3, 10, 14, 5, 0));
    await app.pump(t);

    await app
        .container(t)
        .read(sleepTimeProvider.notifier)
        .save(const TimeOfDay(hour: 14, minute: 0));
    await app.settle(t);

    await app.advance(t, const Duration(hours: 23));
    expect(find.textContaining('Time to take a rest'), findsNothing);
    await app.advance(t, const Duration(minutes: 55));
    expect(reminderText('2:00 PM'), findsOneWidget);
    await app.letItExpire(t);
  });

  testWidgets('AM/PM and midnight edges show the right clock time', (t) async {
    final cases = <(TimeOfDay, DateTime, String)>[
      (
        const TimeOfDay(hour: 0, minute: 0),
        DateTime(2026, 3, 10, 23, 59, 30),
        '12:00 AM',
      ),
      (
        const TimeOfDay(hour: 12, minute: 0),
        DateTime(2026, 3, 10, 11, 59, 30),
        '12:00 PM',
      ),
      (
        const TimeOfDay(hour: 23, minute: 59),
        DateTime(2026, 3, 10, 23, 58, 30),
        '11:59 PM',
      ),
      (
        const TimeOfDay(hour: 1, minute: 5),
        DateTime(2026, 3, 10, 1, 4, 30),
        '1:05 AM',
      ),
    ];
    for (final (time, start, label) in cases) {
      SharedPreferences.setMockInitialValues({});
      final app = App(start);
      await app.pump(t);
      await app.container(t).read(sleepTimeProvider.notifier).save(time);
      await app.settle(t);

      await app.advance(t, const Duration(seconds: 29));
      expect(
        find.textContaining('Time to take a rest'),
        findsNothing,
        reason: '$label must not fire early',
      );
      await app.advance(t, const Duration(seconds: 2));
      expect(reminderText(label), findsOneWidget, reason: label);
      await app.letItExpire(t);
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('midnight rolls into the next day exactly once', (t) async {
    final app = App(DateTime(2026, 3, 10, 23, 59, 30));
    await app.pump(t);
    await app
        .container(t)
        .read(sleepTimeProvider.notifier)
        .save(const TimeOfDay(hour: 0, minute: 0));
    await app.settle(t);

    await app.advance(t, const Duration(seconds: 31));
    expect(reminderText('12:00 AM'), findsOneWidget);
    await app.letItExpire(t);

    await app.advance(t, const Duration(hours: 23));
    expect(find.textContaining('Time to take a rest'), findsNothing);
    await app.advance(t, const Duration(hours: 1));
    expect(reminderText('12:00 AM'), findsOneWidget);
    await app.letItExpire(t);
  });

  testWidgets('the saved time is reloaded after an app restart', (t) async {
    final first = App(DateTime(2026, 3, 10, 9, 0, 0));
    await first.pump(t);
    await first
        .container(t)
        .read(sleepTimeProvider.notifier)
        .save(const TimeOfDay(hour: 21, minute: 15));
    await first.settle(t);

    // The whole app is torn down, then started again from storage.
    await t.pumpWidget(const SizedBox());
    final second = App(DateTime(2026, 3, 10, 21, 14, 30));
    await second.pump(t);
    expect(
      second.container(t).read(sleepTimeProvider),
      const TimeOfDay(hour: 21, minute: 15),
    );

    await second.advance(t, const Duration(seconds: 31));
    expect(reminderText('9:15 PM'), findsOneWidget);
    await second.letItExpire(t);
  });

  testWidgets('it appears over every screen the user can be on', (t) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 20,
      'sleep_time_a_minute': 0,
    });
    final app = App(DateTime(2026, 3, 10, 19, 59, 30));
    await app.pump(t);

    final screens = [
      'Home',
      'Question Bank',
      'Take an Exam',
      'Mock Boards',
      'Study Mode',
      'Profile',
      'Settings',
      'Messages',
    ];
    for (var i = 0; i < screens.length; i++) {
      if (i > 0) await app.push(t, screens[i]);
      // Move to just before the next 8:00 PM and let it arrive.
      if (i == 0) {
        await app.advance(t, const Duration(seconds: 29));
      } else {
        // 8:00:31 PM after the previous 30-second reminder -> 7:59:59 PM.
        await app.advance(
          t,
          const Duration(hours: 23, minutes: 59, seconds: 28),
        );
      }
      expect(
        find.textContaining('Time to take a rest'),
        findsNothing,
        reason: '${screens[i]}: not before the time',
      );
      await app.advance(t, const Duration(seconds: 2));
      expect(
        reminderText('8:00 PM'),
        findsOneWidget,
        reason: 'reminder over ${screens[i]}',
      );
      expect(
        find.text(screens[i]),
        findsWidgets,
        reason: 'the screen underneath is untouched',
      );
      await app.letItExpire(t);
    }
  });

  testWidgets('one occurrence shows one overlay, even after route changes', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 20,
      'sleep_time_a_minute': 0,
    });
    final app = App(DateTime(2026, 3, 10, 19, 59, 59));
    await app.pump(t);
    await app.advance(t, const Duration(seconds: 2));
    expect(reminderText('8:00 PM'), findsOneWidget);

    await app.push(t, 'Question Bank');
    await app.advance(t, const Duration(milliseconds: 500));
    expect(
      find.textContaining('Time to take a rest').evaluate().length,
      lessThanOrEqualTo(1),
    );

    await app.letItExpire(t);
    // No repeat later the same day, no matter how often it rebuilds.
    for (var i = 0; i < 5; i++) {
      await app.advance(t, const Duration(hours: 1));
      expect(find.textContaining('Time to take a rest'), findsNothing);
    }
  });

  testWidgets('tapping never dismisses it nor reaches the screen below', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 20,
      'sleep_time_a_minute': 0,
    });
    final app = App(DateTime(2026, 3, 10, 19, 59, 59));
    await app.pump(t);
    await app.advance(t, const Duration(seconds: 2));
    expect(reminderText('8:00 PM'), findsOneWidget);

    await t.tap(find.text('Home'), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 400));
    expect(reminderText('8:00 PM'), findsOneWidget);
    expect(app.homeTaps, 0, reason: 'the screen below is blocked');

    await app.letItExpire(t);
    expect(reminderText('8:00 PM'), findsNothing);
    await t.tap(find.text('Home'));
    expect(app.homeTaps, 1, reason: 'controls work again afterwards');
  });

  testWidgets('a different account does not inherit the previous schedule', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 20,
      'sleep_time_a_minute': 0,
      'sleep_time_b_hour': 22,
      'sleep_time_b_minute': 0,
    });
    final app = App(DateTime(2026, 3, 10, 19, 59, 30));
    await app.pump(t);
    app.container(t).read(flowUser.notifier).state = 'b';
    await app.settle(t);

    await app.advance(t, const Duration(seconds: 31));
    expect(
      find.textContaining('Time to take a rest'),
      findsNothing,
      reason: "account b sleeps at 10 PM, not account a's 8 PM",
    );
    await app.advance(t, const Duration(hours: 2));
    expect(reminderText('10:00 PM'), findsOneWidget);
    await app.letItExpire(t);
  });

  testWidgets('set a time, see it, set another a few minutes later, see it', (
    t,
  ) async {
    final app = App(DateTime(2026, 3, 10, 14, 0, 0));
    await app.pump(t);
    final notifier = app.container(t).read(sleepTimeProvider.notifier);

    await notifier.save(const TimeOfDay(hour: 14, minute: 2));
    await app.settle(t);
    await app.advance(t, const Duration(minutes: 2));
    expect(reminderText('2:02 PM'), findsOneWidget);
    await app.letItExpire(t);

    // Second manual test the same day (today's first reminder already fired).
    await notifier.save(const TimeOfDay(hour: 14, minute: 5));
    await app.settle(t);
    await app.advance(t, const Duration(minutes: 1));
    expect(find.textContaining('Time to take a rest'), findsNothing);
    await app.advance(t, const Duration(minutes: 2));
    expect(reminderText('2:05 PM'), findsOneWidget);
    await app.letItExpire(t);

    // And it still shows nothing extra afterwards.
    await app.advance(t, const Duration(hours: 1));
    expect(find.textContaining('Time to take a rest'), findsNothing);
  });
}
