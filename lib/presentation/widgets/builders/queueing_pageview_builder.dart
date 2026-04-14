import 'package:flutter/material.dart';

class QueueingPageViewBuilder extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final void Function(int)? onPageChanged;
  final Widget Function(BuildContext, int) itemBuilder;

  const QueueingPageViewBuilder({
    super.key,
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
