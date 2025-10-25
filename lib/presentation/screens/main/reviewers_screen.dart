import 'package:flutter/material.dart';
import 'package:achievia/core/constants/app_colors.dart';

class ReviewersScreen extends StatelessWidget {
  const ReviewersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: headerColor2),
            SizedBox(height: 16),
            Text(
              'Reviewers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Board exam reviewers coming soon!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
