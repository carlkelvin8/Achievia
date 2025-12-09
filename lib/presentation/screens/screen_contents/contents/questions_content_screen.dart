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
            GridBadges(token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjIsInVzZXJuYW1lIjoiam9obmRvZSIsImVtYWlsIjoic3R1ZGVudEBleGFtcGxlLmNvbSIsInJvbGUiOiJzdHVkZW50IiwiaWF0IjoxNzY1MTk1MDcwLCJleHAiOjE3NjU3OTk4NzB9.QqXtMoICwszYrh996IYrwoWYaLEDGegVp76ht1hcMBY', id: '1', title: 'Day 1',)
            ],
          ),
        )
    );
}
}