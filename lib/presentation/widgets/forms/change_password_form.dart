import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final event = ref.read(resetPasswordNotifier.notifier);
    final state = ref.watch(resetPasswordNotifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Password'),
          const SizedBox(height: 10),
          ReusableField(
            validator: (value) =>
                validate('Password', value, event.passwordController),
            hintText: 'Enter your new password',
            controller: event.passwordController,
            borderRadius: BorderRadius.circular(10),
            isObscure: true,
            prefix: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 20),
          const Text('Confirm Password'),
          const SizedBox(height: 10),
          ReusableField(
            validator: (value) =>
                validate('Confirm Password', value, event.passwordController),
            hintText: 'Re-enter your new password',
            controller: event.confirmPasswordController,
            borderRadius: BorderRadius.circular(10),
            isObscure: true,
            prefix: const Icon(Icons.lock_reset_outlined),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use at least 8 characters with uppercase, lowercase, number, and symbol.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 50),
          ReusableButton(
            isLoading: state.isLoading,
            backgroundColor: primaryVariant,
            title: 'UPDATE PASSWORD',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await event.changePassword(context);
              }
            },
            width: MediaQuery.of(context).size.width,
            height: 50,
          ),
        ],
      ),
    );
  }
}
