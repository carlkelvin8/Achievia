import 'package:flutter/material.dart';

/// A reusable horizontal scrollable list widget
/// Commonly used for displaying cards, items, or content in a horizontal layout
class HorizontalCardList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const HorizontalCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 190,
    this.spacing = 10,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: physics,
        itemBuilder: itemBuilder,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemCount: itemCount,
      ),
    );
  }
}
