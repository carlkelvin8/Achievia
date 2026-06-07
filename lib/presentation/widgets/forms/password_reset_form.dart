import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/auth/password_reset/event/reset_password_event.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/inputs/reusable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordResetForm extends ConsumerStatefulWidget {
  const PasswordResetForm({super.key});

  @override
  ConsumerState<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends ConsumerState<PasswordResetForm> {
  final key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final event = ref.read(resetPasswordNotifier.notifier);
    final state = ref.watch(resetPasswordNotifier);
    return Form(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email Address'),
          const SizedBox(height: 10),
          ReusableField(
            validator: (value) =>
                validate('email', value, event.emailAddressController),
            hintText: 'e.g. candidate@achievia.ph',
            controller: event.emailAddressController,
            borderRadius: BorderRadius.circular(10),
            prefix: Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll send a 8-digit verification code to this address.",
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD9E2EC)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF2E5A88),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E5A88),
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Your account security is our priority. We use industry-standard encryption to protect your data.',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          ReusableButton(
            isLoading: state.isLoading,
            backgroundColor: primaryVariant,
            title: 'Continue >',
            onPressed: () async {
              if (key.currentState!.validate()) {
                await event.submitResetPassword(context);
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
