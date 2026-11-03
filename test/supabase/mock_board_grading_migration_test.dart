import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the security properties of the proposed server grading patch. The
/// behaviour itself is executed against PostgreSQL by
/// `scripts/test_mock_board_grading.py`; these checks keep the key statements
/// from being removed in review without anyone noticing.
void main() {
  final sql = File(
    'supabase/proposed/20261013000000_mock_board_server_grading.sql',
  ).readAsStringSync().replaceAll('\r\n', '\n').toLowerCase();

  test('Phase A: no client update/delete and no trust-column writes', () {
    expect(
      sql,
      contains('revoke insert, update, delete on public.quiz_attempts'),
    );
    for (final policy in ['update', 'delete']) {
      expect(
        sql,
        contains(
          'drop policy if exists "users can $policy their own quiz attempts"',
        ),
      );
    }
    // The legacy insert stays, but only on the columns the shipped app writes.
    expect(
      sql,
      contains(
        'grant insert (quiz_id, student_id, score, attempted_at, answer, '
        'no_of_attempt, summary)',
      ),
    );
    for (final trust in [
      'server_graded',
      'time_verified',
      'started_at',
      'client_attempt_id',
    ]) {
      expect(
        RegExp('grant insert \\([^)]*$trust').hasMatch(sql),
        isFalse,
        reason: '$trust must not be client writable',
      );
    }
    expect(
      sql,
      isNot(
        contains(
          'drop policy if exists "users can insert their own quiz attempts"',
        ),
      ),
    );
  });

  test('Phase B removes the legacy insert; rollback restores it', () {
    final phaseB = File(
      'supabase/proposed/20261013100000_mock_board_lockdown_legacy_insert.sql',
    ).readAsStringSync().replaceAll('\r\n', '\n').toLowerCase();
    expect(
      phaseB,
      contains(
        'drop policy if exists "users can insert their own quiz attempts"',
      ),
    );
    expect(phaseB, contains('revoke insert on public.quiz_attempts'));
    expect(phaseB, isNot(contains('delete from')));

    final rollback = File(
      'supabase/reconciliation/'
      'rollback_mock_board_server_grading_20261013.sql',
    ).readAsStringSync().replaceAll('\r\n', '\n').toLowerCase();
    expect(
      rollback,
      contains('drop function if exists public.save_mock_board_attempt'),
    );
    expect(
      rollback,
      contains('create policy "users can insert their own quiz attempts"'),
    );
    // No data loss: the rollback never drops columns or rows by default.
    final executable = rollback
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');
    expect(executable, isNot(contains('drop column')));
    expect(executable, isNot(contains('drop table')));
    expect(executable, isNot(contains('delete from')));
  });

  test('the grading function is owner-bound, locked and not public', () {
    expect(
      sql,
      contains('create or replace function public.save_mock_board_attempt('),
    );
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
    expect(sql, contains('v_uid uuid := auth.uid()'));
    expect(sql, contains('pg_advisory_xact_lock'));
    expect(
      sql,
      contains(
        'revoke all on function public.save_mock_board_attempt(uuid, jsonb)',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.save_mock_board_attempt(uuid, jsonb)',
      ),
    );
    expect(
      sql,
      isNot(contains('save_mock_board_attempt(uuid, jsonb)\n  to anon')),
    );
  });

  test('the score is derived on the server, never read from the client', () {
    expect(sql, contains('c_weights constant integer[]'));
    expect(sql, isNot(contains("p_items ->> 'score'")));
    expect(sql, isNot(contains("i ->> 'score'")));
    expect(sql, isNot(contains("i ->> 'is_correct'")));
    expect(sql, contains('values (\n    v_uid, v_gwa, now()'));
  });

  test('numbering and retries are protected by unique indexes', () {
    expect(sql, contains('quiz_attempts_student_client_attempt_uidx'));
    expect(sql, contains('quiz_attempts_student_attempt_uidx'));
  });

  test('both leaderboards only rank trusted (graded + time verified) rows', () {
    final occurrences = RegExp(
      'where qa.server_graded and qa.time_verified',
    ).allMatches(sql);
    expect(occurrences.length, 2);
    expect(sql, contains('server_graded boolean not null default false'));
    expect(sql, contains('time_verified boolean not null default false'));
  });

  test('history is preserved: no rows are deleted or rewritten', () {
    expect(sql, isNot(contains('delete from public.quiz_attempts')));
    expect(sql, isNot(contains('update public.quiz_attempts')));
    expect(sql, isNot(contains('truncate')));
  });

  test('start time and limit live in server-only tables', () {
    expect(
      sql,
      contains('create table if not exists public.mock_board_sessions'),
    );
    expect(
      sql,
      contains('create table if not exists public.mock_board_settings'),
    );
    expect(
      sql,
      contains(
        'revoke all on public.mock_board_sessions from anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on public.mock_board_settings from anon, authenticated',
      ),
    );
    // The limit is configuration, not a hard-coded decision.
    expect(sql, contains('per_subject_minutes integer'));
  });

  test('every question is checked against its section and eligibility', () {
    expect(sql, contains('mock_board_section_matches(r.section, s.title)'));
    expect(sql, contains('a question does not belong to its section'));
    expect(sql, contains('n_choices < 2 or n_correct <> 1'));
    expect(sql, contains('selected choice does not belong to its question'));
    // Composition and denominator are server-side constants / blueprint.
    expect(sql, contains('the mock board blueprint is not configured'));
    expect(
      sql,
      contains('submitted questions do not match the board blueprint'),
    );
    expect(sql, contains('c_per_section constant integer := 100'));
    expect(sql, contains('v_distinct <> c_total'));
    expect(sql, contains('round(s.correct * 100.0 / c_per_section, 2)'));
    // Soft deletes are respected whether or not the column exists yet.
    expect(sql, contains("to_jsonb(q) ->> 'deleted_at'"));
  });
}
