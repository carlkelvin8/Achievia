import 'package:achievia/presentation/widgets/tabs/profile/tab_bar_profile.dart';
import 'package:flutter/material.dart';

class TabBarHandlerProfile extends StatelessWidget {
  const TabBarHandlerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: TabBarProfile())]
      ),
    );
  }
}
