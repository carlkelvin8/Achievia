import 'package:achievia/const.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Home tab is index 2 — keeps the original Reviewers/Messages/Home/Profile/About order
const int _kHomeIndex = 2;

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// Ordered history of tab indices — back walks this in reverse.
  /// Seeded with Home so the final back press exits from Home.
  final List<int> _tabHistory = [_kHomeIndex];

  void _onNotificationTap(BuildContext context) {
    context.push(RouteConstants.notifications);
  }

  void _onTabTapped(int newIndex) {
    final currentIndex = ref.read(indexProvider);

    if (currentIndex == newIndex) {
      return;
    }

    if (newIndex == _kHomeIndex) {
      _tabHistory
        ..clear()
        ..add(_kHomeIndex);
      ref.read(indexProvider.notifier).changeIndex(_kHomeIndex);
      return;
    }

    // Remove any existing occurrence so history stays unique and ordered
    // e.g. history [home, you, about, review, message] + tap "you"
    //   → remove old "you" → [home, about, review, message] → add → [home, about, review, message, you]
    _tabHistory.remove(newIndex);
    _tabHistory.add(newIndex);
    ref.read(indexProvider.notifier).changeIndex(newIndex);
  }

  Future<void> _handlePop() async {
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousTab = _tabHistory.last;
      ref.read(indexProvider.notifier).changeIndex(previousTab);
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(indexProvider);
    const notificationCount = 1;

    return PopScope(
      // Never let the system pop this route automatically;
      // we handle everything in onPopInvokedWithResult
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop();
      },
      child: Scaffold(
        appBar: MainAppbar(
          onSettingsTap: () => context.push(RouteConstants.settings),
          onNotificationTap: () => _onNotificationTap(context),
          notificationCount: notificationCount,
          username: supabaseAuth.currentUser?.userMetadata?['first_name'],
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
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
