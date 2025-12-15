
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/onboarding_mockboard_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/notifications/notifications_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reminder_screen_content.dart';
import 'package:achievia/presentation/screens/settings/examination/examination_screen.dart';
import 'package:achievia/presentation/screens/settings/pomodoro_timer/pomodoro_timer_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class RouteConstants {
  // Auth routes
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String main = '/main';

  // Main app tabs
  static const String reviewers = '/main/reviewers';
  static const String messages = '/main/messages';
  static const String home = '/main/home';
  static const String profile = '/main/profile';
  static const String about = '/main/about';

  // Additional routes (for future use)
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String examination = '/examination';
  static const String forgotPassword = '/forgot-password';
  static const String signUp = '/sign-up';
  static const String pomodoroTimer = '/pomodoro-timer';
  static const String reminder = '/reminder';
  static const String onboardingQuestions = '/onboarding-questions';
}



final Map<String, WidgetBuilder> appRoutes = {
  // Auth routes
  RouteConstants.onboarding: (_) => const OnboardingScreen(),
  RouteConstants.login: (_) => const LoginScreen(),

  // Main app entry
  RouteConstants.main: (_) => const MainScreen(),

  // Main tabs
  RouteConstants.reviewers: (_) => const ReviewersScreen(),
  RouteConstants.messages: (_) => const MessagesScreen(),
  RouteConstants.home: (_) => const HomeScreen(),
  RouteConstants.profile: (_) => const ProfileScreen(),
  RouteConstants.about: (_) => const AboutScreen(),

  // Settings & notifications
  RouteConstants.settings: (_) => const SettingsScreen(),
  RouteConstants.notifications: (_) => const NotificationsScreen(),
  RouteConstants.examination: (_) => const ExaminationScreen(),
  RouteConstants.pomodoroTimer: (_) => const PomodoroTimerScreen(),

  // Other features
  RouteConstants.reminder: (_) => const ReminderScreenContent(),
  RouteConstants.onboardingQuestions: (_) => const OnboardingMockboardScreen(title: '',),
};


