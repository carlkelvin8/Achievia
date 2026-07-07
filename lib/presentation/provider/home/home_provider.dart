import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/qotd_entity.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QotdNotifier extends Notifier<QotdEntity> {
  @override
  QotdEntity build() {
    // Seed with previous hard-coded demo data
    return const QotdEntity(
      id: 'qotd-2025-07-05',
      question:
          'What conditions are associated with a secretory defect in bilirubin metabolism?',
      options: [
        'Physiologic jaundice of the newborn',
        'Dubin-Johnson syndrome and Rotor syndrome',
        'Crigler-Najjar syndrome',
        'Gilbert syndrome',
      ],
    );
  }

  void selectOption(int index) {
    if (index < 0 || index >= state.options.length) return;
    state = state.copyWith(selectedIndex: index);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final qotdProvider = NotifierProvider<QotdNotifier, QotdEntity>(
  () => QotdNotifier(),
);

class GoalNotifier extends Notifier<GoalEntity> {
  @override
  GoalEntity build() {
    return GoalEntity(
      id: 'goal-2025-07-05',
      date: DateTime(2025, 7, 5),
      title: 'Hematology topic 1',
      details: 'Page 1 - page 12\nJuly 5, 2025',
      isChecked: false,
    );
  }

  void toggleChecked() {
    state = state.copyWith(isChecked: !state.isChecked);
  }
}

final goalProvider = NotifierProvider<GoalNotifier, GoalEntity>(
  () => GoalNotifier(),
);

final topMockboardAchieviansProvider =
    FutureProvider.autoDispose<List<UserEntity>>((ref) async {
      return _fetchAchievianLeaderboard('get_weekly_mockboard_achievians');
    });

final topStreakAchieviansProvider =
    FutureProvider.autoDispose<List<UserEntity>>((ref) async {
      return _fetchAchievianLeaderboard('get_monthly_streak_achievians');
    });

Future<List<UserEntity>> _fetchAchievianLeaderboard(String rpcName) async {
  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;
  if (session == null || session.isExpired) return [];

  final response = await supabase.rpc(rpcName, params: {'p_limit': 10});
  if (response is! List) return [];

  return response
      .whereType<Map>()
      .map((row) => _leaderboardUserFromJson(Map<String, dynamic>.from(row)))
      .toList();
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
