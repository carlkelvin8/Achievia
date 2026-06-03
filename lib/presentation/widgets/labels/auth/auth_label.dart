import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLabel extends StatelessWidget {
  final String text;

  const AuthLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B7280),
        height: 1.5,
      ),
    );
  }
}
