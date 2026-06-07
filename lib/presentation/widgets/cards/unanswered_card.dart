// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_colors.dart';

class UnansweredCard extends StatelessWidget {
  final int itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;
  final VoidCallback isShown;
  final int totalItems;
  final int currentItems;
  const UnansweredCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.isShown,
    required this.totalItems,
    required this.currentItems,
  });

  @override
  Widget build(BuildContext context) {
    final total = currentItems - totalItems;
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 17, 44, 131),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          const SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(logo, height: 40),
                  Text(
                    'Mock Boards',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: isShown,
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'You have $total questions left to answer, Achievian. Stay focused, you got this!',
              style: GoogleFonts.poppins(
                color: LightColors.secondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: GridView.builder(
              padding: EdgeInsets.all(8.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width == 360
                    ? 12
                    : 10,
                mainAxisSpacing: 2.0,
                crossAxisSpacing: 3.0,
                mainAxisExtent: 46.2,
              ),
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }
}
