import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:flutter/material.dart';

class ExamPageviewBuilder extends StatelessWidget {
  final bool visible;
  final PageController controller;
  final int itemCount;
  final void Function(int)? onPageChanged;
  final Widget Function(BuildContext, int) itemBuilder;

  const ExamPageviewBuilder({
    super.key,
    required this.visible,
    required this.controller,
    required this.itemCount,
    this.onPageChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      itemCount: itemCount,
      onPageChanged: onPageChanged,
      itemBuilder: itemBuilder,
    );
  }
}
