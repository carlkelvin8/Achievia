import 'package:achievia/presentation/screens/screen_contents/contents/profile_screen_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/task_screen_content.dart';
import 'package:achievia/presentation/screens/screen_contents/progress_screen_content.dart';
import 'package:flutter/material.dart';

class TabBarProfile extends StatefulWidget {
  const TabBarProfile({super.key});

  @override
  State<TabBarProfile> createState() => _TabBarProfileState();
}

class _TabBarProfileState extends State<TabBarProfile>
    with SingleTickerProviderStateMixin {
  final _tabs = const [
    Tab(text: 'Profile'),
    Tab(text: 'Progress'),
    Tab(text: 'Tasks'),
  ];

  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          tabs: _tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              const ProfileScreenContent(),
              const ProgressScreenContent(),
              TaskScreenContent(),
            ],
          ),
        ),
      ],
    );
  }
}
