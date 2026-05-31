import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Placeholdergesture extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final String gesture;
  const Placeholdergesture({
    super.key,
    required this.onTap,
    required this.text,
    required this.gesture,
  });

  @override
  State<Placeholdergesture> createState() => _PlaceholdergestureState();
}

class _PlaceholdergestureState extends State<Placeholdergesture> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.gesture,
            style: GoogleFonts.poppins(
              decoration: TextDecoration.underline,
              decorationThickness: 4,
              decorationColor: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color.fromRGBO(8, 199, 247, 1),
            ),
          ),
        ),
      ],
    );
  }
}
