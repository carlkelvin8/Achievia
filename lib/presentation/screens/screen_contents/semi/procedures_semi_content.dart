import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:achievia/presentation/widgets/grids/customize_grids.dart';
import 'package:achievia/presentation/widgets/inputs/custom_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProceduresSemiContent extends ConsumerStatefulWidget {
  const ProceduresSemiContent({super.key});

  @override
  ConsumerState<ProceduresSemiContent> createState() => _ProceduresSemiContentState();
}

class _ProceduresSemiContentState extends ConsumerState<ProceduresSemiContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: level1,
      child: Column(
        children: [
          CustomSearchWidget(),
          Expanded(child: CustomizeGrids(crossAxisCount: 3, itemCount: procedures.length, itemBuilder: (context, index) => PdfBadge(text: procedures[index].text, tabType: 'mother notes',), childaspectRatio: 0.9,))
        ],
      ),
      ),
    );
  }
}