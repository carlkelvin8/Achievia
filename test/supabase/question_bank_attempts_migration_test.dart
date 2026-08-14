import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String migrations() => Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .map((file) => file.readAsStringSync())
      .join('\n')
      .toLowerCase();

  test('question bank attempts store scored topic practice', () {
    final sql = migrations();

    expect(
      sql,
      contains('create table if not exists public.question_bank_attempts'),
    );
    expect(sql, contains('correct_answers integer not null'));
    expect(sql, contains('total_questions integer not null'));
    expect(sql, contains('score numeric(5,2) not null'));
    expect(sql, contains('check (correct_answers <= total_questions)'));
    expect(sql, contains('question_bank_attempts_user_completed_idx'));
    expect(sql, contains('question_bank_attempts_user_quiz_idx'));
  });

  test('question bank attempts are owner scoped', () {
    final sql = migrations();

    expect(
      sql,
      contains(
        'alter table public.question_bank_attempts enable row level security',
      ),
    );
    expect(sql, contains('using ((select auth.uid()) = user_id)'));
    expect(sql, contains('with check ((select auth.uid()) = user_id)'));
  });
}
