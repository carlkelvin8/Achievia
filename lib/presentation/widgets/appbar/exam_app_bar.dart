// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:achievia/presentation/widgets/cards/timer_card.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double toolbarheight;
  final String title;
  const ExamAppBar({
    super.key,
    required this.toolbarheight,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
        toolbarHeight: toolbarheight,
        centerTitle: true,
        actions: [
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {},
            ),
              ],
            )
          ],
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TimerCard(),
            const SizedBox(height: 10,),
            Text(title,
            style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700
              ),
            ),
            const SizedBox(height: 2,),
            Text('Mockboards',
            style: GoogleFonts.poppins(
              fontSize: 12

            ),
            )
          ],
        ),
      );
  }
  
  @override
  Size get preferredSize =>  Size.fromHeight(toolbarheight);
}
