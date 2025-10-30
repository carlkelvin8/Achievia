import 'package:flutter/material.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';
import 'package:achievia/presentation/screens/notifications/notifications_screen.dart';
import 'package:achievia/presentation/screens/examination/examination_screen.dart';
import 'package:achievia/presentation/screens/settings/pomodoro_timer_screen.dart';
import 'route_constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case RouteConstants.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case RouteConstants.main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      // Individual tab routes (for deep linking)
      case RouteConstants.reviewers:
        return MaterialPageRoute(
          builder: (_) => const ReviewersScreen(),
          settings: settings,
        );

      case RouteConstants.messages:
        return MaterialPageRoute(
          builder: (_) => const MessagesScreen(),
          settings: settings,
        );

      case RouteConstants.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case RouteConstants.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case RouteConstants.about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
          settings: settings,
        );

      case RouteConstants.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case RouteConstants.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );

      case RouteConstants.examination:
        return MaterialPageRoute(
          builder: (_) => const ExaminationScreen(),
          settings: settings,
        );

      case RouteConstants.pomodoroTimer:
        return MaterialPageRoute(
          builder: (_) => const PomodoroTimerScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
    }
  }

  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('No route defined for ${settings.name}')),
      ),
    );
  }
}
