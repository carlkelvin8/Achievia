import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';

// Tab navigation state
final tabIndexProvider = StateProvider<int>((ref) => 2); // Start with Home tab

// Tab screens list
final tabScreensProvider = Provider<List<Widget>>(
  (ref) => [
    const ReviewersScreen(),
    const MessagesScreen(),
    const HomeScreen(),
    const ProfileScreen(),
    const AboutScreen(),
  ],
);

// Current screen provider based on tab index
final currentScreenProvider = Provider<Widget>((ref) {
  final tabIndex = ref.watch(tabIndexProvider);
  final screens = ref.watch(tabScreensProvider);
  return screens[tabIndex];
});

// Tab navigation service
class TabNavigationService {
  static void changeTab(WidgetRef ref, int index) {
    ref.read(tabIndexProvider.notifier).state = index;
  }

  static void goToHome(WidgetRef ref) {
    changeTab(ref, 2);
  }

  static void goToProfile(WidgetRef ref) {
    changeTab(ref, 3);
  }

  static void goToMessages(WidgetRef ref) {
    changeTab(ref, 1);
  }

  static void goToReviewers(WidgetRef ref) {
    changeTab(ref, 0);
  }

  static void goToAbout(WidgetRef ref) {
    changeTab(ref, 4);
  }
}
