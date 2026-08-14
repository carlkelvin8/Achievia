import 'package:achievia/presentation/provider/progress/progress_provider.dart';
import 'package:achievia/presentation/screens/screen_contents/progress_screen_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('progress failure shows fallback instead of retrying forever', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressProvider.overrideWith(
            (ref) async => throw Exception('permanent database error'),
          ),
        ],
        child: const MaterialApp(home: ProgressScreenContent()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Unable to fetch latest progress. Showing fallback data.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
