import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Navigation settings section containing the Pomodoro Timer link
class NavigationSettingsSection extends ConsumerWidget {
  const NavigationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider).value == true;
    return Column(
      children: [
        if (isAdmin)
          SettingsCard(
            onTap: () => context.push(RouteConstants.adminDailyMotivation),
            child: SettingsItem(
              icon: Icons.format_quote_outlined,
              title: 'Daily Motivation (Admin)',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: headerColor2,
                size: 16,
              ),
            ),
          ),
        // Pomodoro Timer
        SettingsCard(
          onTap: () {
            context.push(RouteConstants.pomodoroTimer);
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
      ],
    );
  }
}
