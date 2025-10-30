import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final sleepTime = ref.watch(sleepTimeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => NavigationService.pop(),
          ),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                trailing: _buildThemeToggle(ref, themeMode),
              ),
            ),

            // Text Size
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsItem(icon: Icons.text_fields, title: 'Text Size'),
                  const SizedBox(height: 16),
                  _buildTextSizeSlider(ref, textSize),
                  const SizedBox(height: 8),
                  Text(
                    'Text Size lets you adjust the font size for a more comfortable reading experience. Customize it to suit your preference and reduce eye strain while studying.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
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
              onTap: () {
                _showLogoutDialog(context);
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

  Widget _buildThemeToggle(WidgetRef ref, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
      child: Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(ref.context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: isDark ? 30 : 2,
              top: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 16,
                  color: Theme.of(ref.context).colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              left: isDark ? 8 : 36,
              top: 8,
              child: Text(
                isDark ? 'NIGHT' : 'DAY',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeSlider(WidgetRef ref, double textSize) {
    return Column(
      children: [
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Expanded(
              child: Slider(
                value: textSize,
                min: 0.0,
                max: 1.0,
                activeColor: headerColor2,
                inactiveColor: Colors.grey[300],
                onChanged: (value) {
                  ref.read(textSizeProvider.notifier).state = value;
                },
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout logic here
                NavigationService.goToLogin();
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
