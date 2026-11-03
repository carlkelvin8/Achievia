import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable custom AppBar with consistent styling across the app
/// Supports back button, title, and optional actions
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Replaces the text [title] (used for the exam countdown).
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? leading;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final bool? centerTitle;
  final double? leadingWidth;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
    this.leading,
    this.backgroundColor,
    this.titleStyle,
    this.centerTitle,
    this.leadingWidth,
  });

  /// Pops when there is a page below; otherwise (a screen that is the only
  /// page, e.g. after a restore or a deep link) goes to the main screen so the
  /// arrow is never a dead button.
  static void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: 0,
      centerTitle: centerTitle,
      leadingWidth: leadingWidth,
      leading: showBackButton
          ? (leading ??
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: onBackPressed ?? () => _goBack(context),
                  ),
                ))
          : leading,
      title:
          titleWidget ??
          Text(
            title,
            style:
                titleStyle ??
                theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
