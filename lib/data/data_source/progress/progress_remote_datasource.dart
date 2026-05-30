import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/progress/progress_day_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProgressDataSource {
  Future<void> markTodayActive();
  Future<List<ProgressDayDto>> getActiveDays();
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
}
