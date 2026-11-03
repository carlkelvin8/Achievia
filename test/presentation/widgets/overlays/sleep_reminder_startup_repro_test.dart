import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final startupUser = StateProvider<String?>((ref) => null);

/// Real startup order seen on a device: the Sleep Time provider is built while
/// no account is resolved yet, then the account resolves. The stored time of
/// that account must be what the scheduler ends up using, not the default.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 20,
      'sleep_time_a_minute': 30,
    });
  });

  testWidgets('the stored time wins when the account resolves late', (t) async {
    var now = DateTime(2026, 3, 10, 20, 29, 0);
    final navigatorKey = GlobalKey<NavigatorState>();

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          taskClockProvider.overrideWithValue(() => now),
          sleepTimeUserProvider.overrideWith((ref) => ref.watch(startupUser)),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              SleepReminderHost(navigatorKey: navigatorKey, child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await t.pump();
    final container = ProviderScope.containerOf(
      t.element(find.byType(Scaffold)),
    );

    // The account resolves after the provider already finished for "nobody".
    container.read(startupUser.notifier).state = 'a';
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 10));
    }

    expect(
      container.read(sleepTimeProvider),
      const TimeOfDay(hour: 20, minute: 30),
    );

    now = DateTime(2026, 3, 10, 20, 30, 0);
    await t.pump(const Duration(minutes: 1));
    await t.pump();
    expect(
      find.textContaining('Time to take a rest'),
      findsOneWidget,
      reason: 'the reminder must fire at the stored time, not at the default',
    );
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
  });

  testWidgets('a reset during the first read never leaves the default', (
    t,
  ) async {
    var now = DateTime(2026, 3, 10, 20, 29, 0);
    final navigatorKey = GlobalKey<NavigatorState>();

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          taskClockProvider.overrideWithValue(() => now),
          sleepTimeUserProvider.overrideWith((ref) => 'a'),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              SleepReminderHost(navigatorKey: navigatorKey, child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      t.element(find.byType(Scaffold)),
    );
    // The account-resolved reset lands while the first read is in flight and
    // is only applied lazily, on the next read.
    container.invalidate(sleepTimeProvider);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 10));
    }

    now = DateTime(2026, 3, 10, 20, 30, 0);
    await t.pump(const Duration(minutes: 1));
    await t.pump();
    expect(
      find.textContaining('Time to take a rest'),
      findsOneWidget,
      reason: 'must fire at the stored 8:30 PM, not the default 8:00 PM',
    );
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
  });

  testWidgets('no spurious catch-up for the default time at startup', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_a_hour': 22,
      'sleep_time_a_minute': 0,
    });
    // Started 5 minutes after the DEFAULT 8:00 PM, but the user sleeps at 10 PM.
    var now = DateTime(2026, 3, 10, 20, 5, 0);
    final navigatorKey = GlobalKey<NavigatorState>();

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          taskClockProvider.overrideWithValue(() => now),
          sleepTimeUserProvider.overrideWith((ref) => 'a'),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              SleepReminderHost(navigatorKey: navigatorKey, child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    ProviderScope.containerOf(
      t.element(find.byType(Scaffold)),
    ).invalidate(sleepTimeProvider);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 10));
    }

    expect(
      find.textContaining('Time to take a rest'),
      findsNothing,
      reason: 'the default 8:00 PM must never be used for a catch-up',
    );

    now = DateTime(2026, 3, 10, 22, 0, 0);
    await t.pump(const Duration(hours: 2));
    await t.pump();
    expect(find.textContaining("It's already 10:00 PM"), findsOneWidget);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
  });
}
