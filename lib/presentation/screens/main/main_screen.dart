import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:achievia/core/constants/routers/tab_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  void _onNotificationTap(BuildContext context) {
    // Handle notification tap
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);
    final currentScreen = ref.watch(currentScreenProvider);
    const notificationCount = 1; // Example notification count

    return Scaffold(
      appBar: MainAppbar(
        onSettingsTap: () {}, // Not used anymore, but keeping for compatibility
        onNotificationTap: () => _onNotificationTap(context),
        notificationCount: notificationCount,
        username: 'Charles Joven',
        profileImageUrl: '',
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(child: currentScreen),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => TabNavigationService.changeTab(ref, index),
      ),
    );
  }
}
