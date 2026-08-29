import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailConfirmedScreen extends StatelessWidget {
  const EmailConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: AppColors.primaryVariant,
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Email confirmed!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your email address has been verified successfully. Your Achievia account is ready.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.go(RouteConstants.main),
                    child: const Text('Continue to Achievia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
