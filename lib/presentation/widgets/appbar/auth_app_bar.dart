import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTap;
  final bool hasCenteredTitle;
  const AuthAppBar({super.key, required this.onTap, required this.hasCenteredTitle});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onTap,
        icon: Icon(Icons.arrow_back, color: primaryVariant),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        Container(
          padding: EdgeInsets.only(right: 12),
          child: Text('Need help?', style: TextStyle(color: primaryVariant)),
        ),
      ],
      centerTitle: true,
      title:hasCenteredTitle ? Text(
        'Achievia',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: primaryVariant,
        ),
      ) : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
