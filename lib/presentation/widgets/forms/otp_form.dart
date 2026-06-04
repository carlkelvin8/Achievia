import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/placeholder_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpFormForgot extends ConsumerStatefulWidget {
  final GlobalKey<FormState> state;

  const OtpFormForgot({super.key, required this.state});

  @override
  ConsumerState<OtpFormForgot> createState() => _OtpFormForgotState();
}

class _OtpFormForgotState extends ConsumerState<OtpFormForgot> {
  @override
  Widget build(BuildContext context) {
    final event = ref.read(resetPasswordNotifier.notifier);

    return Form(
      key: widget.state,
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48.99,
                  height: 48.98659896850586,
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return '';
                      }
                      return null;
                    },
                    controller: event.otpControllers[index],
                    onChanged: (value) {
                      if (value.length == 1) {
                        FocusScope.of(context).nextFocus();
                        setState(() {
                          event.otpBorderColors[index] = value.isNotEmpty
                              ? Theme.of(context).primaryColor
                              : const Color(0xE3E3E3E7);
                        });
                      } else if (value.isEmpty) {
                        FocusScope.of(context).previousFocus();
                        setState(() {
                          event.otpBorderColors[index] = const Color(
                            0xE3E3E3E7,
                          );
                        });
                      }
                    },
                    style: Theme.of(context).textTheme.headlineMedium,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: event.otpBorderColors[index],
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: event.otpBorderColors[index],
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: event.otpBorderColors[index],
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                );
              }),
            ),
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
              title: 'CONFIRM',
              onPressed: () async {
                if (widget.state.currentState!.validate()) {
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
