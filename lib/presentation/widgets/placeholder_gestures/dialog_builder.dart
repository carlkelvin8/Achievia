import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DialogBuilder {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? cancelColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: icon != null ? Icon(icon, size: 48, color: confirmColor) : null,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: cancelColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor ?? theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
    String okText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: icon != null ? Icon(icon, size: 48, color: iconColor) : null,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => dialogContext.pop(), child: Text(okText)),
        ],
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return showInfo(
      context: context,
      title: title,
      content: content,
      okText: okText,
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return showInfo(
      context: context,
      title: title,
      content: content,
      okText: okText,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }
}
