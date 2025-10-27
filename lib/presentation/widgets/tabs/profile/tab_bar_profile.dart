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
    Tab(text: 'Notes'),
  ];

  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
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
          labelColor: const Color.fromARGB(255, 5, 43, 75),
          unselectedLabelColor: Colors.blueAccent,
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: const [
              Center(child: Text('Profile')),
              Center(child: Text('Progress')),
              Center(child: Text('Tasks')),
              Center(child: Text('Notes')),
            ],
          ),
        ),
      ],
    );
  }
}
