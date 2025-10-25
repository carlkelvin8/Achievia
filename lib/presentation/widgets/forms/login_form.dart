import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/injection.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/checkboxes/checkboxes.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _userName = TextEditingController();
  final _password = TextEditingController();
  bool agreedToTerms = false;

  @override
  void dispose() {
    _userName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AuthStateProvider>();
    return Container(
      padding: level1,
      color: const Color.fromARGB(255, 192, 210, 218),
      child: Form(
        child: Column(
          children: [
            ReusableField(
              hintText: 'Username',
              controller: _userName,
              validator: (value) {
                return null;
              },
            ),
            const SizedBox(height: 10),
            ReusableField(
              hintText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => provider.showText(),
                icon: provider.isShow
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off),
              ),
              isObscure: provider.isShow,
              controller: _password,
              validator: (value) {
                return null;
              },
            ),
            const SizedBox(height: 10),
            ReusableButton(
              title: 'Log in',
              onPressed: () {
                // Simple login logic - in real app, validate credentials
                if (_userName.text.isNotEmpty && _password.text.isNotEmpty) {
                  provider.login(_userName.text);
                  Navigator.pushReplacementNamed(context, '/main');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter username and password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              width: MediaQuery.of(context).size.width,
              height: 50,
              backgroundColor: const Color.fromARGB(255, 0, 219, 248),
              textColor: Colors.white,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Checkboxes(
                    onChanged: (value) {
                      setState(() {
                        agreedToTerms = value!;
                      });
                    },
                    isChecked: agreedToTerms,
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(child: Text('Forgot Password?')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
