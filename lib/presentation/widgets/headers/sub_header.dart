import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubHeader extends StatelessWidget {
  final String title;
  const SubHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
