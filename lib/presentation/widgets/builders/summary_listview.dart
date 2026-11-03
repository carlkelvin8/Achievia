// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/presentation/widgets/builders/question_jump_list.dart';
import 'package:flutter/material.dart';

class SummaryListview extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  const SummaryListview({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Scrolls by itself and builds rows lazily: a Mock Board has hundreds of
    // questions, each with formatted text and possibly an image. The
    // draggable bar jumps straight to any of them.
    return QuestionJumpList(itemCount: itemCount, itemBuilder: itemBuilder);
  }
}
