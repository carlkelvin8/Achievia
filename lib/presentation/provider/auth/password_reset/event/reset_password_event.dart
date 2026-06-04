import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:achievia/presentation/provider/auth/password_reset/state/reset_password_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final resetPasswordNotifier =
    NotifierProvider<ResetPasswordEvent, ResetPasswordState>(
      ResetPasswordEvent.new,
    );

final userUseCaseProvider = Provider<UserUseCase>((ref) => sl<UserUseCase>());

class ResetPasswordEvent extends Notifier<ResetPasswordState> {
  late final TextEditingController emailAddressController;
  late final PageController pageController;
  late final List<TextEditingController> otpControllers;
  late final List<Color> otpBorderColors;
  late final UserUseCase useCase;
  @override
  ResetPasswordState build() {
    emailAddressController = TextEditingController();
    pageController = PageController();
    otpControllers = List.generate(6, (_) => TextEditingController());
    otpBorderColors = List.generate(6, (_) => const Color(0xE3E3E3E7));
    useCase = ref.read(userUseCaseProvider);
    ref.onDispose(() {
      emailAddressController.dispose();
      pageController.dispose();
      for (final controller in otpControllers) {
        controller.dispose();
      }
    });
    return ResetPasswordState(isLoading: false, index: 0);
  }

  String get otpCode {
    return otpControllers.map((controller) => controller.text).join();
  }

  void clearOtp() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  Future<void> submitResetPassword(BuildContext context) async {
    try {
      await useCase.sendResetPasswordToEmail(emailAddressController.text.trim());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
