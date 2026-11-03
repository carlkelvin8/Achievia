import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Links to the Privacy Policy and Terms of Service
class LegalSettingsSection extends StatelessWidget {
  const LegalSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsCard(
          onTap: () => context.push(RouteConstants.privacyPolicy),
          child: const SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: headerColor2,
              size: 16,
            ),
          ),
        ),
        SettingsCard(
          onTap: () => context.push(RouteConstants.termsOfService),
          child: const SettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            trailing: Icon(
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
