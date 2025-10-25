import 'package:flutter/material.dart';
import 'package:achievia/core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 80, color: headerColor2),
            SizedBox(height: 16),
            Text(
              'You',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your profile and progress!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
