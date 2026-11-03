import 'dart:io';

import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/data_source/home/daily_motivation_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/home/daily_motivation_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:achievia/presentation/screens/admin/daily_motivation_admin_screen.dart';
import 'package:achievia/presentation/widgets/banners/build_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longNew =
    'Every chapter you finish today is one less worry on board exam day. Keep '
    'your pace steady, ask for help when a topic feels heavy, and trust the '
    'process.';
const _longEdited =
    'Progress is not always loud. Some days it is one more practice set or one '
    'more page of notes, and that quiet effort is exactly what builds a '
    'licensed professional.';

class FakeDataSource implements DailyMotivationDataSource {
  final List<Map<String, dynamic>> rows = [];
  bool fail = false;
  bool admin = true;
  int fetchCount = 0;
  int _next = 1;

  void seed(String message, {bool active = true, int order = 0}) => rows.add({
    'id': 'id${_next++}',
    'message': message,
    'is_active': active,
    'display_order': order,
    'created_at': '2026-01-01T00:00:00Z',
  });

  @override
  Future<List<Map<String, dynamic>>> fetchActive() async {
    fetchCount++;
    if (fail) throw Exception('network');
    final active = rows.where((r) => r['is_active'] == true).toList();
    active.sort(
      (a, b) => (a['display_order'] as int).compareTo(b['display_order']),
    );
    return active;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => List.of(rows);

  @override
  Future<void> insert(String message, {required int displayOrder}) async =>
      seed(message, order: displayOrder);

  @override
  Future<void> updateMessage(String id, String message) async =>
      rows.firstWhere((r) => r['id'] == id)['message'] = message;

  @override
  Future<void> setActive(String id, bool active) async =>
      rows.firstWhere((r) => r['id'] == id)['is_active'] = active;

  @override
  Future<void> delete(String id) async =>
      rows.removeWhere((r) => r['id'] == id);

  @override
  Future<bool> isAdmin() async => admin;
}

// 2026-03-10 00:30 in UTC+8 is still 2026-03-09 in UTC.
final _day1 = DateTime.utc(2026, 3, 9, 16, 30);
final _day1Evening = DateTime.utc(2026, 3, 10, 9, 0);
final _day2 = DateTime.utc(2026, 3, 10, 16, 30);

Future<(DailyMotivationRepositoryImpl, FakeDataSource)> _repo() async {
  SharedPreferences.setMockInitialValues({});
  final ds = FakeDataSource()
    ..seed('A', order: 1)
    ..seed('B', order: 2)
    ..seed('C', order: 3);
  final storage = LocalStorageService(await SharedPreferences.getInstance());
  return (DailyMotivationRepositoryImpl(ds, storage), ds);
}

void main() {
  group('DailyMotivationPicker', () {
    test('day key uses UTC+8 and is stable during the day', () {
      expect(DailyMotivationPicker.dayKey(_day1), '2026-03-10');
      expect(DailyMotivationPicker.dayKey(_day1Evening), '2026-03-10');
      expect(DailyMotivationPicker.dayKey(_day2), '2026-03-11');
    });

    test('same day same pick, next day next pick, empty is null', () {
      final list = [
        'A',
        'B',
        'C',
      ].map((m) => DailyMotivationEntity(id: m, message: m)).toList();
      final a = DailyMotivationPicker.pick(list, _day1)!;
      expect(DailyMotivationPicker.pick(list, _day1Evening)!.id, a.id);
      final b = DailyMotivationPicker.pick(list, _day2)!;
      expect(list.indexOf(b), (list.indexOf(a) + 1) % 3);
      expect(DailyMotivationPicker.pick(const [], _day1), isNull);
    });

    test('validation trims, rejects blank, too short and too long', () {
      expect(DailyMotivationEntity.validateMessage('   '), isNotNull);
      expect(DailyMotivationEntity.validateMessage(null), isNotNull);
      expect(DailyMotivationEntity.validateMessage(' ok '), isNotNull);
      expect(DailyMotivationEntity.validateMessage('x' * 149), isNotNull);
      expect(DailyMotivationEntity.validateMessage(' ${'x' * 150} '), isNull);
      expect(DailyMotivationEntity.validateMessage('x' * 281), isNotNull);
    });

    test('the starter messages are rewritten to at least 150 characters', () {
      final sql = File(
        'supabase/proposed/20261024000000_daily_motivations_min_length.sql',
      ).readAsStringSync();
      final rows = RegExp(
        r"\(\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)'\)",
      ).allMatches(sql).toList();
      expect(rows, hasLength(5));
      for (final row in rows) {
        final message = row.group(2)!.replaceAll("''", "'");
        expect(DailyMotivationEntity.validateMessage(message), isNull);
      }
    });
  });

  group('DailyMotivationRepositoryImpl', () {
    test('same day is stable, next day rotates, inactive excluded', () async {
      final (repo, ds) = await _repo();
      ds.rows[0]['is_active'] = false; // A inactive
      final first = await repo.getTodayMotivation(now: _day1);
      expect(first!.message, isNot('A'));
      expect((await repo.getTodayMotivation(now: _day1Evening))!.id, first.id);
      final next = await repo.getTodayMotivation(now: _day2);
      expect(next!.id, isNot(first.id));
      expect(next.message, isNot('A'));
    });

    test('replaces cached pick only when it is deactivated', () async {
      final (repo, ds) = await _repo();
      final first = (await repo.getTodayMotivation(now: _day1))!;
      ds.seed('D', order: 0); // pool changes; pick must not
      expect((await repo.getTodayMotivation(now: _day1Evening))!.id, first.id);
      ds.rows.firstWhere((r) => r['id'] == first.id)['is_active'] = false;
      final replaced = await repo.getTodayMotivation(now: _day1Evening);
      expect(replaced!.id, isNot(first.id));
    });

    test('offline uses today cache, otherwise null; empty is null', () async {
      final (repo, ds) = await _repo();
      final first = await repo.getTodayMotivation(now: _day1);
      ds.fail = true;
      expect((await repo.getTodayMotivation(now: _day1Evening))!.id, first!.id);
      expect(await repo.getTodayMotivation(now: _day2), isNull);
      ds.fail = false;
      ds.rows.clear();
      expect(await repo.getTodayMotivation(now: _day2), isNull);
    });

    test('admin add/edit/activate/deactivate/delete + validation', () async {
      final (repo, ds) = await _repo();
      await repo.add('  $_longNew  ');
      expect(ds.rows.last['message'], _longNew);
      expect(ds.rows.last['display_order'], 4);
      await expectLater(repo.add('   '), throwsArgumentError);
      final id = ds.rows.last['id'] as String;
      await repo.edit(id, _longEdited);
      expect(ds.rows.last['message'], _longEdited);
      await repo.setActive(id, false);
      expect(ds.rows.last['is_active'], isFalse);
      await repo.setActive(id, true);
      expect(ds.rows.last['is_active'], isTrue);
      await repo.delete(id);
      expect((await repo.listAll()).length, 3);
    });
  });

  test('migration restricts writes to active admins and orders rotation', () {
    final sql = File(
      'supabase/migrations/20261003000000_daily_motivations.sql',
    ).readAsStringSync();
    for (final op in ['insert', 'update', 'delete']) {
      expect(sql, contains('create policy "Admins $op daily motivations"'));
    }
    expect(sql, contains("p.role = 'ADMIN'"));
    expect(sql, contains('enable row level security'));
    expect(sql, isNot(contains('to anon')));
    expect(sql, contains('display_order, created_at, id'));
  });

  group('UI', () {
    testWidgets('banner shows message, hides when empty, long text ok', (
      tester,
    ) async {
      Future<void> pump(DailyMotivationEntity? m, {double scale = 1}) async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [dailyMotivationProvider.overrideWith((ref) async => m)],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 640),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const Scaffold(body: MotivationQuoteBanner()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(const DailyMotivationEntity(id: '1', message: 'Keep going'));
      expect(find.text('Keep going'), findsOneWidget);
      await pump(null);
      expect(find.byType(MotivationQuoteCard), findsNothing);
      await pump(
        DailyMotivationEntity(id: '2', message: 'long text ' * 28),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin screen: non-admin blocked, admin can add and toggle', (
      tester,
    ) async {
      final ds = FakeDataSource()..seed('Existing', order: 1);
      SharedPreferences.setMockInitialValues({});
      final repo = DailyMotivationRepositoryImpl(
        ds,
        LocalStorageService(await SharedPreferences.getInstance()),
      );

      Future<void> pump() async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              dailyMotivationRepositoryProvider.overrideWithValue(repo),
              activeAccountIdProvider.overrideWith((ref) => Stream.value('u')),
            ],
            child: const MaterialApp(home: DailyMotivationAdminScreen()),
          ),
        );
        await tester.pumpAndSettle();
      }

      ds.admin = false;
      await pump();
      expect(find.text('Admins only.'), findsOneWidget);
      expect(find.text('Existing'), findsNothing);

      ds.admin = true;
      await pump();
      expect(find.text('Existing'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a message.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Too short');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 150 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '  $_longNew  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(ds.rows.map((r) => r['message']), contains(_longNew));

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(ds.rows.first['is_active'], isFalse);
    });
  });
}
