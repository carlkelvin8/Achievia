import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/appbar/auth_app_bar.dart';
import 'package:achievia/presentation/widgets/forms/password_reset_form.dart';
import 'package:achievia/presentation/widgets/headers/auth/auth_h1.dart';
import 'package:achievia/presentation/widgets/labels/auth/auth_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AuthAppBar(onTap: (){}, hasCenteredTitle: true,),
      body: SingleChildScrollView(
        child: Padding(
          padding: level3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthH1(
                fontSize: 20,
                text: 'Reset your password',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 20),
              AuthLabel(
                text:
                    'Please enter your email and we will send an OTP code in the next step to reset your password.',
              ),
              const SizedBox(height: 30),
              PasswordResetForm()
            ],
          ),
        ),
      ),
    );
  }
}