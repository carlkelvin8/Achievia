import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point to two-factor authentication.
class MfaSettingsSection extends StatelessWidget {
  const MfaSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      onTap: () => context.push(RouteConstants.mfaSettings),
      child: SettingsItem(
        icon: Icons.security,
        title: 'Two-factor authentication',
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
    );
  }
}
