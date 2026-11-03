import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/use_cases/home/goal_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';

class GoalNotifier extends AsyncNotifier<GoalEntity?> {
  @override
  Future<GoalEntity?> build() async {
    ref.watch(localDayProvider);
    final token = await ref.watch(tokenStream.future);
    if (token == null) return null;
    return sl<GoalUseCase>().getTodayGoal();
  }

  /// Returns whether the write succeeded so the caller can tell the user.
  Future<bool> saveTodayGoal(String title, String details) async {
    try {
      await sl<GoalUseCase>().saveTodayGoal(title, details);
    } catch (error) {
      debugPrint('Goal save failed: $error');
      return false;
    }
    ref.invalidateSelf();
    return true;
  }

  Future<bool> clearGoal() async {
    final goal = state.value;
    if (goal == null) return true;
    try {
      await sl<GoalUseCase>().clearGoal(goal.id);
    } catch (error) {
      debugPrint('Goal clear failed: $error');
      return false;
    }
    ref.invalidateSelf();
    return true;
  }

  Future<void> toggleChecked() async {
    final goal = state.value;
    if (goal == null) return;
    try {
      await sl<GoalUseCase>().setChecked(goal.id, !goal.isChecked);
    } catch (error) {
      // A failed write keeps the current card state instead of surfacing an
      // unhandled error from a tap.
      debugPrint('Goal toggle failed: $error');
      return;
    }
    ref.invalidateSelf();
  }
}

final goalProvider = AsyncNotifierProvider<GoalNotifier, GoalEntity?>(
  () => GoalNotifier(),
);

/// One leaderboard entry: the student's ID card and, where the ranking has
/// a value worth showing (study time), that value next to the rank.
class LeaderboardEntry {
  final UserEntity profile;
  final String? detail;

  const LeaderboardEntry(this.profile, {this.detail});
}

final topMockboardAchieviansProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
      return _fetchAchievianLeaderboard('get_weekly_mockboard_achievians');
    });

/// Top 10 by total time spent in the app (hours and minutes), all time.
final topStudyTimeAchieviansProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
      return _fetchAchievianLeaderboard(
        'get_top_study_time_achievians',
        detail: (row) {
          final minutes = num.tryParse('${row['total_minutes']}')?.toInt();
          return minutes == null ? null : formatStudyTime(minutes);
        },
      );
    });

/// "12h 05m", "45m".
String formatStudyTime(int minutes) {
  final safe = minutes < 0 ? 0 : minutes;
  final hours = safe ~/ 60;
  final rest = (safe % 60).toString().padLeft(hours > 0 ? 2 : 1, '0');
  return hours > 0 ? '${hours}h ${rest}m' : '${rest}m';
}

Future<List<LeaderboardEntry>> _fetchAchievianLeaderboard(
  String rpcName, {
  String? Function(Map<String, dynamic> row)? detail,
}) async {
  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;
  if (session == null || session.isExpired) return [];

  final Object? response;
  try {
    response = await supabase.rpc(rpcName, params: {'p_limit': 10});
  } on PostgrestException catch (error) {
    // A ranking whose database function is not deployed yet shows as empty
    // instead of an error.
    if (error.code == 'PGRST202' || error.code == '42883') return [];
    rethrow;
  }
  if (response is! List) return [];

  return response.whereType<Map>().map((raw) {
    final row = Map<String, dynamic>.from(raw);
    return LeaderboardEntry(
      _leaderboardUserFromJson(row),
      detail: detail?.call(row),
    );
  }).toList();
}

UserEntity _leaderboardUserFromJson(Map<String, dynamic> json) {
  return UserEntity(
    firstName: json['first_name']?.toString(),
    middleName: json['middle_name']?.toString(),
    lastName: json['last_name']?.toString(),
    profileImage: json['profile_image']?.toString(),
    university: json['university']?.toString(),
    purpose: json['purpose']?.toString(),
    dateOfExamination: _parseDate(json['date_of_examination']),
  );
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
