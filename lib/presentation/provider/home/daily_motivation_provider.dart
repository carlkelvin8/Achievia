import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/data_source/home/daily_motivation_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/home/daily_motivation_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';
import 'package:achievia/domain/repository/home/daily_motivation_repository.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyMotivationRepositoryProvider = Provider<DailyMotivationRepository>(
  (ref) => DailyMotivationRepositoryImpl(
    DailyMotivationRemoteDatasource(),
    sl<LocalStorageService>(),
  ),
);

/// Current calendar day in the app timezone. Re-checked when the app resumes,
/// so no timer has to stay alive until midnight.
final motivationDayProvider = NotifierProvider<MotivationDayNotifier, String>(
  MotivationDayNotifier.new,
);

class MotivationDayNotifier extends Notifier<String> {
  late _AppResumeObserver _observer;

  String _today() =>
      DailyMotivationPicker.dayKey(ref.read(taskClockProvider)());

  @override
  String build() {
    final binding = WidgetsBinding.instance;
    _observer = _AppResumeObserver(refresh);
    binding.addObserver(_observer);
    ref.onDispose(() => binding.removeObserver(_observer));
    return _today();
  }

  void refresh() {
    final today = _today();
    if (today != state) state = today;
  }
}

/// Re-checks the day when the app comes back to the foreground, so no timer has
/// to stay alive until midnight.
class _AppResumeObserver with WidgetsBindingObserver {
  _AppResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// Today's motivation, or null (hide the section) when none can be resolved.
/// Only re-runs when the day or the signed-in account changes.
final dailyMotivationProvider = FutureProvider<DailyMotivationEntity?>((
  ref,
) async {
  ref.watch(motivationDayProvider);
  final accountId = await ref.watch(activeAccountIdProvider.future);
  if (accountId == null) return null;
  final now = ref.read(taskClockProvider)();
  return ref
      .read(dailyMotivationRepositoryProvider)
      .getTodayMotivation(now: now);
});

final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  await ref.watch(activeAccountIdProvider.future);
  return ref.read(dailyMotivationRepositoryProvider).isAdmin();
});

final adminMotivationsProvider =
    AsyncNotifierProvider.autoDispose<
      AdminMotivationsNotifier,
      List<DailyMotivationEntity>
    >(AdminMotivationsNotifier.new);

class AdminMotivationsNotifier
    extends AsyncNotifier<List<DailyMotivationEntity>> {
  DailyMotivationRepository get _repo =>
      ref.read(dailyMotivationRepositoryProvider);

  @override
  Future<List<DailyMotivationEntity>> build() => _repo.listAll();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listAll);
  }

  Future<void> add(String message) => _mutate(() => _repo.add(message));

  Future<void> edit(String id, String message) =>
      _mutate(() => _repo.edit(id, message));

  Future<void> setActive(String id, bool active) =>
      _mutate(() => _repo.setActive(id, active));

  Future<void> delete(String id) => _mutate(() => _repo.delete(id));

  /// Runs a write and refetches the list. Errors propagate to the caller so
  /// the UI can show feedback while the current list stays on screen.
  Future<void> _mutate(Future<void> Function() write) async {
    await write();
    final fresh = await _repo.listAll();
    state = AsyncData(fresh);
    ref.invalidate(dailyMotivationProvider);
  }
}
