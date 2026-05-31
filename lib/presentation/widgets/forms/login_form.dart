import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/placeholder_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
    final key = GlobalKey<FormState>();
    return Form(
      key: key,
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
          ),
          const SizedBox(height: 10),
          ReusableButton(
            title: 'Log in',
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
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.center,
            child: Text('Forgot Password?'),
          ),
          const SizedBox(height: 12),
          const _AuthDivider(),
          const SizedBox(height: 16),
          _GoogleSignInButton(
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

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const FaIcon(
          FontAwesomeIcons.google,
          color: Color(0xFF4285F4),
          size: 18,
        ),
        label: Text(
          'Continue with Google',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
