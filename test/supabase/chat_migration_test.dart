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

  test('chat migration defines people search RPC used by autocomplete', () {
    final migration = allMigrations();

    expect(migration, contains('function public.search_profiles_for_chat'));
    expect(migration, contains('function public.chat_profile_summaries'));
    expect(migration, contains('function public.get_or_create_direct_chat'));
    expect(migration, contains('grant execute on function'));
  });

  test('chat RPCs are defined once with the response shape used by Flutter', () {
    final migration = allMigrations();

    expect(
      'create or replace function public.search_profiles_for_chat'
          .allMatches(migration),
      hasLength(1),
    );
    expect(
      'create or replace function public.chat_profile_summaries'
          .allMatches(migration),
      hasLength(1),
    );
    expect(
      'create or replace function public.get_or_create_direct_chat'
          .allMatches(migration),
      hasLength(1),
    );
    expect(
      migration,
      contains(
        'function public.get_or_create_direct_chat(target_profile_id uuid)\n'
        'returns jsonb',
      ),
    );
  });
}
