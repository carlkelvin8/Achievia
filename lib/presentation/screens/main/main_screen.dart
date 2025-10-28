import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:achievia/core/constants/routers/tab_navigation_provider.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  void _onNotificationTap(BuildContext context) {
    // Navigate to notifications screen
    NavigationService.goToNotifications();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(indexProvider);
    final reader = ref.read(indexProvider.notifier);
    const notificationCount = 1; // Example notification count

    return Scaffold(
      appBar: MainAppbar(
        onSettingsTap: () {}, // Not used anymore, but keeping for compatibility
        onNotificationTap: () => _onNotificationTap(context),
        notificationCount: notificationCount,
        username: 'Charles Joven',
        profileImageUrl: '',
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          const ReviewersScreen(),
          const MessagesScreen(),
          const HomeScreen(),
          const ProfileScreen(),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => reader.changeIndex(index),
      ),
    );
  }
}
