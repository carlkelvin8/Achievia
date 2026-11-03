import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/forms/birthday_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('age is the whole years completed on the given day', () {
    final birth = DateTime(2000, 1, 15);
    expect(LoginNotifier.ageOn(birth, DateTime(2026, 1, 14)), 25);
    expect(LoginNotifier.ageOn(birth, DateTime(2026, 1, 15)), 26);
    expect(LoginNotifier.ageOn(birth, DateTime(2026, 12, 31)), 26);
    expect(LoginNotifier.ageOn(DateTime(2026, 6, 1), DateTime(2026, 5, 1)), 0);
  });

  test('the date is stored as yyyy-MM-dd and shown readably', () {
    expect(LoginNotifier.isoDate(DateTime(2000, 1, 5)), '2000-01-05');
    expect(BirthdayField.format(DateTime(2000, 1, 15)), 'January 15, 2000');
  });

  testWidgets('picking a date fills the field and reports it', (t) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    DateTime? picked;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: BirthdayField(
              controller: controller,
              today: DateTime(2026, 10, 14),
              onPicked: (d) => picked = d,
              validator: (v) => (v ?? '').isEmpty ? 'required' : null,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Birthday'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('birthday-field')));
    await t.pumpAndSettle();
    expect(find.text('Select your birthday'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await t.tap(find.text('15'));
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(picked, DateTime(2006, 10, 15));
    expect(controller.text, 'October 15, 2006');
  });

  testWidgets('cancel leaves the field empty', (t) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var calls = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BirthdayField(
            controller: controller,
            today: DateTime(2026, 10, 14),
            onPicked: (_) => calls++,
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('birthday-field')));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(calls, 0);
  });
}
