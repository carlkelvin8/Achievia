import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/dialog_builder.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Logout settings section with confirmation dialog
class LogoutSettingsSection extends ConsumerWidget {
  const LogoutSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsCard(
      onTap: () => _handleLogout(context),
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
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await DialogBuilder.showConfirmation(
      context: context,
      title: 'Log Out',
      content: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      final singleton = sl<LocalStorageService>();
      await Supabase.instance.client.auth.signOut();
      await singleton.clearToken();
      if (context.mounted) {
        NavigationService.pop();
      }
    }
  }
}
