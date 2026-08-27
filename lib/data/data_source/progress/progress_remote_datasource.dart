import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/progress/progress_day_dto.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProgressDataSource {
  Future<void> markTodayActive();
  Future<List<ProgressDayDto>> getActiveDays();
  Future<ProgressSnapshotDto> getSnapshot();
}

@lazySingleton
@injectable
class ProgressRemoteDatasource implements ProgressDataSource {
  final SupabaseUserContext userContext;

  ProgressRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  String _todayDate() {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, now.day);
    return normalized.toIso8601String().split('T').first;
  }

  @override
  Future<void> markTodayActive() async {
    final userId = await userContext.currentUserId();

    await _supabase.from('progress_days').upsert({
      'user_id': userId,
      'activity_date': _todayDate(),
      'is_active': true,
    }, onConflict: 'user_id,activity_date');
  }

  @override
  Future<List<ProgressDayDto>> getActiveDays() async {
    final userId = await userContext.currentUserId();
    final rows = await _supabase
        .from('progress_days')
        .select('id, user_id, activity_date, is_active')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('activity_date');

    return rows
        .map((item) => ProgressDayDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<ProgressSnapshotDto> getSnapshot() async {
    final userId = await userContext.currentUserId();
    final results = await Future.wait<dynamic>([
      getActiveDays(),
      _supabase
          .from('quiz_attempts')
          .select('score, answer, summary, attempted_at, no_of_attempt')
          .eq('student_id', userId)
          .order('attempted_at'),
      _supabase
          .from('study_sessions')
          .select('started_at, ended_at, duration_minutes, session_type')
          .eq('user_id', userId)
          .order('started_at'),
    ]);

    return ProgressSnapshotDto(
      activeDays: results[0] as List<ProgressDayDto>,
      quizAttempts: (results[1] as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      studySessions: (results[2] as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
    );
  }
}
