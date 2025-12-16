// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MockboardCard extends StatelessWidget {
  final String label;
  final List<String> labels;
  final bool isOne;
  final bool isBullet;
  final bool isNumber;
  const MockboardCard({
    super.key,
    required this.label,
    required this.labels,
    this.isOne = false,
    this.isBullet = false,
    this.isNumber = false
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isOne
                ? ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) =>
                        Text('• ${labels[index]}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          ),
                        ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemCount: labels.length,
                  )
                : Text(labels.first,
                style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          ),
                ),
          ),
        ),
      ],
    );
  }
}
