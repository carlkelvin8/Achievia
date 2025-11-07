import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/author_entity.dart';

// Author items provider
final authorItemsProvider = Provider<List<AuthorEntity>>((ref) {
  return demoAuthorItems;
});

// Expandable items state for Achievia screen
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
  ExpandableItemsState build() {
    return ExpandableItemsState(expandedItems: {0: true});
  }

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
      () => ExpandableItemsNotifier(),
    );
