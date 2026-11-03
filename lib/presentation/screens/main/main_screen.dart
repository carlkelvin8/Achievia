import 'dart:async';

import 'package:achievia/const.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/widgets/appbar/main_appbar.dart';
import 'package:achievia/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:achievia/presentation/provider/notifications/notifications_provider.dart';
import 'package:achievia/core/utils/welcome_session_service.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

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
  late final _welcomeToast = WelcomeToastController(
    slot: ref.read(toastSlotProvider),
  );
  StreamSubscription<AuthState>? _authSub;
  ProviderSubscription<AsyncValue<ProfileEntity>>? _profileSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  @override
  void dispose() {
    _cancelAuthSub();
    _cancelProfileSub();
    _welcomeToast.dispose();
    super.dispose();
  }

  /// Defensive upper bound for unresolved auth/profile states only; normal
  /// resolution is driven by Supabase auth and profileProvider state changes.
  static const _safeguard = Duration(seconds: 30);

  /// Resolves the signed-in user id from the restored Supabase session, or
  /// from the next auth event carrying one. Never blocks the dashboard.
  Future<String?> _resolveUserId() {
    final current = supabaseAuth.currentUser?.id;
    if (current != null) return Future.value(current);
    final completer = Completer<String?>();
    _authSub = supabaseAuth.onAuthStateChange.listen((event) {
      final id = event.session?.user.id;
      if (id != null && !completer.isCompleted) completer.complete(id);
    }, onError: (_) {});
    return completer.future
        .timeout(_safeguard, onTimeout: () => null)
        .whenComplete(_cancelAuthSub);
  }

  void _cancelAuthSub() {
    _authSub?.cancel();
    _authSub = null;
  }

  /// First usable name from the already-loaded profile state, then auth
  /// metadata. Waits on profileProvider state only if it is still loading.
  Future<String?> _resolveFirstName() async {
    final profile = ref.read(profileProvider);
    if (profile.isLoading) {
      final completer = Completer<void>();
      _profileSub = ref.listenManual(profileProvider, (_, next) {
        if (!next.isLoading && !completer.isCompleted) completer.complete();
      });
      await completer.future
          .timeout(_safeguard, onTimeout: () {})
          .whenComplete(_cancelProfileSub);
      if (!mounted) return null;
    }
    final loaded = ref.read(profileProvider).value?.firstName;
    return WelcomeSessionService.usableName(loaded) ??
        WelcomeSessionService.usableName(
          supabaseAuth.currentUser?.userMetadata?['first_name']?.toString(),
        );
  }

  void _cancelProfileSub() {
    _profileSub?.close();
    _profileSub = null;
  }

  bool get _isCurrentRoute => ModalRoute.isCurrentOf(context) ?? true;

  Future<void> _maybeShowWelcome() async {
    final userId = await _resolveUserId();
    if (!mounted || userId == null) return;
    final service = ref.read(welcomeSessionServiceProvider);
    if (!await service.shouldShowWelcome(userId) || !mounted) return;
    final firstName = await _resolveFirstName();
    if (!mounted || !_isCurrentRoute) return;
    _welcomeToast.show(context, WelcomeSessionService.buildMessage(firstName));
  }

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
    final notificationCount = ref.watch(unreadNotificationsCountProvider);
    // The profile is the source of truth: the signup metadata never changes
    // when the student edits their name or picture.
    final profile = ref.watch(profileProvider).value;
    final firstName = profile?.firstName?.trim();

    return WelcomeToastHost(
      controller: _welcomeToast,
      child: PopScope(
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
            username: (firstName != null && firstName.isNotEmpty)
                ? firstName
                : supabaseAuth.currentUser?.userMetadata?['first_name'] ?? '',
            profileImageUrl: profile?.profileImage ?? '',
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
      ),
    );
  }
}
