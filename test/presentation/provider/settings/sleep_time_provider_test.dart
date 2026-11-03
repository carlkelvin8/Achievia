import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(String? userId) => ProviderContainer(
    overrides: [sleepTimeUserProvider.overrideWithValue(userId)],
  );

  test('defaults to 20:00 while nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = containerFor('u1');
    addTearDown(container.dispose);
    container.read(sleepTimeProvider);
    await pumpEventQueue();

    expect(
      container.read(sleepTimeProvider),
      SleepTimeNotifier.defaultSleepTime,
    );
  });

  test(
    'persists per user and restores the same value on a fresh provider',
    () async {
      SharedPreferences.setMockInitialValues({});
      final writer = containerFor('u1');
      await pumpEventQueue();

      await writer
          .read(sleepTimeProvider.notifier)
          .save(TimeOfDay(hour: 23, minute: 5));
      await pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('sleep_time_u1_hour'), 23);
      expect(prefs.getInt('sleep_time_u1_minute'), 5);
      writer.dispose();

      final restored = containerFor('u1');
      addTearDown(restored.dispose);
      restored.read(sleepTimeProvider);
      await pumpEventQueue();
      expect(
        restored.read(sleepTimeProvider),
        const TimeOfDay(hour: 23, minute: 5),
      );
    },
  );

  test('keeps one account value isolated from another', () async {
    SharedPreferences.setMockInitialValues({});
    final writer = containerFor('u1');
    await pumpEventQueue();
    await writer
        .read(sleepTimeProvider.notifier)
        .save(TimeOfDay(hour: 22, minute: 30));
    await pumpEventQueue();
    writer.dispose();

    final other = containerFor('u2');
    addTearDown(other.dispose);
    other.read(sleepTimeProvider);
    await pumpEventQueue();
    expect(other.read(sleepTimeProvider), SleepTimeNotifier.defaultSleepTime);
  });

  test('out-of-range stored values fall back to the default', () async {
    SharedPreferences.setMockInitialValues({
      'sleep_time_u1_hour': 25,
      'sleep_time_u1_minute': -1,
    });
    final container = containerFor('u1');
    addTearDown(container.dispose);
    container.read(sleepTimeProvider);
    await pumpEventQueue();

    expect(
      container.read(sleepTimeProvider),
      SleepTimeNotifier.defaultSleepTime,
    );
  });

  test(
    'updates in memory but writes nothing when no user is resolved',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = containerFor(null);
      addTearDown(container.dispose);
      await pumpEventQueue();

      await container
          .read(sleepTimeProvider.notifier)
          .save(const TimeOfDay(hour: 21, minute: 0));
      await pumpEventQueue();

      expect(
        container.read(sleepTimeProvider),
        const TimeOfDay(hour: 21, minute: 0),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    },
  );
}
