// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnansweredQuestionsBadge extends StatelessWidget {
  final String content;
  final bool answered;
  final int index;
  final VoidCallback callback;
  const UnansweredQuestionsBadge({
    super.key,
    required this.content,
    required this.answered,
    required this.index,
    required this.callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
      decoration: BoxDecoration(
        color: answered ? Colors.black : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8)
      ),
      padding: EdgeInsets.symmetric(horizontal:8.0, vertical: 8.0),
      child: Center(
        child: FittedBox(
          child: Text(content,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color:answered   ? Colors.white : Colors.black ,
        fontWeight: FontWeight.w700
      ),
      ),
        )
      )
    ),
    );
  }
}
