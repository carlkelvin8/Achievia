// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class OnboardingState {
  final PageController controller;
  final bool isLoading;
  final int currentIndex;
  OnboardingState({
    required this.controller,
    required this.isLoading,
    required this.currentIndex,
  });

  OnboardingState copyWith({
    PageController? controller,
    bool? isLoading,
    int? currentIndex,
  }) {
    return OnboardingState(
      controller: controller ?? this.controller,
      isLoading: isLoading ?? this.isLoading,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
