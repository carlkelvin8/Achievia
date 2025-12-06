import 'package:achievia/presentation/screens/screen_contents/contents/author_content_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/achievia_content_screen.dart';
import 'package:flutter/material.dart';

class TabBarAbout extends StatefulWidget {
  const TabBarAbout({super.key});

  @override
  State<TabBarAbout> createState() => _TabBarAboutState();
}

class _TabBarAboutState extends State<TabBarAbout>
    with SingleTickerProviderStateMixin {
  final _tabs = const [Tab(text: 'Author'), Tab(text: 'Achievia')];

  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
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
            children: const [AuthorContentScreen(), AchieviaContentScreen()],
          ),
        ),
      ],
    );
  }
}
