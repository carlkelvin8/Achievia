// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:achievia/domain/use_cases/reviewer/module_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final getModules = Provider<ModuleUseCase>((ref) {
  return sl.get<ModuleUseCase>();
});

void _logPagination(String message) {
  debugPrint('[ModulesPagination] $message');
}

final paginatedModulesProvider =
    StateNotifierProvider<ModulePaginationNotifier, ModulePaginationState>((
      ref,
    ) {
      final moduleUseCase = ref.read(getModules);
      return ModulePaginationNotifier(moduleUseCase);
    });

class ModulePaginationState {
  final List<ModuleEntity> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int total;
  final String? errorMessage;

  const ModulePaginationState({
    required this.items,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.total,
    this.errorMessage,
  });

  factory ModulePaginationState.initial() => const ModulePaginationState(
    items: [],
    isInitialLoading: true,
    isLoadingMore: false,
    hasMore: true,
    currentPage: 0,
    total: 0,
    errorMessage: null,
  );

  ModulePaginationState copyWith({
    List<ModuleEntity>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? total,
    String? errorMessage,
  }) {
    return ModulePaginationState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}

class ModulePaginationNotifier extends StateNotifier<ModulePaginationState> {
  static const int _perPage = 20;

  final ModuleUseCase _moduleUseCase;
  final Set<int> _inFlightPages = {};

  ModulePaginationNotifier(this._moduleUseCase)
    : super(ModulePaginationState.initial()) {
    _loadPage(1, reset: true);
  }

  Future<void> refresh() async {
    _logPagination('Refresh requested');
    state = ModulePaginationState.initial();
    await _loadPage(1, reset: true);
  }

  Future<void> loadMore() async {
    _logPagination(
      'LoadMore called currentPage=${state.currentPage} items=${state.items.length} total=${state.total} '
      'hasMore=${state.hasMore} initLoading=${state.isInitialLoading} loadingMore=${state.isLoadingMore}',
    );

    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) {
      _logPagination('LoadMore ignored due to state guard');
      return;
    }

    if (state.total > 0 && state.items.length >= state.total) {
      state = state.copyWith(hasMore: false);
      _logPagination(
        'LoadMore stopped: all items loaded items=${state.items.length} total=${state.total}',
      );
      return;
    }

    final nextPage = state.currentPage + 1;
    if (_inFlightPages.contains(nextPage)) {
      _logPagination('LoadMore ignored: page=$nextPage already in flight');
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    await _loadPage(nextPage, reset: false);
  }

  Future<void> _loadPage(int page, {required bool reset}) async {
    try {
      _inFlightPages.add(page);

      _logPagination('API fetch start page=$page limit=$_perPage reset=$reset');

      final result = await _moduleUseCase.getModules(
        page: page,
        limit: _perPage,
      );

      _logPagination(
        'API fetch success page=$page fetched=${result.items.length} total=${result.total} backendHasMore=${result.hasMore}',
      );

      final nextItems = reset ? result.items : [...state.items, ...result.items];
      final reachedTotal = result.total > 0 && nextItems.length >= result.total;

      state = state.copyWith(
        items: nextItems,
        isInitialLoading: false,
        isLoadingMore: false,
        currentPage: page,
        hasMore: !reachedTotal && result.hasMore,
        total: result.total,
        errorMessage: null,
      );
      _logPagination(
        'State updated page=${state.currentPage} items=${state.items.length} total=${state.total} hasMore=${state.hasMore}',
      );
      _inFlightPages.remove(page);
    } catch (e) {
      _inFlightPages.remove(page);
      _logPagination('API fetch error page=$page error=$e');
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        // Avoid automatic repeated calls from scroll listener after a failure.
        hasMore: false,
        errorMessage: e.toString(),
      );
    }
  }

}
