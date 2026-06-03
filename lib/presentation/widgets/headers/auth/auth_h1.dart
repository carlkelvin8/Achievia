// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthH1 extends StatelessWidget {
  final double fontSize;
  final String text;
  final FontWeight fontWeight;
  const AuthH1({
    super.key,
    required this.fontSize,
    required this.text,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: primaryVariant,
        fontSize: fontSize,
        fontWeight: fontWeight
      ),
    );
  }
}
