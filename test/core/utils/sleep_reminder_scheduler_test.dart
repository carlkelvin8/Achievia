import 'dart:async';

import 'package:achievia/core/utils/sleep_reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTimer implements Timer {
  FakeTimer(this.delay, this.run);
  final Duration delay;
  final void Function() run;
  bool cancelled = false;
  bool fired = false;

  @override
  bool get isActive => !cancelled && !fired;
  @override
  int get tick => 0;
  @override
  void cancel() => cancelled = true;
}

class Harness {
  Harness(this.now, {Duration grace = const Duration(minutes: 10)}) {
    scheduler = SleepReminderScheduler(
      clock: () => now,
      onFire: (time) => fired.add(time),
      timerFactory: (delay, run) {
        final timer = FakeTimer(delay, run);
        timers.add(timer);
        return timer;
      },
      grace: grace,
    );
    addTearDown(scheduler.dispose);
  }

  DateTime now;
  late final SleepReminderScheduler scheduler;
  final fired = <TimeOfDay>[];
  final timers = <FakeTimer>[];

  FakeTimer get active => timers.lastWhere((t) => t.isActive);
  int get activeCount => timers.where((t) => t.isActive).length;

  /// Advances the clock to [to] and runs the pending timer, like real time.
  void advanceTo(DateTime to) {
    now = to;
    final timer = active..fired = true;
    timer.run();
  }
}

