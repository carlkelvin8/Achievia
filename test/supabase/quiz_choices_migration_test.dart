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

  test('choices table allows authenticated reads for quiz rendering', () {
    final migration = allMigrations();

    expect(migration, contains('public.choices'));
    expect(migration, contains('Authenticated users can read choices'));
    expect(migration, contains('for select'));
    expect(migration, contains('to authenticated'));
    expect(migration, contains('using (true)'));
  });
}
