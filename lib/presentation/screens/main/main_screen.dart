import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:flutter/material.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Start with Home tab selected
  int _notificationCount = 1; // Example notification count

  final List<Widget> _screens = [
    const ReviewersScreen(),
    const MessagesScreen(),
    const HomeScreen(),
    const ProfileScreen(),
    const AboutScreen(),
  ];

  void _onNotificationTap() {
    // Handle notification tap
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onSettingsTap() {
    // Handle settings tap
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppbar(onSettingsTap: _onSettingsTap, onNotificationTap: _onNotificationTap, notificationCount: _notificationCount, username: 'Charles Joven', profileImageUrl: '',),
      body: Column(
        children: [
          
          // Main content area
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
