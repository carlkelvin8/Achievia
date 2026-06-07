import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String allMigrations() {
    return Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n');
  }

  test('quiz attempts are owned by authenticated profile uuid', () {
    final migration = allMigrations();

    expect(migration, contains('public.quiz_attempts'));
    expect(migration, contains('student_id uuid'));
    expect(migration, contains('alter column student_id_legacy drop not null'));
    expect(migration, contains('references auth.users(id)'));
    expect(migration, contains('quiz_attempts_student_id_idx'));
  });

  test('quiz attempts RLS allows users to manage only their own attempts', () {
    final migration = allMigrations();

    expect(
      migration,
      contains('alter table public.quiz_attempts enable row level security'),
    );
    expect(migration, contains('Users can read their own quiz attempts'));
    expect(migration, contains('Users can insert their own quiz attempts'));
    expect(migration, contains('Users can update their own quiz attempts'));
    expect(migration, contains('using ((select auth.uid()) = student_id)'));
    expect(
      migration,
      contains('with check ((select auth.uid()) = student_id)'),
    );
  });

  test('quiz attempts can store summary snapshots without a quiz row', () {
    final migration = allMigrations();

    expect(migration, contains("constraint_record.contype = 'f'"));
    expect(migration, contains("attribute_record.attname = 'quiz_id'"));
    expect(migration, contains('alter column quiz_id drop not null'));
  });
}
