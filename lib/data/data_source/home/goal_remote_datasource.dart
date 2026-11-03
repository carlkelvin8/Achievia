import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/home/goal_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GoalDataSource {
  Future<GoalDto?> getTodayGoal();
  Future<void> saveTodayGoal(String title, String details);
  Future<void> clearGoal(String id);
  Future<void> setChecked(String id, bool checked);
}

@lazySingleton
@injectable
class GoalRemoteDatasource implements GoalDataSource {
  final SupabaseUserContext userContext;

  GoalRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  String _today() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).toIso8601String().split('T').first;
  }

  @override
  Future<GoalDto?> getTodayGoal() async {
    final userId = await userContext.currentUserId();
    final row = await _supabase
        .from('goals')
        .select('id, goal_date, title, details, is_checked')
        .eq('user_id', userId)
        .lte('goal_date', _today())
        .order('goal_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null
        ? null
        : GoalDto.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> saveTodayGoal(String title, String details) async {
    final userId = await userContext.currentUserId();
    final today = _today();
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await _supabase
        .from('goals')
        .select('id')
        .eq('user_id', userId)
        .eq('goal_date', today)
        .limit(1)
        .maybeSingle();
    if (existing == null) {
      await _supabase.from('goals').insert({
        'user_id': userId,
        'goal_date': today,
        'title': title,
        'details': details,
      });
      return;
    }
    await _supabase
        .from('goals')
        .update({
          'title': title,
          'details': details,
          'is_checked': false,
          'updated_at': now,
        })
        .eq('id', existing['id'])
        .eq('user_id', userId);
  }

  @override
  Future<void> clearGoal(String id) async {
    final userId = await userContext.currentUserId();
    await _supabase.from('goals').delete().eq('id', id).eq('user_id', userId);
  }

  @override
  Future<void> setChecked(String id, bool checked) async {
    final userId = await userContext.currentUserId();
    await _supabase
        .from('goals')
        .update({
          'is_checked': checked,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId);
  }
}
