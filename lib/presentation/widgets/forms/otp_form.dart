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
  @override
  Widget build(BuildContext context) {
    final event = ref.read(resetPasswordNotifier.notifier);
    final state = ref.read(resetPasswordNotifier);
    final key = GlobalKey<FormState>();
    return Form(
      key: key,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Column(
          children: [
            Pinput(length: 8),
            const SizedBox(height: 278),
            Placeholdergesture(
              onTap: () {
                debugPrint('Resend code');
              },
              text: 'Did not received the code?',
              gesture: ' Resend',
            ),
            const SizedBox(height: 30),
            ReusableButton(
              isLoading: state.isLoading,
              title: 'CONFIRM',
              onPressed: () async {
                if (key.currentState!.validate()) {
                  debugPrint(event.otpCode);

                  event.pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                  event.clearOtp();
                } else {
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
