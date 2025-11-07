import 'package:achievia/core/constants/app_paddings.dart';
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
          CustomSearchWidget()
        ],
      ),
      ),
    );
  }
}