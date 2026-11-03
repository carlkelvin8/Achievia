import 'package:achievia/core/utils/helpers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('confirm password', () {
    test('matches the exact typed password', () {
      final controller = TextEditingController(text: 'Abcdef1!');
      addTearDown(controller.dispose);

      expect(validate('Confirm Password', 'Abcdef1!', controller), isNull);
    });

    test('matches a password with surrounding spaces typed the same way', () {
      final controller = TextEditingController(text: ' Abcdef1! ');
      addTearDown(controller.dispose);

      expect(validate('Confirm Password', ' Abcdef1! ', controller), isNull);
    });

    test('rejects a different password', () {
      final controller = TextEditingController(text: 'Abcdef1!');
      addTearDown(controller.dispose);

      expect(
        validate('Confirm Password', 'Abcdef1?', controller),
        'Passwords do not match',
      );
    });

    test('rejects a password that only differs by edge spaces', () {
      final controller = TextEditingController(text: 'Abcdef1!');
      addTearDown(controller.dispose);

      expect(
        validate('Confirm Password', 'Abcdef1! ', controller),
        'Passwords do not match',
      );
    });
  });
}
