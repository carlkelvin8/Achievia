import 'package:flutter/material.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';

/// Navigation settings section containing Pomodoro Timer and Examination links
class NavigationSettingsSection extends StatelessWidget {
  const NavigationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}
