import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The settings provider is autoDispose; without an active listener the
  // notifier is disposed between microtasks and every read would rebuild it
  // with fresh defaults. A dummy listener keeps it alive for the test.
  ProviderContainer keptAliveContainer() {
    final container = ProviderContainer();
    container.listen<void>(pomodoroSettingsProvider, (_, _) {});
    return container;
  }

  test('uses the built-in defaults while nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = keptAliveContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    final settings = container.read(pomodoroSettingsProvider);
    expect(settings.focusDuration, const Duration(minutes: 25));
    expect(settings.shortBreakDuration, const Duration(minutes: 5));
    expect(settings.longBreakDuration, const Duration(minutes: 30));
    expect(settings.sessionsBeforeLongBreak, 3);
  });

  test('persists each change and restores them on a fresh provider', () async {
    SharedPreferences.setMockInitialValues({});
    final first = keptAliveContainer();
    await pumpEventQueue();

    final notifier = first.read(pomodoroSettingsProvider.notifier);
    notifier.setFocusMinutes(45);
    notifier.setShortBreakMinutes(10);
    notifier.setLongBreakMinutes(60);
    notifier.setSessionsBeforeLong(4);
    await pumpEventQueue();

    expect(
      first.read(pomodoroSettingsProvider).focusDuration,
      const Duration(minutes: 45),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PomodoroSettingsNotifier.focusMinutesKey), 45);
    expect(prefs.getInt(PomodoroSettingsNotifier.shortBreakMinutesKey), 10);
    expect(prefs.getInt(PomodoroSettingsNotifier.longBreakMinutesKey), 60);
    expect(prefs.getInt(PomodoroSettingsNotifier.sessionsBeforeLongKey), 4);
    first.dispose();

    final second = keptAliveContainer();
    addTearDown(second.dispose);
    await pumpEventQueue();
    final settings = second.read(pomodoroSettingsProvider);
    expect(settings.focusDuration, const Duration(minutes: 45));
    expect(settings.shortBreakDuration, const Duration(minutes: 10));
    expect(settings.longBreakDuration, const Duration(minutes: 60));
    expect(settings.sessionsBeforeLongBreak, 4);
  });

  test('out-of-range stored values fall back to the defaults', () async {
    SharedPreferences.setMockInitialValues({
      PomodoroSettingsNotifier.focusMinutesKey: 0,
      PomodoroSettingsNotifier.shortBreakMinutesKey: -5,
      PomodoroSettingsNotifier.longBreakMinutesKey: 900,
      PomodoroSettingsNotifier.sessionsBeforeLongKey: 11,
    });
    final container = keptAliveContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    final settings = container.read(pomodoroSettingsProvider);
    expect(settings.focusDuration, const Duration(minutes: 25));
    expect(settings.shortBreakDuration, const Duration(minutes: 5));
    expect(settings.longBreakDuration, const Duration(minutes: 30));
    expect(settings.sessionsBeforeLongBreak, 3);
  });

  test('toggleDefault(true) stores the fixed default durations', () async {
    SharedPreferences.setMockInitialValues({});
    final container = keptAliveContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    container.read(pomodoroSettingsProvider.notifier).setFocusMinutes(50);
    container.read(pomodoroSettingsProvider.notifier).toggleDefault(true);
    await pumpEventQueue();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PomodoroSettingsNotifier.focusMinutesKey), 25);
    expect(prefs.getInt(PomodoroSettingsNotifier.shortBreakMinutesKey), 5);
    expect(prefs.getInt(PomodoroSettingsNotifier.longBreakMinutesKey), 30);
    expect(prefs.getInt(PomodoroSettingsNotifier.sessionsBeforeLongKey), 3);
  });

  test('Mock Boards exam limit stays fixed at 120 minutes', () async {
    SharedPreferences.setMockInitialValues({});
    final container = keptAliveContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    expect(
      container.read(timerProvider).remaining,
      const Duration(minutes: 120),
    );
    container.read(pomodoroSettingsProvider.notifier).setFocusMinutes(10);
    container.read(pomodoroSettingsProvider.notifier).setLongBreakMinutes(90);
    expect(
      container.read(timerProvider).remaining,
      const Duration(minutes: 120),
    );
  });
}
