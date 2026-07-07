import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String leaderboardMigration() {
    return File(
      'supabase/migrations/20260707002000_weekly_achievements_and_streak_rpc.sql',
    ).readAsStringSync();
  }

  test('weekly mockboard achievians rpc ranks by quiz attempt results', () {
    final migration = leaderboardMigration();

    expect(migration, contains('public.get_weekly_mockboard_achievians'));
    expect(migration, contains('from public.quiz_attempts qa'));
    expect(migration, contains('round(avg(qa.score)::numeric, 2)'));
    expect(
      migration,
      contains('order by r.average_score desc, r.best_score desc'),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.get_weekly_mockboard_achievians(integer) to authenticated',
      ),
    );
  });

  test('monthly streak achievians rpc ranks dynamic attempt-day streaks', () {
    final migration = leaderboardMigration();

    expect(migration, contains('public.get_monthly_streak_achievians'));
    expect(migration, contains('from public.quiz_attempts qa'));
    expect(
      migration,
      contains(
        "timezone('Asia/Manila', qa.attempted_at)::date as attempt_date",
      ),
    );
    expect(
      migration,
      contains(
        'row_number() over (partition by student_id order by attempt_date)',
      ),
    );
    expect(
      migration,
      contains('order by r.longest_streak desc, r.active_days desc'),
    );
    expect(migration, isNot(contains('progress_days')));
    expect(migration, isNot(contains('activity_date')));
    expect(
      migration,
      contains(
        'grant execute on function public.get_monthly_streak_achievians(integer) to authenticated',
      ),
    );
  });

  test('leaderboard has indexes for quiz attempt rpc filters', () {
    final migration = leaderboardMigration();

    expect(migration, contains('quiz_attempts_attempted_at_idx'));
    expect(migration, contains('quiz_attempts_weekly_leaderboard_idx'));
  });
}
