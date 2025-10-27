import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/grids/grid_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskScreenContent extends ConsumerStatefulWidget {
  const TaskScreenContent({super.key});

  @override
  ConsumerState<TaskScreenContent> createState() => _TaskScreenContentState();
}

class _TaskScreenContentState extends ConsumerState<TaskScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: level1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: GridCards()),
          ],
        ),
        ),
    );
  }
}