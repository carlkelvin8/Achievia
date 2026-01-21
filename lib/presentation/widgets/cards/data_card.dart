import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataCard extends StatelessWidget {
  final String dataNum;
  final String subject;
  final Color? color;
  final Color? textColor;
  const DataCard({super.key, required this.dataNum, required this.subject,  this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(subject,
        ),
        Container(
          width: 100,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:color ?? Theme.of(context).cardColor
          ),
          child: Text(dataNum,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black,
          ),
          ),
        )
      ],
    );
  }
}