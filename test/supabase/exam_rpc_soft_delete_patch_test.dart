import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The soft-delete patch for save_subject_exam_attempt is prepared but NOT
/// applied. These checks keep it reviewable and prevent it from being picked
/// up by `supabase db push` by accident.
void main() {
  const name = '20261007000000_exam_rpc_respect_soft_delete.sql';
  final patch = File('supabase/proposed/$name');

  test('stays outside supabase/migrations until approved', () {
    expect(patch.existsSync(), isTrue);
    expect(File('supabase/migrations/$name').existsSync(), isFalse);
  });

  test('requires live question, subtopic, subject and choices', () {
    final sql = patch.readAsStringSync();
    expect(sql, contains('q.deleted_at is null'));
    expect(sql, contains('z.deleted_at is null'));
    expect(sql, contains('s.deleted_at is null'));
    expect(
      'c.deleted_at is null'.allMatches(sql).length,
      greaterThanOrEqualTo(3),
    );
    expect(sql, contains('exactly one correct choice'));
  });

  test('keeps the security model of 20261005', () {
    final sql = patch.readAsStringSync().toLowerCase();
    expect(sql, isNot(contains('security definer')));
    expect(sql, contains('v_uid uuid := auth.uid()'));
    expect(
      sql,
      contains('revoke all on function public.save_subject_exam_attempt'),
    );
    expect(sql, contains('to authenticated'));
    expect(sql, isNot(contains('service_role')));
  });
}
