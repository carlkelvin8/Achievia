import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header2 extends StatelessWidget {
  final String title;

  const Header2({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 2,
      ),
    );
  }
}
