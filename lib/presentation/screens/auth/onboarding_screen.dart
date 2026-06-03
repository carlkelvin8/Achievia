import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/headers/auth/auth_h1.dart';
import 'package:achievia/presentation/widgets/labels/auth/auth_label.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: level3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 40),
              const AuthH1(
                fontSize: 24,
                text: 'Achievia',
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 18),
              const AuthH1(
                fontSize: 20,
                text: 'Awaken academic ambition',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 20),
              const AuthLabel(
                text:
                    "The Philippines' premier e-learning platform for board exam preparation.",
              ),
              const SizedBox(height: 40),
              ReusableButton(
                title: 'Log In',
                onPressed: () => context.go(RouteConstants.login),
                width: width,
                height: 50,
              ),
              const SizedBox(height: 12),
              ReusableButton(
                title: 'Create Account',
                onPressed: () => context.go(RouteConstants.signUp),
                width: width,
                height: 50,
                backgroundColor: Theme.of(context).colorScheme.surface,
                textColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
