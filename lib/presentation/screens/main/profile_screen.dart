import 'package:achievia/presentation/widgets/tabs/profile/tab_bar_profile.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [Expanded(child: TabBarProfile())]),
    );
  }
}
