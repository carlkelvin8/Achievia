import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/appbar/auth_app_bar.dart';
import 'package:achievia/presentation/widgets/forms/signup_form.dart';
import 'package:achievia/presentation/widgets/headers/auth/auth_h1.dart';
import 'package:achievia/presentation/widgets/labels/auth/auth_label.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AuthAppBar(
        onTap: () => context.go(RouteConstants.login),
        hasCenteredTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: level3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              AuthH1(
                fontSize: 20,
                text: 'Create your account',
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 20),
              AuthLabel(
                text:
                    'Set up your Achievia profile so your study progress, reminders, and reviewer activity stay connected.',
              ),
              SizedBox(height: 30),
              SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}
