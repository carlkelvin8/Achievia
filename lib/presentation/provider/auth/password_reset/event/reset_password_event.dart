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
  late final TextEditingController otpControllers;
  late final List<Color> otpBorderColors;
  late final UserUseCase useCase;
  @override
  ResetPasswordState build() {
    emailAddressController = TextEditingController();
    pageController = PageController();
    otpControllers = TextEditingController();
    otpBorderColors = List.generate(6, (_) => const Color(0xE3E3E3E7));
    useCase = ref.read(userUseCaseProvider);
    ref.onDispose(() {
      emailAddressController.dispose();
      pageController.dispose();
      otpControllers.dispose();
    });
    return ResetPasswordState(isLoading: false, index: 0);
  }

  void setPageIndex(int index) {
    state = state.copyWith(index: index);
  }

  void previousPage() {
    if (!pageController.hasClients) {
      return;
    }

    pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void nextPage() {
    if (!pageController.hasClients) {
      return;
    }

    pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void clearOtp() {
    otpControllers.clear();
  }

  Future<void> submitResetPassword(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true);
      await useCase.sendResetPasswordToEmail(
        emailAddressController.text.trim(),
      );
      if (pageController.hasClients) {
        nextPage();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        state = state.copyWith(isLoading: false);
      }
    }
  }
}
