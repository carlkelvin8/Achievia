import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StudySessionDataSource {
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required String sessionType,
  });
}

@lazySingleton
@injectable
class StudySessionRemoteDatasource implements StudySessionDataSource {
  final SupabaseUserContext userContext;

  StudySessionRemoteDatasource({
    this.userContext = const SupabaseUserContext(),
  });

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required String sessionType,
  }) async {
    final duration = endedAt.difference(startedAt).inMinutes;
    if (duration < 1 || !endedAt.isAfter(startedAt)) return;

    await _supabase.from('study_sessions').insert({
      'user_id': await userContext.currentUserId(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_minutes': duration,
      'session_type': sessionType,
    });
  }
}
