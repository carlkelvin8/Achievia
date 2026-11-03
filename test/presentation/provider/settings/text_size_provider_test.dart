import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('the default is 0.5', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(textSizeProvider), 0.5);
    await settle();
    expect(container.read(textSizeProvider), 0.5);
  });

  test('the chosen size is stored and survives an app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    await first.read(textSizeProvider.notifier).setSize(0.9);
    expect(first.read(textSizeProvider), 0.9);
    first.dispose();

    // "Restart": a brand new container reads the stored value.
    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(textSizeProvider);
    await settle();
    expect(second.read(textSizeProvider), 0.9);
  });

  test('the minimum and maximum are stored too', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(textSizeProvider.notifier).setSize(0.0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(TextSizeNotifier.storageKey), 0.0);
    await container.read(textSizeProvider.notifier).setSize(1.0);
    expect(prefs.getDouble(TextSizeNotifier.storageKey), 1.0);
  });

  test('stored garbage is clamped, never crashes', () async {
    SharedPreferences.setMockInitialValues({TextSizeNotifier.storageKey: 7.0});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(textSizeProvider);
    await settle();
    expect(container.read(textSizeProvider), 1.0);
  });

  test('a slider move made before the stored value loads is kept', () async {
    SharedPreferences.setMockInitialValues({TextSizeNotifier.storageKey: 0.2});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(textSizeProvider.notifier);
    await notifier.setSize(0.8);
    await settle();
    expect(container.read(textSizeProvider), 0.8);
  });
}
