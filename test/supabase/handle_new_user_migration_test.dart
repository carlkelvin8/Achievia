import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync().toLowerCase();

String _functionBody(String sql) => RegExp(
  r'create or replace function public\.handle_new_user\(\).*?\n\$\$;',
  dotAll: true,
).firstMatch(sql)!.group(0)!.replaceAll(RegExp(r'\s+'), ' ');

String _code(String sql) => sql
    .split(RegExp(r'\r?\n'))
    .where((line) => !line.trimLeft().startsWith('--'))
    .join(' ');

void main() {
  // Comments are excluded so wording like "username policy" cannot trip checks.
  final sql = _code(
    _read('supabase/migrations/20261009000000_harden_handle_new_user.sql'),
  );

  test('keeps the hardened security posture', () {
    expect(sql, contains("security definer set search_path = ''"));
    expect(sql, contains("'user', 'active'"));
    // Clients must never choose role, status or trial entitlements.
    expect(sql, isNot(contains("meta ->> 'role'")));
    expect(sql, isNot(contains("meta ->> 'status'")));
    expect(sql, isNot(contains('trial')));
    expect(sql, isNot(contains('grant ')));
    expect(sql, isNot(contains('policy')));
  });

  test('numeric and timestamp metadata is validated before casting', () {
    expect(sql, contains(r"~ '^[0-9]{1,9}$'"));
    expect(sql, contains('exception when others then'));
    expect(sql, isNot(contains("nullif(new.raw_user_meta_data ->> 'age'")));
  });

  test('every varchar column written by the trigger is length-bounded', () {
    for (final entry in {
      'first_name': '100',
      'middle_name': '100',
      'last_name': '255',
      'profile_image': '255',
      'university': '255',
      'purpose': '255',
    }.entries) {
      expect(sql, contains("left(meta ->> '${entry.key}', ${entry.value})"));
    }
    expect(sql, contains('left(new.email, 255)'));
    expect(sql, contains("left(nullif(btrim(meta ->> 'username'), ''), 100)"));
  });

  test('an explicit username is refused when taken, never renamed', () {
    expect(sql, contains('lower(btrim(p.username)) = lower(v_username)'));
    expect(sql, contains("raise exception 'username already taken'"));
    expect(sql, contains("constraint = 'profiles_username_key'"));
    expect(sql, isNot(contains('v_suffix')));
    // A username is only generated when none was supplied.
    expect(sql, contains('if v_username is null then'));
  });

  test('failures name the constraint without leaking row values', () {
    expect(sql, contains('get stacked diagnostics'));
    expect(sql, contains('constraint_name'));
    expect(sql, contains('handle_new_user failed'));
    expect(sql, isNot(contains('new.email,\n    sqlstate')));
  });

  test('forward-only, lock-light, and touches auth.users only if needed', () {
    expect(sql, contains('set local lock_timeout'));
    expect(sql, contains('alter table public.profiles add column mantra text'));
    expect(sql, contains('drop trigger if exists on_auth_user_created'));
    expect(sql, contains('after insert on auth.users'));
    // Recreated only when missing, disabled or pointing elsewhere.
    expect(sql, contains("t.tgenabled = 'o'"));
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('delete from')));
    expect(sql, isNot(contains('truncate')));
    expect(sql, isNot(contains('drop column')));
  });

  test('diagnostic script is a single read-only SELECT', () {
    final diag = _read('supabase/reconciliation/diagnose_signup_trigger.sql');
    final code = diag
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');
    for (final write in [
      RegExp(r'\binsert\s+into\b'),
      RegExp(r'\bupdate\s+\w'),
      RegExp(r'\bdelete\s+from\b'),
      RegExp(r'\b(drop|create|alter|truncate|grant|revoke)\s'),
    ]) {
      expect(write.hasMatch(code), isFalse, reason: write.pattern);
    }
    expect(diag, contains('stale: pre-20261009 body'));
    expect(diag, contains('tgenabled'));
    expect(diag, contains('profile-email-stale'));
  });

  test('rollback restores the 20261001 function body exactly', () {
    final previous = _read(
      'supabase/migrations/20261001000000_production_security.sql',
    );
    final rollback = _read(
      'supabase/reconciliation/rollback_handle_new_user_20261009.sql',
    );
    expect(_functionBody(rollback), _functionBody(previous));
  });

  test('staging verification script always rolls back', () {
    final verify = _read(
      'supabase/reconciliation/verify_handle_new_user.sql',
    ).trim();
    expect(verify, endsWith('rollback;'));
    expect(verify, isNot(contains('commit')));
  });

  test('the email-sync trigger is only a proposal, not a migration', () {
    expect(
      File(
        'supabase/migrations/20261010000000_sync_profile_email.sql',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'supabase/proposed/20261010000000_sync_profile_email.sql',
      ).existsSync(),
      isTrue,
    );
  });
}
