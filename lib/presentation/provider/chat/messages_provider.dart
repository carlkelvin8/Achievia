import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatConversationFilter { all, groups, direct }

final messagesProvider = NotifierProvider<MessagesNotifier, MessagesViewState>(
  MessagesNotifier.new,
);

class MessagesViewState {
  final ChatConversationFilter filter;
  final String searchQuery;
  final String? openingProfileId;

  const MessagesViewState({
    required this.filter,
    required this.searchQuery,
    this.openingProfileId,
  });

  List<ChatConversationEntity> filteredConversations(
    List<ChatConversationEntity> conversations,
  ) {
    return switch (filter) {
      ChatConversationFilter.all => conversations,
      ChatConversationFilter.groups =>
        conversations
            .where(
              (conversation) => conversation.type == ChatConversationType.group,
            )
            .toList(),
      ChatConversationFilter.direct =>
        conversations
            .where(
              (conversation) =>
                  conversation.type == ChatConversationType.direct,
            )
            .toList(),
    };
  }

  MessagesViewState copyWith({
    ChatConversationFilter? filter,
    String? searchQuery,
    Object? openingProfileId = _unchanged,
  }) {
    return MessagesViewState(
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      openingProfileId: openingProfileId == _unchanged
          ? this.openingProfileId
          : openingProfileId as String?,
    );
  }
}

const Object _unchanged = Object();

class MessagesNotifier extends Notifier<MessagesViewState> {
  late final TextEditingController searchController;

  @override
  MessagesViewState build() {
    searchController = TextEditingController();
    ref.onDispose(searchController.dispose);

    return const MessagesViewState(
      filter: ChatConversationFilter.all,
      searchQuery: '',
    );
  }

  void setFilter(ChatConversationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void clearSearch() {
    searchController.clear();
    state = state.copyWith(searchQuery: '');
  }

  void setOpeningProfileId(String? profileId) {
    state = state.copyWith(openingProfileId: profileId);
  }
}
