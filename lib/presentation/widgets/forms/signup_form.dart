import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
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
    final key = GlobalKey<FormState>();
    return Form(
      key: key,
      child: Column(
        children: [
          ReusableField(
            hintText: 'First Name',
            controller: loginNotifier.userNameControllerSignup,
            validator: (val) => loginNotifier.validate("Username", val),
          ),
          const SizedBox(height: 10),
          ReusableField(
            validator: (val) => loginNotifier.validate('Middle Name', val),
            hintText: 'Middle Name',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),

          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Surname',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),
            ReusableField(
            
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Username',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),
          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Email',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
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
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),
          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Confirm Password',
            suffixIcon: IconButton(
              onPressed: () => visibilityNotifier.toggle(),
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            isObscure: !isPasswordVisible,
            controller: loginNotifier.passwordControllerSignup,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),
          ReusableButton(
            title: 'Sign up',
            isLoading: ref.watch(loginFormProvider).isLoading,
            onPressed: () async {
              if (key.currentState!.validate()) {
                await loginNotifier.submit();
              }
            },
            width: MediaQuery.of(context).size.width,
            height: 50,
            backgroundColor: const Color.fromARGB(255, 0, 219, 248),
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
