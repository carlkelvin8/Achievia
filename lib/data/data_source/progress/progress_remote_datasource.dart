import 'package:achievia/core/utils/questions_helpers.dart'
    show utcTimestampText;
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
  final SupabaseClient? _client;

  ProgressRemoteDatasource({
    this.userContext = const SupabaseUserContext(),
    @ignoreParam SupabaseClient? client,
  }) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Reads every row of an ascending query. A single response is capped by the
  /// API, which would silently drop the NEWEST rows of a long history.
  Future<List<Map<String, dynamic>>> _allRows(
    PostgrestTransformBuilder<PostgrestList> Function() build,
  ) async {
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = await build().range(from, from + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    return rows;
  }

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
    final rows = await _allRows(
      () => _supabase
          .from('progress_days')
          .select('id, user_id, activity_date, is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('activity_date')
          .order('id'),
    );

    return rows
        .map((item) => ProgressDayDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<ProgressSnapshotDto> getSnapshot() async {
    final userId = await userContext.currentUserId();
    final activeDaysFuture = getActiveDays();
    final quizAttemptsFuture = _allRows(
      () => _supabase
          .from('quiz_attempts')
          .select('score, answer, summary, attempted_at, no_of_attempt')
          .eq('student_id', userId)
          .order('attempted_at')
          .order('no_of_attempt'),
    );
    // Optional data: a failure here must not hide the mock board history.
    final questionBankAttemptsFuture = _allRows(
      () => _supabase
          .from('question_bank_attempts')
          .select(
            'id, score, completed_at, subject_id, correct_answers, total_questions, attempt_type, subjects(title)',
          )
          .eq('user_id', userId)
          .order('completed_at')
          .order('id'),
    ).catchError((_) => const <Map<String, dynamic>>[]);
    final results = await Future.wait<dynamic>([
      activeDaysFuture,
      quizAttemptsFuture,
      questionBankAttemptsFuture,
    ]);

    return ProgressSnapshotDto(
      activeDays: results[0] as List<ProgressDayDto>,
      quizAttempts: [
        ...(results[1] as List).map(
          (row) => <String, dynamic>{
            ...Map<String, dynamic>.from(row),
            'attempted_at': utcTimestampText(row['attempted_at']),
          },
        ),
        ...(results[2] as List).map(
          (row) => <String, dynamic>{
            'score': row['score'],
            'attempted_at': row['completed_at'],
            'answer': [
              {
                'name': row['subjects']?['title'] ?? 'Question Bank',
                'score': row['score'],
              },
            ],
          },
        ),
      ],
      subjectExamAttempts: (results[2] as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      // Screentime is measured by the foreground tracker, not Pomodoro duration.
      studySessions: const [],
    );
  }
}