const eight = TimeOfDay(hour: 20, minute: 0);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SleepReminderSchedule', () {
    test('a future time schedules today, a past time tomorrow', () {
      expect(
        SleepReminderSchedule.nextOccurrence(
          DateTime(2026, 3, 10, 19, 30),
          eight,
        ),
        DateTime(2026, 3, 10, 20),
      );
      expect(
        SleepReminderSchedule.nextOccurrence(
          DateTime(2026, 3, 10, 20, 30),
          eight,
        ),
        DateTime(2026, 3, 11, 20),
      );
      // Exactly at the time counts as passed: the next one is tomorrow.
      expect(
        SleepReminderSchedule.nextOccurrence(DateTime(2026, 3, 10, 20), eight),
        DateTime(2026, 3, 11, 20),
      );
    });

    test('month and year rollover', () {
      expect(
        SleepReminderSchedule.nextOccurrence(DateTime(2026, 12, 31, 21), eight),
        DateTime(2027, 1, 1, 20),
      );
    });

    test('day key is canonical and invalid times are rejected', () {
      expect(
        SleepReminderSchedule.dayKey(DateTime(2026, 3, 5, 23)),
        '2026-03-05',
      );
      expect(
        SleepReminderSchedule.isValid(const TimeOfDay(hour: 23, minute: 59)),
        isTrue,
      );
      expect(
        SleepReminderSchedule.isValid(const TimeOfDay(hour: 24, minute: 0)),
        isFalse,
      );
      expect(
        SleepReminderSchedule.isValid(const TimeOfDay(hour: 1, minute: 60)),
        isFalse,
      );
      expect(
        SleepReminderSchedule.isValid(const TimeOfDay(hour: -1, minute: 0)),
        isFalse,
      );
    });

    test('message uses the first name or a generic greeting', () {
      expect(
        SleepReminderSchedule.message(firstName: 'Ana', time: '8:00 PM'),
        "Hello, Ana! It's already 8:00 PM. Time to take a rest!",
      );
      for (final v in [null, '', 'null', 'undefined', 'User', 'unknown']) {
        expect(
          SleepReminderSchedule.message(firstName: v, time: '8:00 PM'),
          "Hello! It's already 8:00 PM. Time to take a rest!",
        );
      }
    });
  });

  group('SleepReminderScheduler', () {
    test('schedules one timer at the absolute next occurrence', () async {
      final h = Harness(DateTime(2026, 3, 10, 19, 30));
      await h.scheduler.configure(userId: 'a', time: eight);
      expect(h.activeCount, 1);
      expect(h.active.delay, const Duration(minutes: 30));
    });

    test('a passed time schedules tomorrow', () async {
      final h = Harness(DateTime(2026, 3, 10, 20, 30));
      await h.scheduler.configure(userId: 'a', time: eight);
      expect(h.active.delay, const Duration(hours: 23, minutes: 30));
    });

    test('fires once at the configured minute, then recurs daily', () async {
      final h = Harness(DateTime(2026, 3, 10, 19, 30));
      await h.scheduler.configure(userId: 'a', time: eight);

      h.advanceTo(DateTime(2026, 3, 10, 20));
      expect(h.fired, [eight]);
      expect(h.activeCount, 1);
      expect(h.active.delay, const Duration(days: 1));

      h.advanceTo(DateTime(2026, 3, 11, 20));
      expect(h.fired, hasLength(2));
    });

    test(
      'a timer that runs a moment early re-arms instead of firing',
      () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 30));
        await h.scheduler.configure(userId: 'a', time: eight);
        h.advanceTo(DateTime(2026, 3, 10, 19, 59, 59, 900));
        expect(h.fired, isEmpty);
        expect(h.active.delay, const Duration(milliseconds: 100));
      },
    );

    test(
      'duplicate configuration does not duplicate timers or reminders',
      () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 30));
        await h.scheduler.configure(userId: 'a', time: eight);
        await h.scheduler.configure(userId: 'a', time: eight);
        await Future.wait([
          h.scheduler.configure(userId: 'a', time: eight),
          h.scheduler.configure(userId: 'a', time: eight),
        ]);
        expect(h.activeCount, 1);
        h.advanceTo(DateTime(2026, 3, 10, 20));
        expect(h.fired, hasLength(1));
      },
    );

    test('changing the time cancels the old schedule', () async {
      final h = Harness(DateTime(2026, 3, 10, 19, 30));
      await h.scheduler.configure(userId: 'a', time: eight);
      final old = h.active;
      await h.scheduler.configure(
        userId: 'a',
        time: const TimeOfDay(hour: 21, minute: 0),
      );
      expect(old.cancelled, isTrue);
      expect(h.activeCount, 1);
      expect(h.active.delay, const Duration(hours: 1, minutes: 30));
    });

    test(
      'editing the time after it passed does not fire immediately',
      () async {
        final h = Harness(DateTime(2026, 3, 10, 20, 2));
        await h.scheduler.configure(userId: 'a', time: eight);
        expect(h.fired, isEmpty);
        expect(h.active.delay, greaterThan(const Duration(hours: 23)));
      },
    );

    test('an old timer callback that races a change does nothing', () async {
      final h = Harness(DateTime(2026, 3, 10, 19, 30));
      await h.scheduler.configure(userId: 'a', time: eight);
      final old = h.timers.last;
      await h.scheduler.configure(
        userId: 'a',
        time: const TimeOfDay(hour: 22, minute: 0),
      );
      h.now = DateTime(2026, 3, 10, 20);
      old.run();
      expect(h.fired, isEmpty);
    });

    test('invalid or missing input cancels and never schedules', () async {
      final h = Harness(DateTime(2026, 3, 10, 19, 30));
      await h.scheduler.configure(
        userId: 'a',
        time: const TimeOfDay(hour: 30, minute: 0),
      );
      expect(h.timers, isEmpty);
      await h.scheduler.configure(userId: 'a', time: eight);
      await h.scheduler.configure(userId: null, time: null);
      expect(h.activeCount, 0);
      expect(h.scheduler.userId, isNull);
    });

    group('last fired', () {
      test(
        'a time set later the same day still fires after an earlier one',
        () async {
          final h = Harness(DateTime(2026, 3, 10, 5, 27, 30));
          await h.scheduler.configure(
            userId: 'a',
            time: const TimeOfDay(hour: 5, minute: 28),
          );
          h.advanceTo(DateTime(2026, 3, 10, 5, 28));
          await pumpEventQueue();
          expect(h.fired, hasLength(1));

          // The user edits the Sleep Time again a few minutes later.
          h.advanceTo(DateTime(2026, 3, 10, 5, 30));
          await h.scheduler.configure(
            userId: 'a',
            time: const TimeOfDay(hour: 5, minute: 32),
          );
          h.advanceTo(DateTime(2026, 3, 10, 5, 32));
          await pumpEventQueue();

          expect(h.fired, hasLength(2));
          expect(h.fired.last, const TimeOfDay(hour: 5, minute: 32));
        },
      );

      test('the same occurrence never fires twice', () async {
        final h = Harness(DateTime(2026, 3, 10, 5, 27, 30));
        const time = TimeOfDay(hour: 5, minute: 28);
        await h.scheduler.configure(userId: 'a', time: time);
        h.advanceTo(DateTime(2026, 3, 10, 5, 28));
        await pumpEventQueue();
        h.advanceTo(DateTime(2026, 3, 10, 5, 29));
        await h.scheduler.configure(userId: 'a', time: time, catchUp: true);
        h.scheduler.resume();
        await pumpEventQueue();
        expect(h.fired, hasLength(1));
      });

      test(
        'persists the fired occurrence per user and blocks a repeat',
        () async {
          final h = Harness(DateTime(2026, 3, 10, 19, 30));
          await h.scheduler.configure(userId: 'a', time: eight);
          h.advanceTo(DateTime(2026, 3, 10, 20));
          await pumpEventQueue();
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getString('sleep_reminder_last_fired_a'),
            '2026-03-10 20:00',
          );
          expect(prefs.getString('sleep_reminder_last_fired_b'), isNull);

          // Restart within the grace window the same day: not delivered again.
          final restarted = Harness(DateTime(2026, 3, 10, 20, 3));
          await restarted.scheduler.configure(
            userId: 'a',
            time: eight,
            catchUp: true,
          );
          expect(restarted.fired, isEmpty);
          expect(
            restarted.active.delay,
            greaterThan(const Duration(hours: 23)),
          );
        },
      );

      test('users keep independent last-fired state', () async {
        SharedPreferences.setMockInitialValues({
          'sleep_reminder_last_fired_a': '2026-03-10 20:00',
        });
        final now = DateTime(2026, 3, 10, 20, 3);
        final a = Harness(now);
        final b = Harness(now);
        await a.scheduler.configure(userId: 'a', time: eight, catchUp: true);
        await b.scheduler.configure(userId: 'b', time: eight, catchUp: true);
        expect(a.fired, isEmpty);
        expect(b.fired, [eight]);
      });
    });

    group('user scope', () {
      test(
        'switching account reloads that account and drops the old state',
        () async {
          SharedPreferences.setMockInitialValues({
            'sleep_reminder_last_fired_a': '2026-03-10 20:00',
          });
          final h = Harness(DateTime(2026, 3, 10, 20, 3));
          await h.scheduler.configure(userId: 'a', time: eight, catchUp: true);
          expect(h.fired, isEmpty);
          final aTimer = h.active;

          await h.scheduler.configure(userId: 'b', time: eight, catchUp: true);
          expect(aTimer.cancelled, isTrue);
          expect(h.fired, hasLength(1)); // b has not been reminded today
          expect(h.scheduler.userId, 'b');
        },
      );

      test('logout cancels the active schedule', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 30));
        await h.scheduler.configure(userId: 'a', time: eight);
        await h.scheduler.configure(userId: null, time: null);
        expect(h.activeCount, 0);
        expect(h.fired, isEmpty);
      });

      test(
        'a logout that lands mid-load does not arm the old account',
        () async {
          final gate = Completer<SharedPreferences>();
          final timers = <FakeTimer>[];
          final scheduler = SleepReminderScheduler(
            clock: () => DateTime(2026, 3, 10, 19, 30),
            onFire: (_) {},
            prefs: () => gate.future,
            timerFactory: (d, r) {
              final t = FakeTimer(d, r);
              timers.add(t);
              return t;
            },
          );
          addTearDown(scheduler.dispose);
          final slow = scheduler.configure(userId: 'a', time: eight);
          final next = scheduler.configure(userId: null, time: null);
          gate.complete(await SharedPreferences.getInstance());
          await Future.wait([slow, next]);
          expect(timers, isEmpty);
        },
      );
    });

    group('lifecycle', () {
      test('resume before the time keeps a single schedule', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 0));
        await h.scheduler.configure(userId: 'a', time: eight);
        h.now = DateTime(2026, 3, 10, 19, 20);
        h.scheduler.resume();
        expect(h.activeCount, 1);
        expect(h.active.delay, const Duration(minutes: 40));
        expect(h.fired, isEmpty);
      });

      test('resume shortly after the time delivers once', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 0));
        await h.scheduler.configure(userId: 'a', time: eight);
        h.now = DateTime(2026, 3, 10, 20, 3);
        h.scheduler.resume();
        h.scheduler.resume();
        expect(h.fired, hasLength(1));
        expect(h.activeCount, 1);
      });

      test('resume much later shows no stale reminder', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 0));
        await h.scheduler.configure(userId: 'a', time: eight);
        h.now = DateTime(2026, 3, 10, 23, 30);
        h.scheduler.resume();
        expect(h.fired, isEmpty);
        expect(h.active.delay, const Duration(hours: 20, minutes: 30));
      });

      test('a delayed timer after the grace window is skipped', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 0));
        await h.scheduler.configure(userId: 'a', time: eight);
        h.advanceTo(DateTime(2026, 3, 10, 21));
        expect(h.fired, isEmpty);
      });

      test('dispose cancels the timer and ignores late calls', () async {
        final h = Harness(DateTime(2026, 3, 10, 19, 0));
        await h.scheduler.configure(userId: 'a', time: eight);
        final timer = h.active;
        h.scheduler.dispose();
        expect(timer.cancelled, isTrue);
        h.now = DateTime(2026, 3, 10, 20);
        timer.run();
        h.scheduler.resume();
        expect(h.fired, isEmpty);
      });
    });

    test('a failing prefs read is contained and still schedules', () async {
      final timers = <FakeTimer>[];
      final scheduler = SleepReminderScheduler(
        clock: () => DateTime(2026, 3, 10, 19, 30),
        onFire: (_) {},
        prefs: () async => throw StateError('disk'),
        timerFactory: (d, r) {
          final t = FakeTimer(d, r);
          timers.add(t);
          return t;
        },
      );
      addTearDown(scheduler.dispose);
      await scheduler.configure(userId: 'a', time: eight);
      expect(timers, hasLength(1));
    });
  });
}
