import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:achievia/presentation/widgets/appbar/auth_app_bar.dart';
import 'package:achievia/presentation/widgets/builders/forgot_password_step.dart';
import 'package:achievia/presentation/widgets/forms/change_password_form.dart';
import 'package:achievia/presentation/widgets/forms/otp_form.dart';
import 'package:achievia/presentation/widgets/forms/password_reset_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreenHandler extends ConsumerStatefulWidget {
  const ForgotPasswordScreenHandler({super.key});

  @override
  ConsumerState<ForgotPasswordScreenHandler> createState() =>
      _ForgotPasswordScreenHandlerState();
}

class _ForgotPasswordScreenHandlerState extends ConsumerState<ForgotPasswordScreenHandler> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(resetPasswordNotifier.notifier);
    return Scaffold(
      appBar: AuthAppBar(onTap: context.pop, hasCenteredTitle: true),
      body: SafeArea(
        child: Padding(
          padding: level3,
          child: PageView(
            controller: notifier.pageController,
            onPageChanged: (value) => notifier.setPageIndex(value),
            children: [
              ForgotPasswordStep(
                headerText: 'Reset your password', 
                labelText: 'Please enter your email and we will send an OTP code in the next step to reset your password.', 
                child: PasswordResetForm(),),
              ForgotPasswordStep(
                headerText: 'OTP code verification',
                labelText:'We have an OTP code to your email in ${notifier.emailAddressController.text} Enter the OTP code below to verify',
                child: OtpFormForgot(),
              ),
              ForgotPasswordStep(
                headerText: 'Create new password',
                labelText: 'Enter a new password for your Achievia account.',
                child: ChangePasswordForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
