// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnansweredQuestionsBadge extends StatelessWidget {
  final String content;
  final bool answered;
  final int index;
  const UnansweredQuestionsBadge({
    super.key,
    required this.content,
    required this.answered,
    required this.index
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: answered ? Colors.black : Theme.of(context).primaryColor,
      padding: EdgeInsets.all(5.0),
      child: Text(content,
      style: GoogleFonts.poppins(
        fontSize: 9,
        color:answered   ? Colors.white : Colors.black ,
        fontWeight: FontWeight.w700
      ),
      ),
    );
  }
}
