import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/settings/pomodoro_customize_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('labels use "1 min" / "1 session" and plurals otherwise', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PomodoroCustomizeSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PomodoroCustomizeSection)),
    );
    final notifier = container.read(pomodoroSettingsProvider.notifier);

    notifier.setFocusMinutes(1);
    notifier.setShortBreakMinutes(1);
    notifier.setSessionsBeforeLong(1);
    await tester.pumpAndSettle();
    expect(find.text('1 min'), findsNWidgets(2));
    expect(find.text('1 mins'), findsNothing);
    expect(find.text('1 session'), findsOneWidget);
    expect(find.text('1 sessions'), findsNothing);

    notifier.setFocusMinutes(2);
    notifier.setShortBreakMinutes(3);
    notifier.setSessionsBeforeLong(4);
    await tester.pumpAndSettle();
    expect(find.text('2 mins'), findsOneWidget);
    expect(find.text('3 mins'), findsOneWidget);
    expect(find.text('4 sessions'), findsOneWidget);
    expect(find.text('1 min'), findsNothing);
  });
}
