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

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  bool agreedToTerms = false;
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(toggleProvider);
    final visibilityNotifier = ref.read(toggleProvider.notifier);
    final loginNotifier = ref.read(loginFormProvider.notifier);
    return Form(
      key: _key,
      child: Column(
        children: [
          ReusableField(
            hintText: 'Email',
            controller: loginNotifier.emailControllerLogin,
            validator: (val) =>
                validate("Email", val, loginNotifier.emailControllerLogin),
          ),
          const SizedBox(height: 10),
          ReusableField(
            validator: (val) =>
                validate('Password', val, loginNotifier.passwordController),
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
            isLoading: ref.watch(loginFormProvider).isLoading,
            onPressed: () async {
              if (!_key.currentState!.validate()) {
                return;
              }

              final success = await loginNotifier.submit();
              if (!context.mounted) {
                return;
              }

              final loginState = ref.read(loginFormProvider);
              if (!success) {
                AppToast.showError(
                  context,
                  loginState.errorMessage ?? 'Unable to log in.',
                );
                return;
              }

              AppToast.showSuccess(context, 'Logged in successfully.');
              context.go(RouteConstants.main);
            },
            width: MediaQuery.of(context).size.width,
            height: 50,
            backgroundColor: const Color.fromARGB(255, 0, 219, 248),
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
              onTap: () {
                context.push(RouteConstants.forgotPassword);
              },
            ),
          ),
          const SizedBox(height: 12),
          const AuthDivider(),
          const SizedBox(height: 16),
          GoogleSignInButton(
            onPressed: () {
              AppToast.showInfo(
                context,
                'Google sign in is a design preview.',
              );
            },
          ),
          const SizedBox(height: 20),
          Placeholdergesture(
            onTap: () {
              context.push(RouteConstants.signUp);
            },
            text: "Dont't have an account?  ",
            gesture: 'Register',
          ),
        ],
      ),
    );
  }
}
