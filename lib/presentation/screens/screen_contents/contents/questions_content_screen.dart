import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/grids/grid_badges.dart';
import 'package:flutter/material.dart';

class QuestionsContentScreen extends StatelessWidget {
  const QuestionsContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: level1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [GridBadges()],
        ),
      ),
    );
  }
}
