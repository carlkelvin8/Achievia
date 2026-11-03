import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/data_source/home/daily_motivation_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/home/daily_motivation_repository_impl.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DataSource implements DailyMotivationDataSource {
  _DataSource(this.rows);
  final List<Map<String, dynamic>> rows;
  bool fail = false;
  int fetches = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchActive() async {
    fetches++;
    if (fail) throw Exception('relation "daily_motivations" does not exist');
    return rows.where((r) => r['is_active'] == true).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => rows;
  @override
  Future<void> insert(String message, {required int displayOrder}) async {}
  @override
  Future<void> updateMessage(String id, String message) async {}
  @override
  Future<void> setActive(String id, bool active) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<bool> isAdmin() async => false;
}

Map<String, dynamic> _row(String id, String message, {bool active = true}) => {
  'id': id,
  'message': message,
  'is_active': active,
  'display_order': int.parse(id),
  'created_at': '2026-01-01T00:00:00Z',
};

Future<void> _pumpHome(
  WidgetTester tester,
  _DataSource ds, {
  required DateTime Function() clock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        dailyMotivationRepositoryProvider.overrideWithValue(
          DailyMotivationRepositoryImpl(ds, storage),
        ),
        activeAccountIdProvider.overrideWith((ref) => Stream.value('user-1')),
        taskClockProvider.overrideWithValue(clock),
        topMockboardAchieviansProvider.overrideWith(
          (ref) async => <LeaderboardEntry>[],
        ),
        topStudyTimeAchieviansProvider.overrideWith(
          (ref) async => <LeaderboardEntry>[],
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final day1 = DateTime.utc(2026, 3, 10, 2); // 10:00 in UTC+8
  final day2 = DateTime.utc(2026, 3, 11, 2);

  testWidgets('Homepage renders the active daily motivation from data', (
    tester,
  ) async {
    final ds = _DataSource([
      _row('1', 'Message A'),
      _row('2', 'Message B'),
      _row('3', 'Hidden inactive', active: false),
    ]);
    await _pumpHome(tester, ds, clock: () => day1);

    final shown = [
      'Message A',
      'Message B',
    ].where((m) => find.text(m).evaluate().isNotEmpty).toList();
    expect(shown, hasLength(1));
    expect(find.text('Hidden inactive'), findsNothing);
    // Placed in the top section, before Question of the day.
    final quoteY = tester.getTopLeft(find.text(shown.single)).dy;
    final qotdY = tester.getTopLeft(find.text('Question of the day')).dy;
    expect(quoteY, lessThan(qotdY));
  });

  testWidgets('same day is stable across rebuilds; next day rotates', (
    tester,
  ) async {
    final ds = _DataSource([_row('1', 'Message A'), _row('2', 'Message B')]);
    await _pumpHome(tester, ds, clock: () => day1);
    final first = find.text('Message A').evaluate().isNotEmpty
        ? 'Message A'
        : 'Message B';
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(first), findsOneWidget);
    expect(ds.fetches, 1, reason: 'rebuilds must not refetch');

    await _pumpHome(tester, ds, clock: () => day2);
    final second = first == 'Message A' ? 'Message B' : 'Message A';
    expect(find.text(second), findsOneWidget);
  });

  testWidgets('no active motivations does not crash the Homepage', (
    tester,
  ) async {
    final ds = _DataSource([_row('1', 'Off', active: false)]);
    await _pumpHome(tester, ds, clock: () => day1);
    expect(tester.takeException(), isNull);
    expect(find.text('Question of the day'), findsOneWidget);
  });

  testWidgets('a failing query keeps the Homepage working', (tester) async {
    final ds = _DataSource([_row('1', 'Message A')])..fail = true;
    await _pumpHome(tester, ds, clock: () => day1);
    expect(tester.takeException(), isNull);
    expect(find.text('Question of the day'), findsOneWidget);
    expect(find.textContaining('does not exist'), findsNothing);
  });
}
