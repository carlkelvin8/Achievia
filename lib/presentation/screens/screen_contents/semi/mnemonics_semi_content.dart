import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/cards/notes_card.dart';
import 'package:achievia/presentation/widgets/cards/reusable_card.dart';
import 'package:achievia/presentation/widgets/grids/customize_grids.dart';
import 'package:achievia/presentation/widgets/inputs/custom_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MnemonicsSemiContent extends ConsumerStatefulWidget {
  const MnemonicsSemiContent({super.key});

  @override
  ConsumerState<MnemonicsSemiContent> createState() => _MnemonicsSemiContentState();
}

class _MnemonicsSemiContentState extends ConsumerState<MnemonicsSemiContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: level1,
      child: Column(
        children: [
          CustomSearchWidget(),
          Expanded(child: CustomizeGrids(crossAxisCount: 3, itemCount: mnemonics.length, itemBuilder: (context, index) => NotesCard(image: mnemonics[index].image, title: mnemonics[index].title), childaspectRatio: 1,))
        ],
      ),
      ),
    );
  }
}