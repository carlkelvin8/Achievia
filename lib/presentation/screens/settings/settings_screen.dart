import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/settings/navigation_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/answer_feedback_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/theme_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/text_size_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/sleep_time_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/legal_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/logout_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/subscription_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/mfa_settings_section.dart';
import 'package:achievia/presentation/widgets/settings/app_lock_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Settings',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () {
                // Additional settings action
              },
            ),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),

            // Subscription and purchases
            SubscriptionSettingsSection(),

            // Two-factor authentication
            MfaSettingsSection(),

            // Biometric lock
            AppLockSettingsSection(),

            // Navigation Settings (Pomodoro & Examination)
            NavigationSettingsSection(),

            // Answer sounds and vibration (Study Deck, Take an Exam)
            AnswerFeedbackSettingsSection(),

            // Theme Settings
            ThemeSettingsSection(),

            // Text Size Settings
            TextSizeSettingsSection(),

            // Sleep Time Settings
            SleepTimeSettingsSection(),

            // Privacy Policy and Terms of Service
            LegalSettingsSection(),

            // Logout Settings
            LogoutSettingsSection(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
