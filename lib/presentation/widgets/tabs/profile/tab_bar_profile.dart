import 'package:achievia/presentation/provider/states/tab_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabBarProfile extends ConsumerStatefulWidget {
  const TabBarProfile({super.key});

  @override
  ConsumerState<TabBarProfile> createState() => _TabBarProfileState();
}

class _TabBarProfileState extends ConsumerState<TabBarProfile>
    with SingleTickerProviderStateMixin {
  final _tabs = const [
    Tab(text: 'Profile'),
    Tab(text: 'Progress'),
    Tab(text: 'Tasks'),
    Tab(text: 'Notes',)
  ];

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tabControllerProvider);

    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: _tabs,
          labelColor: const Color.fromARGB(255, 5, 43, 75),
          unselectedLabelColor: Colors.blueAccent,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
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
