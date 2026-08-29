import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final loginNotifier = ref.read(loginFormProvider.notifier);
    final loginState = ref.watch(loginFormProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          ReusableField(
            hintText: 'First Name',
            controller: loginNotifier.firstNameController,
            validator: (val) =>
                validate('First Name', val, loginNotifier.firstNameController),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Middle Name',
            controller: loginNotifier.middleNameController,
            validator: (val) => validate(
              'Middle Name',
              val,
              loginNotifier.middleNameController,
            ),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Surname',
            controller: loginNotifier.lastNameController,
            validator: (val) =>
                validate('Surname', val, loginNotifier.lastNameController),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Username',
            controller: loginNotifier.userNameControllerSignup,
            validator: (val) => validate(
              'Username',
              val,
              loginNotifier.userNameControllerSignup,
            ),
          ),
          const SizedBox(height: 10),

          ReusableField(
            hintText: 'Email',
            controller: loginNotifier.emailController,
            validator: (val) =>
                validate('Email', val, loginNotifier.emailController),
            errorText: loginState.errorMessage,
          ),
          const SizedBox(height: 10),

          ReusableField(
            validator: (val) => validate(
              'Password',
              val,
              loginNotifier.passwordControllerSignup,
            ),
            hintText: 'Password',
            controller: loginNotifier.passwordControllerSignup,
            isObscure: !_isPasswordVisible,
            suffixIcon: IconButton(
              key: const ValueKey('signup-password-visibility'),
              tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ReusableField(
            validator: (val) => validate(
              'Confirm Password',
              val,
              loginNotifier.confirmPasswordControllerSignup,
            ),
            suffixIcon: IconButton(
              key: const ValueKey('signup-confirm-password-visibility'),
              tooltip: _isConfirmPasswordVisible
                  ? 'Hide confirm password'
                  : 'Show confirm password',
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
            hintText: 'Confirm Password',
            controller: loginNotifier.confirmPasswordControllerSignup,
            isObscure: !_isConfirmPasswordVisible,
          ),
          const SizedBox(height: 50),
          ReusableButton(
            title: 'Create Account',
            isLoading: loginState.isLoading,
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              final result = await loginNotifier.submitSignup();
              if (!context.mounted) {
                return;
              }

              final signupState = ref.read(loginFormProvider);
              if (result == null) {
                AppToast.showError(
                  context,
                  signupState.errorMessage ?? 'Unable to create the account.',
                );
                return;
              }

              if (result.requiresEmailConfirmation) {
                AppToast.showInfo(
                  context,
                  'Check your email to confirm your account.',
                );
                context.go(RouteConstants.login);
                return;
              }

              AppToast.showSuccess(context, 'Account created successfully.');
              context.go(RouteConstants.main);
            },
            width: MediaQuery.of(context).size.width,
            height: 50,
            backgroundColor: const Color.fromARGB(255, 0, 219, 248),
            textColor: Colors.white,
          ),
          const SizedBox(height: 20),
          const AuthDivider(),
          const SizedBox(height: 16),
          GoogleSignInButton(
            onPressed: () {
              AppToast.showInfo(context, 'Google sign in is a design preview.');
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
