import 'dart:async';
import 'dart:convert';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/streak_rules.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/domain/use_cases/progress/progress_use_case.dart';
import 'package:achievia/domain/use_cases/progress/study_session_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final screentimeUserProvider = Provider<String?>((ref) {
  final token = ref.watch(tokenStream).value;
  return token == null ? null : Supabase.instance.client.auth.currentUser?.id;
});
final screentimeClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final screentimeProvider =
    AsyncNotifierProvider<ScreentimeNotifier, Map<String, int>>(
      ScreentimeNotifier.new,
    );

/// Sends one stretch of foreground use to the server (`study_sessions`,
/// type `app`), where it counts towards the Study Time leaderboard.
typedef StudyTimeUploader = Future<void> Function(DateTime from, DateTime to);

final studyTimeUploaderProvider = Provider<StudyTimeUploader>(
  (ref) =>
      (from, to) => sl<StudySessionUseCase>().recordSession(
        startedAt: from,
        endedAt: to,
        sessionType: studyTimeSessionType,
      ),
);

const studyTimeSessionType = 'app';

/// Foreground time is uploaded in stretches of about this length (and when
/// the app goes to the background), so the leaderboard stays current
/// without a row every few seconds.
const studyTimeUploadEvery = Duration(minutes: 5);

/// Whether today's foreground use has reached the streak's 60 minutes. A bool,
/// so the progress calendar only rebuilds when the day flips to blue (not every
/// time the seconds tick up).
final todayStreakMetProvider = Provider<bool>((ref) {
  final seconds = ref.watch(screentimeProvider).value ?? const {};
  final now = ref.watch(screentimeClockProvider)();
  return metDailyStreak(seconds[streakDayKey(now)] ?? 0);
});

/// Foreground app usage, persisted per account on this device, in seconds.
class ScreentimeNotifier extends AsyncNotifier<Map<String, int>>
    with WidgetsBindingObserver {
  DateTime? _startedAt;
  SharedPreferences? _prefs;
  String? _key;
  Map<String, int> _seconds = {};
  Future<void> _writes = Future.value();
  String? _recordedDay;

  /// Start of the foreground stretch not yet sent to the server.
  DateTime? _uploadFrom;

  @override
  Future<Map<String, int>> build() async {
    final userId = ref.watch(screentimeUserProvider);
    _startedAt = null;
    _uploadFrom = null;
    _recordedDay = null;
    _key = null;
    _seconds = {};
    if (userId == null) return {};
    var disposed = false;
    ref.onDispose(() => disposed = true);
    final prefs = await SharedPreferences.getInstance();
    if (disposed) return {};
    _prefs = prefs;
    _key = 'screentime_seconds_$userId';
    try {
      final raw = jsonDecode(prefs.getString(_key!) ?? '{}') as Map;
      _seconds = raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    } catch (_) {
      _seconds = {};
    }
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed) {
      _startedAt = ref.read(screentimeClockProvider)();
    }
    binding.addObserver(this);
    final timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkpoint(),
    );
    ref.onDispose(() {
      timer.cancel();
      binding.removeObserver(this);
    });
    return Map.of(_seconds);
  }

  void _checkpoint({bool leaving = false}) {
    final start = _startedAt;
    if (start == null || _key == null || !state.hasValue) return;
    final now = ref.read(screentimeClockProvider)();
    final seconds = now.difference(start).inSeconds;
    if (seconds <= 0) return;
    final end = start.add(Duration(seconds: seconds));
    _seconds = addForegroundInterval(_seconds, start, end);
    _startedAt = end;
    state = AsyncData(Map.of(_seconds));
    _recordStreakDay(end);
    _uploadStudyTime(start, end, leaving: leaving);
    final key = _key!;
    final payload = jsonEncode(_seconds);
    final prefs = _prefs!;
    _writes = _writes
        .then((_) async {
          await prefs.setString(key, payload);
        })
        .catchError((Object error) {
          debugPrint('Unable to persist screentime: $error');
        });
  }

  /// Sends the foreground time since [_uploadFrom] once it reaches
  /// [studyTimeUploadEvery], or when the app is [leaving] the foreground
  /// (stretches under a minute are not stored by the server). Best effort:
  /// a failed upload never affects the local count.
  void _uploadStudyTime(DateTime start, DateTime end, {required bool leaving}) {
    final from = _uploadFrom ??= start;
    final length = end.difference(from);
    if (length <
        (leaving ? const Duration(minutes: 1) : studyTimeUploadEvery)) {
      if (leaving) _uploadFrom = null;
      return;
    }
    _uploadFrom = leaving ? null : end;
    try {
      unawaited(
        ref.read(studyTimeUploaderProvider)(from, end).catchError((
          Object error,
        ) {
          debugPrint('Unable to upload study time: $error');
        }),
      );
    } catch (error) {
      debugPrint('Unable to upload study time: $error');
    }
  }

  /// Stores today as an active day once, as soon as the 60 minutes are done.
  /// A failed write is retried on the next checkpoint.
  void _recordStreakDay(DateTime now) {
    final day = streakDayKey(now);
    if (_recordedDay == day || !metDailyStreak(_seconds[day] ?? 0)) return;
    _recordedDay = day;
    unawaited(
      sl<ProgressUseCase>().markTodayActive().catchError((Object error) {
        _recordedDay = null;
        debugPrint('Unable to record streak day: $error');
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startedAt ??= ref.read(screentimeClockProvider)();
    } else {
      _checkpoint(leaving: true);
      _startedAt = null;
      _uploadFrom = null;
    }
  }
}

Map<String, int> addForegroundInterval(
  Map<String, int> existing,
  DateTime start,
  DateTime end,
) {
  final result = Map<String, int>.of(existing);
  var cursor = start;
  while (cursor.isBefore(end)) {
    final midnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
    final segmentEnd = end.isBefore(midnight) ? end : midnight;
    final key = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
    ).toIso8601String().split('T').first;
    result[key] = (result[key] ?? 0) + segmentEnd.difference(cursor).inSeconds;
    cursor = segmentEnd;
  }
  return result;
}

ScreentimeData screentimeFromSeconds(Map<String, int> seconds) {
  final days =
      seconds.entries
          .where(
            (entry) => entry.value > 0 && DateTime.tryParse(entry.key) != null,
          )
          .map(
            (entry) => DailyScreentime(
              date: DateTime.parse(entry.key),
              minutes: entry.value ~/ 60,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final values = days.map((day) => day.minutes).toList();
  return ScreentimeData(
    dailyAverage: values.isEmpty
        ? 0
        : (values.reduce((a, b) => a + b) / values.length).round(),
    longestScreentime: values.isEmpty
        ? 0
        : values.reduce((a, b) => a > b ? a : b),
    shortestScreentime: values.isEmpty
        ? 0
        : values.reduce((a, b) => a < b ? a : b),
    dailyBreakdown: days,
  );
}
