// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub_label;
  const QuestionsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.sub_label,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){},
      child: Container(
      width: MediaQuery.of(context).size.width,
      padding: level1_widget,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(
            Radius.circular(10)
          )
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 70, color: Theme.of(context).colorScheme.secondary,),
                const SizedBox(height: 10,),
                Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                ),
                const SizedBox(height: 10,),
                Text(sub_label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor
                ),
                )
              ],
            ),
          
          ),
        ),
      ),
    ),
    );
  }
}
