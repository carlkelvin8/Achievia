import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('owns reset password form controllers', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final event = container.read(resetPasswordNotifier.notifier);

    expect(event.emailAddressController, isA<TextEditingController>());
    expect(event.pageController, isA<PageController>());
    expect(event.otpControllers, isA<TextEditingController>());
    expect(event.otpBorderColors, hasLength(6));
    expect(event.otpBorderColors, everyElement(const Color(0xE3E3E3E7)));
  });
}
