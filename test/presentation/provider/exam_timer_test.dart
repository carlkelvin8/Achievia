import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'mock exam uses its own fixed minutes and cancels timer on disposal',
    (tester) async {
      final container = ProviderContainer();
      final subscription = container.listen(timerProvider, (_, _) {});
      expect(
        container.read(timerProvider).remaining,
        const Duration(minutes: mockBoardSubjectMinutes),
      );
      container.read(timerProvider.notifier).start();
      await tester.pump(const Duration(seconds: 11));
      expect(
        container.read(timerProvider).remaining,
        const Duration(minutes: mockBoardSubjectMinutes - 1, seconds: 49),
      );
      container.read(timerProvider.notifier).reset();
      expect(
        container.read(timerProvider).remaining,
        const Duration(minutes: mockBoardSubjectMinutes),
      );
      container.read(timerProvider.notifier).start();
      subscription.close();
      container.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );
}
