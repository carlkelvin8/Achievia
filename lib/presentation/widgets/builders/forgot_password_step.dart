// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:achievia/presentation/widgets/headers/auth/auth_h1.dart';
import 'package:achievia/presentation/widgets/labels/auth/auth_label.dart';

class ForgotPasswordStep extends StatelessWidget {
  final String headerText;
  final String labelText;
  final Widget child;
  const ForgotPasswordStep({
    super.key,
    required this.headerText,
    required this.labelText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthH1(fontSize: 20, text: headerText, fontWeight: FontWeight.w600),
          const SizedBox(height: 20),
          AuthLabel(text: labelText),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }
}
