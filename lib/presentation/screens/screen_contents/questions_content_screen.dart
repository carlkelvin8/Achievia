import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/grids/grid_badges.dart';
import 'package:flutter/material.dart';

class QuestionsContentScreen extends StatefulWidget {
  const QuestionsContentScreen({super.key});

  @override
  State<QuestionsContentScreen> createState() => _QuestionsContentScreenState();
}

class _QuestionsContentScreenState extends State<QuestionsContentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:level1,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            GridBadges(text: 'First Day Subjects', text2: 'Second Day Sybjects',)
            ],
          ),
        )
    );
}
}