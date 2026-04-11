import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Home tab is index 2 — keeps the original Reviewers/Messages/Home/Profile/About order
const int _kHomeIndex = 2;

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// One navigator key per tab — replacing a key destroys & recreates the Navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// Ordered history of tab indices — back walks this in reverse.
  /// Seeded with Home so the final back press exits from Home.
  final List<int> _tabHistory = [_kHomeIndex];

  void _onNotificationTap(BuildContext context) {
    NavigationService.goToNotifications();
  }

  /// Replace the key for [index] with a fresh one so Flutter
  /// destroys the old Navigator and builds a completely new stack.
  void _resetTab(int index) {
    setState(() {
      _navigatorKeys[index] = GlobalKey<NavigatorState>();
    });
  }

  void _onTabTapped(int newIndex) {
    final currentIndex = ref.read(indexProvider);

    if (currentIndex == newIndex) {
      // Tapping the already-active tab: pop to root within that tab
      _navigatorKeys[newIndex]
          .currentState
          ?.popUntil((route) => route.isFirst);
      return;
    }

    // Tapping Home: reset ALL tab stacks and clear history entirely.
    // Back from Home will exit the app — no lingering stacks anywhere.
    if (newIndex == _kHomeIndex) {
      setState(() {
        for (int i = 0; i < _navigatorKeys.length; i++) {
          _navigatorKeys[i] = GlobalKey<NavigatorState>();
        }
      });
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

    // Fully reset the destination tab — destroys old stack, starts fresh
    _resetTab(newIndex);

    _tabHistory.add(newIndex);
    ref.read(indexProvider.notifier).changeIndex(newIndex);
  }

  Future<void> _handlePop() async {
    final currentIndex = ref.read(indexProvider);
    final currentNav = _navigatorKeys[currentIndex].currentState;

    // 1. Pop within the current tab's own screen stack first
    if (currentNav != null) {
      final didPop = await currentNav.maybePop();
      if (didPop) return;
    }

    // 2. At root of current tab — walk back through tab history
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousTab = _tabHistory.last;
      // Fully reset the tab we're going back to
      _resetTab(previousTab);
      ref.read(indexProvider.notifier).changeIndex(previousTab);
      return;
    }

    // 3. No history left (at Home root) → exit app
    SystemNavigator.pop();
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        // Root route → always show this tab's own screen
        if (settings.name == Navigator.defaultRouteName) {
          return MaterialPageRoute(builder: (_) => child);
        }
        // Any named push resolves through the appRoutes map
        final builder = appRoutes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder, settings: settings);
        }
        // Unrecognised route — show a clear error instead of looping
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
      },
    );
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
          onSettingsTap: () {},
          onNotificationTap: () => _onNotificationTap(context),
          notificationCount: notificationCount,
          username: 'Charles Joven',
          profileImageUrl: '',
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [
            _buildTabNavigator(0, const ReviewersScreen()),
            _buildTabNavigator(1, const MessagesScreen()),
            _buildTabNavigator(2, const HomeScreen()),
            _buildTabNavigator(3, const ProfileScreen()),
            _buildTabNavigator(4, const AboutScreen()),
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
