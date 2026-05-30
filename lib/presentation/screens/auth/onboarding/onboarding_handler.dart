import 'package:achievia/presentation/provider/auth/onboarding/onboarding_event.dart';
import 'package:achievia/presentation/screens/auth/onboarding/onboarding_step_1.dart';
import 'package:achievia/presentation/screens/auth/onboarding/onboarding_step_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingHandler extends ConsumerStatefulWidget {
  const OnboardingHandler({super.key});

  @override
  ConsumerState<OnboardingHandler> createState() => _OnboardingHandlerState();
}

class _OnboardingHandlerState extends ConsumerState<OnboardingHandler> {
  @override
  Widget build(BuildContext context) {
    final event = ref.read(onboardingNotifier.notifier);
    final state = ref.watch(onboardingNotifier);
    return Scaffold(
      body: PageView(
        controller: state.controller,
        onPageChanged: (val)=> event.onPageChange(val),
        children: [
          OnboardingStep1(),
          OnboardingStep2()
        ],
      ),
    );
  }
}