import 'package:achievia/core/di/injection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks authenticated launches per Supabase user and decides whether the
/// dashboard welcome message should be shown.
///
/// The instance lives for the whole app process (see
/// [welcomeSessionServiceProvider]), so its in-memory guards make the launch
/// counter increment at most once per account per app session, no matter how
/// many widgets or auth callbacks ask.
class WelcomeSessionService {
  WelcomeSessionService(this._prefs);

  final SharedPreferences _prefs;

  /// First launch that is allowed to show the welcome message.
  static const int firstWelcomeLaunch = 2;

  final Map<String, Future<int>> _sessionLaunchCounts = {};
  final Set<String> _welcomeConsumed = {};

  static String storageKey(String userId) => 'welcome_launch_count_$userId';

  /// Registers this app session for [userId] (once) and returns whether the
  /// welcome message should be displayed now (at most once per session).
  Future<bool> shouldShowWelcome(String userId) async {
    final count = await registerLaunch(userId);
    if (count < firstWelcomeLaunch) return false;
    return _welcomeConsumed.add(userId);
  }

  /// Increments and persists the launch count once per session for [userId].
  /// Concurrent callers share the same in-flight future. Returns the count,
  /// or 0 if local persistence failed.
  Future<int> registerLaunch(String userId) {
    return _sessionLaunchCounts.putIfAbsent(userId, () => _increment(userId));
  }

  Future<int> _increment(String userId) async {
    try {
      final key = storageKey(userId);
      final next = (_prefs.getInt(key) ?? 0) + 1;
      await _prefs.setInt(key, next);
      return next;
    } catch (error) {
      debugPrint('WelcomeSessionService: launch tracking failed: $error');
      return 0;
    }
  }

  /// Returns the trimmed [name], or null when it is missing or a placeholder.
  static String? usableName(String? name) {
    final trimmed = name?.trim() ?? '';
    const placeholders = {'null', 'undefined', 'user', 'unknown'};
    if (trimmed.isEmpty || placeholders.contains(trimmed.toLowerCase())) {
      return null;
    }
    return trimmed;
  }

  /// Builds the two-line welcome text, falling back gracefully when the first
  /// name is missing or a placeholder value.
  static String buildMessage(String? firstName) {
    final name = usableName(firstName);
    final greeting = name != null ? 'Welcome back, $name!' : 'Welcome back!';
    return '$greeting\nKeep going, future RMT!';
  }
}

final welcomeSessionServiceProvider = Provider<WelcomeSessionService>(
  (ref) => WelcomeSessionService(sl<SharedPreferences>()),
);
