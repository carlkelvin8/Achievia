import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/placeholder_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

class OtpFormForgot extends ConsumerStatefulWidget {
  const OtpFormForgot({super.key});

  @override
  ConsumerState<OtpFormForgot> createState() => _OtpFormForgotState();
}

class _OtpFormForgotState extends ConsumerState<OtpFormForgot> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final event = ref.read(resetPasswordNotifier.notifier);
    final state = ref.watch(resetPasswordNotifier);
    final defaultOtpTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: Theme.of(context).textTheme.titleLarge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDBDEE4)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
    final focusedOtpTheme = defaultOtpTheme.copyDecorationWith(
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(10),
    );
    final errorOtpTheme = defaultOtpTheme.copyDecorationWith(
      border: Border.all(color: Colors.redAccent),
      borderRadius: BorderRadius.circular(10),
    );

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Column(
          children: [
            Pinput(
              length: 8,
              controller: event.otpControllers,
              defaultPinTheme: defaultOtpTheme,
              focusedPinTheme: focusedOtpTheme,
              submittedPinTheme: defaultOtpTheme,
              errorPinTheme: errorOtpTheme,
              validator: event.validateOtpCode,
              inputFormatters: [
                LengthLimitingTextInputFormatter(8),
                FilteringTextInputFormatter.digitsOnly,
              ],
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            ),
            const SizedBox(height: 278),
            if (state.canResendOtp)
              Placeholdergesture(
                onTap: () async {
                  await event.resendOtp(context);
                },
                text: 'Did not received the code?',
                gesture: ' Resend',
              )
            else
              Text(
                'Resend code in ${event.otpCountdownLabel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            const SizedBox(height: 30),
            ReusableButton(
              isLoading: state.isLoading,
              title: 'CONFIRM',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await event.submitOtp(context);
                  event.clearOtp();
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              textColor: const Color(0xFFFFFFFF),
              width: MediaQuery.of(context).size.width,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
