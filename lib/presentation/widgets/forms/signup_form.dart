import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/google_sign_in_button.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/dividers/auth_divider.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/placeholder_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupForm extends ConsumerStatefulWidget {
  const SignupForm({super.key});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  bool agreedToTerms = false;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final loginNotifier = ref.read(loginFormProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          ReusableField(
            hintText: 'First Name',
            controller: loginNotifier.userNameControllerSignup,
            validator: (val) => loginNotifier.validate('First Name', val),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Middle Name',
            controller: loginNotifier.middleNameController,
            validator: (val) => loginNotifier.validate('Middle Name', val),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Surname',
            controller: loginNotifier.lastNameController,
            validator: (val) => loginNotifier.validate('Surname', val),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Username',
            controller: loginNotifier.userNameControllerSignup,
            validator: (val) => loginNotifier.validate('Username', val),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Email',
            controller: loginNotifier.emailController,
            validator: (val) => loginNotifier.validate('Email', val),
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),

          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Password',
            controller: loginNotifier.passwordControllerSignup,
            isObscure: true,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 10),

          ReusableField(
            validator: (val) => loginNotifier.validate('Password', val),
            hintText: 'Confirm Password',
            controller: loginNotifier.confirmPasswordControllerSignup,
            isObscure: true,
            errorText: ref.watch(loginFormProvider).errorMessage,
          ),
          const SizedBox(height: 50),
          ReusableButton(
            title: 'Create Account',
            isLoading: ref.watch(loginFormProvider).isLoading,
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await loginNotifier.submit();
              }
            },
            width: MediaQuery.of(context).size.width,
            height: 50,
            backgroundColor: const Color.fromARGB(255, 0, 219, 248),
            textColor: Colors.white,
          ),
          const SizedBox(height: 20,),
          const AuthDivider(),
          const SizedBox(height: 16),
          GoogleSignInButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google sign in is a design preview.'),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Placeholdergesture(
            onTap: () {
              context.push(RouteConstants.login);
            },
            text: "Already have an account?  ",
            gesture: 'Log in',
          ),
        ],
      ),
    );
  }
}
