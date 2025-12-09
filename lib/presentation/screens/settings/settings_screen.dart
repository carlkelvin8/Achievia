import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/theme_toggle_button.dart';
import 'package:achievia/presentation/widgets/inputs/text_size_slider.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/dialog_builder.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final sleepTime = ref.watch(sleepTimeProvider);

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Pomodoro Timer
            SettingsCard(
              onTap: () {
                NavigationService.goToPomodoroTimer();
              },
              child: SettingsItem(
                icon: Icons.timer_outlined,
                title: 'Pomodoro Timer',
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: headerColor2,
                  size: 16,
                ),
              ),
            ),

            // Examination
            SettingsCard(
              onTap: () {
                NavigationService.goToExamination();
              },
              child: SettingsItem(
                icon: Icons.assignment_outlined,
                title: 'Examination',
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: headerColor2,
                  size: 16,
                ),
              ),
            ),

            // Theme
            SettingsCard(
              child: SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                trailing: ThemeToggleButton(
                  isDarkMode: themeMode == ThemeMode.dark,
                  onToggle: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
              ),
            ),

            // Text Size
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsItem(icon: Icons.text_fields, title: 'Text Size'),
                  const SizedBox(height: 16),
                  TextSizeSlider(
                    value: textSize,
                    onChanged: (value) {
                      ref.read(textSizeProvider.notifier).state = value;
                    },
                    description: 'Text Size lets you adjust the font size for a more comfortable reading experience. Customize it to suit your preference and reduce eye strain while studying.',
                  ),
                ],
              ),
            ),

            // Sleep Time
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsItem(
                    icon: Icons.bedtime_outlined,
                    title: 'Sleep time',
                    trailing: _buildSleepTimeButton(ref, sleepTime),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sleep Time automatically sends notifications and reminds you to rest, promoting healthier study habits and balanced screen time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Log out
            SettingsCard(
              onTap: () async {
                final confirmed = await DialogBuilder.showConfirmation(
                  context: context,
                  title: 'Log Out',
                  content: 'Are you sure you want to log out?',
                  confirmText: 'Log Out',
                  confirmColor: Colors.red,
                );
                if (confirmed == true) {
                  final singleton = sl<LocalStorageService>();
                  await singleton.clearToken();
                  if (context.mounted) {
                    NavigationService.pop();
                    NavigationService.pop();
                  }
                }
              },
              child: SettingsItem(
                icon: Icons.logout,
                title: 'Log out',
                iconColor: Colors.red[600],
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red[600],
                  size: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTimeButton(WidgetRef ref, TimeOfDay sleepTime) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: ref.context,
          initialTime: sleepTime,
        );
        if (picked != null) {
          ref.read(sleepTimeProvider.notifier).state = picked;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(
            ref.context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              ref.context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          sleepTime.format(ref.context),
          style: TextStyle(
            color: Theme.of(ref.context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

