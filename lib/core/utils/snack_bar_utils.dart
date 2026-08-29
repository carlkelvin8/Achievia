import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppToast {
  const AppToast._();

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, AppColors.warning, Icons.warning);

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
