import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/widgets/author_entity.dart';
import 'package:achievia/domain/use_cases/about/author_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authorItemsProvider = FutureProvider<List<AuthorEntity>>((ref) {
  return sl<AuthorUseCase>().getAuthors();
});

class ExpandableItemsState {
  final Map<int, bool> expandedItems;

  const ExpandableItemsState({required this.expandedItems});

  ExpandableItemsState copyWith({Map<int, bool>? expandedItems}) {
    return ExpandableItemsState(
      expandedItems: expandedItems ?? this.expandedItems,
    );
  }
}

class ExpandableItemsNotifier extends Notifier<ExpandableItemsState> {
  @override
  ExpandableItemsState build() =>
      const ExpandableItemsState(expandedItems: {0: true});

  void toggleExpanded(int index) {
    final newState = Map<int, bool>.from(state.expandedItems);
    newState[index] = !(newState[index] ?? false);
    state = state.copyWith(expandedItems: newState);
  }

  void setExpanded(int index, bool isExpanded) {
    final newState = Map<int, bool>.from(state.expandedItems);
    newState[index] = isExpanded;
    state = state.copyWith(expandedItems: newState);
  }
}

final expandableItemsProvider =
    NotifierProvider<ExpandableItemsNotifier, ExpandableItemsState>(
      ExpandableItemsNotifier.new,
    );

// Separate provider for Mission/Vision/Core Values section
final mvcExpandableItemsProvider =
    NotifierProvider<ExpandableItemsNotifier, ExpandableItemsState>(
      ExpandableItemsNotifier.new,
    );
