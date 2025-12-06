// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomizeGrids extends ConsumerWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childaspectRatio;
  final Widget? Function(BuildContext, int) itemBuilder;
  const CustomizeGrids({super.key, 
    required this.crossAxisCount,
    required this.itemCount,
    required this.childaspectRatio,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childaspectRatio,
          ),
          itemBuilder: itemBuilder
        ),
      ],
    );
  }
}
