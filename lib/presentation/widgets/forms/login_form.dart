import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: level1,
      color: const Color.fromARGB(255, 192, 210, 218),
      child: Form(
        child: Column(
          children: [
            ReusableField(
              hintText: 'Username',
              controller: TextEditingController(),
              validator: (value) {
                return null;
              },
            ),
            const SizedBox(height: 10,),
            ReusableField(
              hintText: 'Password',
              controller: TextEditingController(),
              validator: (value) {
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
