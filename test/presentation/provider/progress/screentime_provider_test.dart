import 'package:achievia/presentation/provider/progress/screentime_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('splits active usage at local midnight and keeps partial minutes', () {
    final seconds = addForegroundInterval(
      {},
      DateTime(2026, 9, 25, 23, 59, 30),
      DateTime(2026, 9, 26, 0, 1),
    );
    expect(seconds, {'2026-09-25': 30, '2026-09-26': 60});
    expect(screentimeFromSeconds(seconds).longestScreentime, 1);
  });

  test('counts foreground only and restores per-account usage', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 9, 26, 12);
    ProviderContainer containerFor(String user) => ProviderContainer(
      overrides: [
        screentimeUserProvider.overrideWithValue(user),
        screentimeClockProvider.overrideWithValue(() => now),
      ],
    );
    final container = containerFor('first');
    await container.read(screentimeProvider.future);
    final notifier = container.read(screentimeProvider.notifier);
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    now = now.add(const Duration(seconds: 65));
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(container.read(screentimeProvider).value!['2026-09-26'], 65);
    now = now.add(const Duration(hours: 2));
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    now = now.add(const Duration(seconds: 55));
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    final restored = containerFor('first');
    expect((await restored.read(screentimeProvider.future))['2026-09-26'], 120);
    restored.dispose();
    final other = containerFor('second');
    expect(await other.read(screentimeProvider.future), isEmpty);
    other.dispose();
  });

  test(
    'uploads a foreground stretch when leaving, not under a minute',
    () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 9, 26, 12);
      final uploads = <(DateTime, DateTime)>[];
      final container = ProviderContainer(
        overrides: [
          screentimeUserProvider.overrideWithValue('u'),
          screentimeClockProvider.overrideWithValue(() => now),
          studyTimeUploaderProvider.overrideWithValue((from, to) async {
            uploads.add((from, to));
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(screentimeProvider.future);
      final notifier = container.read(screentimeProvider.notifier);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Under a minute in the foreground: nothing is sent.
      now = now.add(const Duration(seconds: 40));
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(uploads, isEmpty);

      // Time in the background is never sent; a 3-minute visit is, on leaving.
      now = now.add(const Duration(hours: 1));
      final visit = now;
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      now = now.add(const Duration(minutes: 3));
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(uploads, [(visit, visit.add(const Duration(minutes: 3)))]);
    },
  );
}
