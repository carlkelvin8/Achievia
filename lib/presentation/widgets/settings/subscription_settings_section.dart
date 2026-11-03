import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point to plans and purchases.
class SubscriptionSettingsSection extends StatelessWidget {
  const SubscriptionSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      onTap: () => context.push(RouteConstants.subscription),
      child: SettingsItem(
        icon: Icons.workspace_premium_outlined,
        title: 'Subscription & Mother Notes',
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
    );
  }
}
