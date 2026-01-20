// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/presentation/widgets/cards/data_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_colors.dart';

class AttemptCard extends StatelessWidget {
  const AttemptCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                  Image.asset(logo, height: 40,),
                  Text('RESULTS',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: Text("Nice one, Achievian! You're getting better and better",
            style: GoogleFonts.poppins(
              color: LightColors.secondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12,),
          Container(
            padding: EdgeInsets.all(15.0),
            color: Colors.white,
            child: Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                DataCard(dataNum: '77.00', subject: 'Clinical Chemistry'),
                DataCard(dataNum: '77.00', subject: 'Clinical Chemistry'),
                DataCard(dataNum: '77.00', subject: 'Clinical Chemistry'),
                DataCard(dataNum: '77.00', subject: 'Clinical Chemistry'),
                DataCard(dataNum: '77.00', subject: 'Clinical Chemistry'),
              ],
            ),
          ),
          )
        ],
      ),
    );
  }
}
