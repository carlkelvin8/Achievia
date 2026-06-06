import 'package:achievia/presentation/widgets/inputs/custom_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows matching suggestions and fills the selected value', (
    tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomSearchWidget(
            controller: controller,
            suggestions: const ['Hematology', 'Clinical Chemistry'],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hema');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Hematology'), findsOneWidget);
    expect(find.text('Clinical Chemistry'), findsNothing);

    await tester.tap(find.text('Hematology'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Hematology');
    expect(find.widgetWithText(ListTile, 'Hematology'), findsNothing);

    controller.dispose();
  });

  testWidgets('does not show add action unless a callback is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CustomSearchWidget())),
    );

    expect(find.byIcon(Icons.add), findsNothing);
  });
}
