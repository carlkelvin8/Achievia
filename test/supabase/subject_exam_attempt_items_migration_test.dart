import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for the (not yet applied) exam summary migration. They read
/// the SQL text only; nothing here touches a database.
void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      'supabase/migrations/20261005000000_subject_exam_attempt_items.sql',
    ).readAsStringSync().toLowerCase();
  });

  test('runs in one transaction', () {
    expect(sql.trimLeft(), startsWith('begin;'));
    expect(sql.trimRight(), endsWith('commit;'));
  });

  test('historical items survive question deletion and keep a snapshot', () {
    expect(sql, contains('question_text text not null'));
    expect(sql, contains('choices_snapshot jsonb not null'));
    expect(sql, contains('references public.questions(id) on delete set null'));
    // Only the parent attempt may cascade away its items.
    expect(
      sql,
      contains(
        'references public.question_bank_attempts(id) on delete cascade',
      ),
    );
    expect(sql.contains('references public.choices'), isFalse);
    expect(
      RegExp(r'questions\(id\)\s+on delete cascade').hasMatch(sql),
      isFalse,
    );
  });

  test('enforces the simple invariants in the database', () {
    expect(sql, contains('position between 1 and 100'));
    expect(sql, contains('primary key (attempt_id, position)'));
    expect(sql, contains('(attempt_id, question_id)'));
    expect(sql, contains('selected_index is not null or is_correct = false'));
  });

  test('rls: own rows only, no update or delete policy', () {
    expect(
      sql,
      contains(
        'alter table public.question_bank_attempt_items enable row level security',
      ),
    );
    expect(sql, contains('for select'));
    expect(sql, contains('for insert'));
    expect(sql.contains('for update'), isFalse);
    expect(sql.contains('for delete'), isFalse);
    expect(sql, contains('a.user_id = (select auth.uid())'));
  });

  test('the save function is atomic, invoker-rights and idempotent', () {
    expect(sql, contains('function public.save_subject_exam_attempt('));
    expect(sql, contains('returns uuid'));
    expect(sql, contains('set search_path = public'));
    expect(sql.contains('security definer'), isFalse);
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('on conflict (user_id, client_attempt_id)'));
    expect(sql, contains('question_bank_attempts_client_attempt_uidx'));
    // The caller never supplies the user id.
    expect(sql.contains('p_user_id'), isFalse);
    expect(
      sql,
      contains('revoke all on function public.save_subject_exam_attempt'),
    );
    expect(sql, contains('to authenticated'));
  });

  test('does not touch other tables destructively', () {
    expect(sql.contains('drop table'), isFalse);
    expect(sql.contains('truncate'), isFalse);
    expect(sql.contains('delete from'), isFalse);
  });

  group('server is authoritative', () {
    late String body;
    late String clientKeys;

    setUpAll(() {
      final start = sql.indexOf(
        'create or replace function public.save_subject_exam_attempt',
      );
      final end = sql.indexOf(r'$$;', sql.indexOf(r'as $$', start));
      body = sql.substring(start, end);
      // Every JSON field read from a submitted item (`i ->> 'key'`, `i -> 'key'`).
      clientKeys = (RegExp(
        r"i\s*->>?\s*'(\w+)'",
      ).allMatches(body)).map((m) => m.group(1)!).toSet().join(',');
    });

    test('reads only session facts from the client payload', () {
      final keys = clientKeys.split(',').toSet();
      expect(keys, {
        'position',
        'question_id',
        'selected_choice_id',
        'choice_order',
      });
    });

    test('never reads correctness, text, score or counts from the client', () {
      for (final forbidden in [
        'correct_index',
        'correct_choice_id',
        'is_correct',
        'question_text',
        'choice_text',
        'choices',
        'score',
        'correct_answers',
      ]) {
        expect(clientKeys.contains(forbidden), isFalse, reason: forbidden);
      }
      expect(body.contains('p_score'), isFalse);
      expect(body.contains('p_correct'), isFalse);
      expect(body.contains('p_user_id'), isFalse);
    });

    test('resolves question, subject and choices from the Question Bank', () {
      expect(body, contains('join public.questions q on q.id = r.question_id'));
      expect(
        body,
        contains(
          'join public.quizzes z on z.id = q.quiz_id and z.subject_id = p_subject_id',
        ),
      );
      expect(body, contains('join public.choices c'));
      expect(body, contains('c.question_id = o.question_id'));
      // Text and correctness come from database columns.
      expect(body, contains('q.question_text'));
      expect(body, contains("'text', ch.choice_text"));
      expect(body, contains("'is_correct', ch.is_correct"));
    });

    test('derives score and correct count from the resolved rows', () {
      expect(body, contains("(x ->> 'is_correct')::boolean"));
      expect(body, contains('from jsonb_array_elements(v_rows) as x'));
      expect(body, contains('round(v_correct * 100.0 / v_total, 2)'));
    });

    test('rejects malformed submissions', () {
      expect(body, contains('c_expected constant integer := 100'));
      expect(body, contains('v_total <> c_expected'));
      expect(body, contains('item positions must be exactly 1..'));
      expect(body, contains('duplicate question in exam'));
      expect(
        body,
        contains('every question must exist and belong to the subject'),
      );
      expect(
        body,
        contains('choice order must list each choice of the question once'),
      );
      expect(body, contains('a question has no correct choice'));
      expect(body, contains('selected choice does not belong to its question'));
    });

    test('keeps idempotency and ignores conflicting retries', () {
      expect(body, contains('client_attempt_id = p_client_attempt_id'));
      expect(body, contains('on conflict (user_id, client_attempt_id)'));
      expect(body, contains('do nothing'));
    });
  });
}
