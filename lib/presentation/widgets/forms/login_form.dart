import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/checkboxes/checkboxes.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginForm extends ConsumerWidget {
  LoginForm({super.key});

  // Controllers (still local — not state managed)
  final _userName = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPasswordVisible = ref.watch(toggleProvider);
    final notifier = ref.read(toggleProvider.notifier);

    bool agreedToTerms = false;

    return Container(
      padding: level1,
      color: const Color.fromARGB(255, 192, 210, 218),
      child: Form(
        child: Column(
          children: [
            ReusableField(
              hintText: 'Username',
              controller: _userName,
            ),
            const SizedBox(height: 10),
            ReusableField(
              hintText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => notifier.toggle(),
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              isObscure: !isPasswordVisible,
              controller: _password,
            ),
            const SizedBox(height: 10),
            ReusableButton(
              title: 'Log in',
              onPressed: () {
                if (_userName.text.isNotEmpty && _password.text.isNotEmpty) {
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
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Checkboxes(
                        onChanged: (value) {
                          setState(() {
                            agreedToTerms = value!;
                          });
                        },
                        isChecked: agreedToTerms,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 30),
                const Expanded(child: Text('Forgot Password?')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
