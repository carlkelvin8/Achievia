import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:flutter/material.dart';

class MotherNotesContent extends StatefulWidget {
  const MotherNotesContent({super.key});

  @override
  State<MotherNotesContent> createState() => _MotherNotesContentState();
}

class _MotherNotesContentState extends State<MotherNotesContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:level1,
        child: Column(
        children: [
            Expanded(child: GridView.builder(shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ), 
            itemBuilder: (context, index) => PdfBadge(tabType: 'mother notes',text: list[index].text)
            )
          )
            ],
          ),
        )
    );
  }
}