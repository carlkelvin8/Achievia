import 'package:flutter/material.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static NavigatorState? get navigator => navigatorKey.currentState;

  // Navigation methods
  static Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> pushReplacementNamed(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static void pop([dynamic result]) {
    navigator!.pop(result);
  }

  static void popUntil(String routeName) {
    navigator!.popUntil(ModalRoute.withName(routeName));
  }

  static bool canPop() {
    return navigator!.canPop();
  }

  // Convenience methods for common navigation patterns
  static Future<dynamic> goToLogin() {
    return pushReplacementNamed(RouteConstants.login);
  }

  static Future<dynamic> goToMain() {
    return pushReplacementNamed(RouteConstants.main);
  }

  static Future<dynamic> goToOnboarding() {
    return pushReplacementNamed(RouteConstants.onboarding);
  }

  static Future<dynamic> goToHome() {
    return pushReplacementNamed(RouteConstants.home);
  }

  static Future<dynamic> goToProfile() {
    return pushReplacementNamed(RouteConstants.profile);
  }

  static Future<dynamic> goToAbout() {
    return pushReplacementNamed(RouteConstants.about);
  }

  static Future<dynamic> goToMessages() {
    return pushReplacementNamed(RouteConstants.messages);
  }

  static Future<dynamic> goToReviewers() {
    return pushReplacementNamed(RouteConstants.reviewers);
  }

  static Future<dynamic> goToSettings() {
    return pushNamed(RouteConstants.settings);
  }
}
