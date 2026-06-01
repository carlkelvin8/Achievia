import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/forms/signup_form.dart';
import 'package:achievia/presentation/widgets/headers/header1.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Header1(title1: 'Achie', title2: 'via'),
                ],
              ),
              const SizedBox(height: 30),
              SignupForm(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
