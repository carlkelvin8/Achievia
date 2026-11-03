// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnansweredQuestionsBadge extends StatelessWidget {
  final String content;
  final bool answered;

  /// Marked to revisit: red, whether answered or not.
  final bool marked;
  final int index;
  final VoidCallback callback;
  const UnansweredQuestionsBadge({
    super.key,
    required this.content,
    required this.answered,
    this.marked = false,
    required this.index,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('navigator-question-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: callback,
      child: Container(
        decoration: BoxDecoration(
          color: marked
              ? Colors.red
              : answered
              ? Colors.black
              : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        child: Center(
          child: FittedBox(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: answered || marked ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
