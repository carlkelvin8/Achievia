import 'dart:async';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:achievia/presentation/provider/auth/password_reset/state/reset_password_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final resetPasswordNotifier =
    NotifierProvider<ResetPasswordEvent, ResetPasswordState>(
      ResetPasswordEvent.new,
    );

final userUseCaseProvider = Provider<UserUseCase>((ref) => sl<UserUseCase>());

class ResetPasswordEvent extends Notifier<ResetPasswordState> {
  static const int otpCooldownSeconds = 60;

  late final TextEditingController emailAddressController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final PageController pageController;
  late final TextEditingController otpControllers;
  late final List<Color> otpBorderColors;
  late final UserUseCase useCase;
  Timer? _otpTimer;

  @override
  ResetPasswordState build() {
    emailAddressController = TextEditingController();
    pageController = PageController();
    otpControllers = TextEditingController();
    confirmPasswordController = TextEditingController();
    passwordController = TextEditingController();
    otpBorderColors = List.generate(6, (_) => const Color(0xE3E3E3E7));
    useCase = ref.read(userUseCaseProvider);
    ref.onDispose(() {
      _otpTimer?.cancel();
      emailAddressController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
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

  String get otpCountdownLabel {
    final minutes = state.otpSecondsRemaining ~/ 60;
    final seconds = state.otpSecondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    state = state.copyWith(otpSecondsRemaining: otpCooldownSeconds);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.otpSecondsRemaining;

      if (remaining <= 1) {
        timer.cancel();
        state = state.copyWith(otpSecondsRemaining: 0);
        return;
      }

      state = state.copyWith(otpSecondsRemaining: remaining - 1);
    });
  }

  String? validateOtpCode(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Enter the OTP code';
    }

    if (code.length != 8) {
      return 'Enter the 6-digit OTP code';
    }

    if (!RegExp(r'^\d{8}$').hasMatch(code)) {
      return 'OTP code must contain digits only';
    }

    return null;
  }

  Future<void> submitOtp(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true);
      await useCase.validateOtp(
        otpControllers.text.trim(),
        emailAddressController.text.trim(),
      );
      state = state.copyWith(isLoading: false);

      if (pageController.hasClients) {
        nextPage();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitResetPassword(BuildContext context) async {
    await _sendResetPasswordOtp(context, shouldAdvance: true);
  }

  Future<void> resendOtp(BuildContext context) async {
    if (!state.canResendOtp) {
      return;
    }

    await _sendResetPasswordOtp(context, shouldAdvance: false);
  }

  Future<void> _sendResetPasswordOtp(
    BuildContext context, {
    required bool shouldAdvance,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      await useCase.sendResetPasswordToEmail(
        emailAddressController.text.trim(),
      );
      _startOtpTimer();
      if (shouldAdvance && pageController.hasClients) {
        nextPage();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> changePassword(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true);
      await useCase.changePassword(
        passwordController.text,
      );
      passwordController.clear();
      confirmPasswordController.clear();
      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.go(RouteConstants.main);
      }
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
