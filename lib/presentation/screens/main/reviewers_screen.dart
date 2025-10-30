import 'package:achievia/presentation/widgets/tabs/reviewers/tab_bar_reviewer.dart';
import 'package:flutter/material.dart';

class ReviewersScreen extends StatelessWidget {
  const ReviewersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TabBarReviewer(),
            )
          ],
        ),
      ),
    );
  }
}
