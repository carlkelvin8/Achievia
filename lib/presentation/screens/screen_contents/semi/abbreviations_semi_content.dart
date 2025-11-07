import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/inputs/custom_search_field.dart';
import 'package:achievia/presentation/widgets/list_items/medical_abbreviation_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbbreviationsSemiContent extends ConsumerStatefulWidget {
  const AbbreviationsSemiContent({super.key});

  @override
  ConsumerState<AbbreviationsSemiContent> createState() => _AbbreviationsSemiContentState();
}

class _AbbreviationsSemiContentState extends ConsumerState<AbbreviationsSemiContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: level1,
      child: Column(
        children: [
          CustomSearchWidget(),
          Expanded(child: MedicalAbbreviationsList())
        ],
      ),
      ),
    );
  }
}