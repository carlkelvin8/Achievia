import 'package:achievia/core/constants/philippine_schools.dart';
import 'package:achievia/presentation/widgets/forms/school_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the list is the client list, A-Z, without duplicates', () {
    expect(philippineSchools.toSet().length, philippineSchools.length);
    expect(philippineSchools.first, 'Adventist Medical Center College');
    expect(philippineSchools.last, 'World Citi Colleges – Quezon City');
    final sorted = [...philippineSchools]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    expect(philippineSchools, sorted, reason: 'alphabetical, case-insensitive');
    expect(
      philippineSchools,
      contains(
        'University of the East Ramon Magsaysay Memorial Medical Center (UERM)',
      ),
    );
  });

  test('search ignores case, accents and dash style', () {
    expect(
      schoolMatches('Kolehiyo ng Lungsod ng Dasmariñas', 'dasmarinas'),
      isTrue,
    );
    expect(
      schoolMatches('Arellano University – Manila', 'university - manila'),
      isTrue,
    );
    expect(schoolMatches('Lorma Colleges', 'FATIMA'), isFalse);
    expect(schoolMatches('Lorma Colleges', ''), isTrue);
  });

  Future<TextEditingController> pump(WidgetTester t) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: SchoolPickerField(
              controller: controller,
              validator: (v) => (v ?? '').isEmpty ? 'required' : null,
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('choosing a school from the list fills the field', (t) async {
    final controller = await pump(t);
    await t.tap(find.byKey(const ValueKey('school-field')));
    await t.pumpAndSettle();
    expect(find.text('School not listed?'), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('school-search')), 'lorma');
    await t.pumpAndSettle();
    expect(find.text('Lorma Colleges'), findsOneWidget);
    expect(find.text('Silliman University'), findsNothing);

    await t.tap(find.text('Lorma Colleges'));
    await t.pumpAndSettle();
    expect(controller.text, 'Lorma Colleges');
    expect(find.text('School not listed?'), findsNothing);
  });

  testWidgets('a school that is not listed can be typed in', (t) async {
    final controller = await pump(t);
    await t.tap(find.byKey(const ValueKey('school-field')));
    await t.pumpAndSettle();

    final use = find.byKey(const ValueKey('school-use'));
    expect(t.widget<FilledButton>(use).onPressed, isNull);
    await t.enterText(
      find.byKey(const ValueKey('school-custom')),
      '  My New College ',
    );
    await t.pump();
    await t.ensureVisible(use);
    await t.tap(use);
    await t.pumpAndSettle();
    expect(controller.text, 'My New College');
  });

  testWidgets('closing the picker leaves the field unchanged', (t) async {
    final controller = await pump(t);
    controller.text = 'Silliman University';
    await t.tap(find.byKey(const ValueKey('school-field')));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Close'));
    await t.pumpAndSettle();
    expect(controller.text, 'Silliman University');
  });
}
