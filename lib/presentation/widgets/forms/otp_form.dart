import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/placeholder_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpFormForgot extends StatefulWidget {
  final GlobalKey<FormState> state;
  final List<TextEditingController> controller;
  final List<Color> borderColor;
  final PageController? controllerPage;
  final Widget? screen;
  const OtpFormForgot({
    super.key,
    required this.state,
    this.controllerPage,
    required this.controller,
    required this.borderColor,
    this.screen,
  });

  @override
  State<OtpFormForgot> createState() => _OtpFormForgotState();
}

class _OtpFormForgotState extends State<OtpFormForgot> {
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<FormState>();
    return Form(
      key: key,
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
                    controller: widget.controller[index],
                    onChanged: (value) {
                      if (value.length == 1) {
                        FocusScope.of(context).nextFocus();
                        setState(() {
                          widget.borderColor[index] = value.isNotEmpty
                              ? Theme.of(context).primaryColor
                              : const Color(0xE3E3E3E7);
                        });
                      } else if (value.isEmpty) {
                        FocusScope.of(context).previousFocus();
                        setState(() {
                          widget.borderColor[index] = const Color(0xE3E3E3E7);
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
                          color: widget.borderColor[index],
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: widget.borderColor[index],
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: widget.borderColor[index],
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:  BorderSide(
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
                // ignore: avoid_print
                print('Resend code');
              },
              text: 'Did not received the code?',
              gesture: ' Resend',
            ),
            const SizedBox(height: 30),
            ReusableButton(
              title: 'CONFIRM',
              onPressed: () async {
                if (widget.state.currentState!.validate()) {
                  final otpValue = widget.controller
                      .map((controller) => controller.text)
                      .join();
                  
                  widget.controllerPage?.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                  for (var index in widget.controller) {
                    index.clear();
                  }
                } else {
                  for (var index in widget.controller) {
                    index.clear();
                  }
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
