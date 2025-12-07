import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/checkboxes/checkboxes.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(toggleProvider);
    final visibilityNotifier = ref.read(toggleProvider.notifier);
    final loginNotifier = ref.read(loginFormProvider.notifier);
  
    return Container(
      padding: level1,
      color: const Color.fromARGB(255, 192, 210, 218),
      child: Form(
        child: Column(
          children: [
            ReusableField(
              hintText: 'Username',
              controller: loginNotifier.usernameController,
            ),
            const SizedBox(height: 10),
            ReusableField(
              hintText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => visibilityNotifier.toggle(),
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              isObscure: !isPasswordVisible,
              controller: loginNotifier.passwordController,
            ),
            const SizedBox(height: 10),
            ReusableButton(
              title: 'Log in',
              onPressed: () async {
                final username = loginNotifier.usernameController.text;
                final password = loginNotifier.passwordController.text;
                if (username.isNotEmpty && password.isNotEmpty) {
                  await loginNotifier.submit();
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
