import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header1 extends StatelessWidget {
  final String title1;
  final String title2;
  const Header1({super.key, required this.title1, required this.title2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title1,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 4,
            fontSize: 50,
          ),
        ),
        Text(
          title2,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 4,
            fontSize: 50,
          ),
        ),
      ],
    );
  }
}
