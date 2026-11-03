import 'package:achievia/presentation/provider/auth/onboarding/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingEvent extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.onDispose(() {
      state.controller.dispose();
    });
    return OnboardingState(
      controller: PageController(),
      isLoading: false,
      currentIndex: 0,
    );
  }

  Future<void> nextPage() async {
    final controller = state.controller;
    if (controller.hasClients) {
      await controller.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  void onPageChange(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

final onboardingNotifier = NotifierProvider<OnboardingEvent, OnboardingState>(
  OnboardingEvent.new,
);
