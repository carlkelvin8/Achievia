import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/checkboxes/checkboxes.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupForm extends ConsumerStatefulWidget {
  const SignupForm({super.key});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(toggleProvider);
    final visibilityNotifier = ref.read(toggleProvider.notifier);
    final loginNotifier = ref.read(loginFormProvider.notifier);

    return Form(
      key: loginNotifier.key,
      child: Column(
        children: [
          ReusableField(
            hintText: 'Username',
            controller: loginNotifier.usernameController,
            validator: (val) => loginNotifier.validate("Username", val),
          ),
          const SizedBox(height: 10),
          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Password',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordController,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),
          ReusableButton(
            title: 'Log in',
            isLoading: ref.watch(loginFormProvider).isLoading,
            onPressed: () async {
              if (loginNotifier.key.currentState!.validate()) {
                await loginNotifier.submit();
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
              const SizedBox(width: 80),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Forgot Password?'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
