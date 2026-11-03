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

  test(
    'progress days use authenticated user UUIDs without deleting legacy IDs',
    () {
      final migration = allMigrations();

      expect(migration, contains('public.progress_days'));
      expect(migration, contains('rename column user_id to user_id_legacy'));
      expect(migration, contains('add column user_id uuid'));
      expect(migration, contains('references auth.users(id)'));
      expect(migration, contains('progress_days_user_activity_idx'));
    },
  );

  test('progress days are owner scoped for reads and upserts', () {
    final migration = allMigrations();

    expect(
      migration,
      contains('alter table public.progress_days enable row level security'),
    );
    expect(migration, contains('Users can read their own progress days'));
    expect(migration, contains('Users can insert their own progress days'));
    expect(migration, contains('Users can update their own progress days'));
    expect(migration, contains('using ((select auth.uid()) = user_id)'));
    expect(migration, contains('with check ((select auth.uid()) = user_id)'));
  });
}
