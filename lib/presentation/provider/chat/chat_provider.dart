import 'dart:async';

import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/domain/use_cases/chat/chat_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

final chatUseCaseProvider = Provider<ChatUseCase>((ref) => sl<ChatUseCase>());

final chatConversationsProvider = FutureProvider<List<ChatConversationEntity>>((
  ref,
) {
  return ref.read(chatUseCaseProvider).getConversations();
});

final chatPeopleSearchProvider = FutureProvider.autoDispose
    .family<List<ChatPersonEntity>, String>((ref, query) {
      final trimmedQuery = query.trim();
      if (trimmedQuery.length < 2) {
        return Future.value([]);
      }
      return ref.read(chatUseCaseProvider).searchPeople(trimmedQuery);
    });

class ChatThreadState {
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final List<ChatMessageEntity> messages;

  const ChatThreadState({
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.messages = const [],
  });

  ChatThreadState copyWith({
    bool? isLoading,
    bool? isSending,
    Object? errorMessage = _unchanged,
    List<ChatMessageEntity>? messages,
  }) {
    return ChatThreadState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      messages: messages ?? this.messages,
    );
  }

  ChatThreadState appendMessage(ChatMessageEntity message) {
    if (messages.any((existing) => existing.id == message.id)) {
      return this;
    }

    return copyWith(messages: _sortMessages([...messages, message]));
  }
}

const Object _unchanged = Object();

final chatThreadProvider = NotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThreadState, String>(
      ChatThreadNotifier.new,
    );

class ChatThreadNotifier extends Notifier<ChatThreadState> {
  final String conversationId;

  ChatThreadNotifier(this.conversationId);

  late final TextEditingController composerController;
  StreamSubscription<ChatMessageEntity>? _messagesSubscription;
  var _isDisposed = false;

  @override
  ChatThreadState build() {
    composerController = TextEditingController();
    ref.onDispose(() {
      _isDisposed = true;
      _messagesSubscription?.cancel();
      composerController.dispose();
    });

    Future<void>.microtask(load);
    _subscribe();

    return const ChatThreadState(isLoading: true);
  }

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final messages = await ref
          .read(chatUseCaseProvider)
          .getMessages(conversationId);
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        messages: _sortMessages(messages),
      );
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void _subscribe() {
    _messagesSubscription?.cancel();
    _messagesSubscription = ref
        .read(chatUseCaseProvider)
        .subscribeToMessages(conversationId)
        .listen(
          (message) {
            if (_isDisposed) {
              return;
            }
            state = state.appendMessage(message);
            ref.invalidate(chatConversationsProvider);
          },
          onError: (Object error) {
            if (_isDisposed) {
              return;
            }
            state = state.copyWith(errorMessage: error.toString());
          },
        );
  }

  Future<void> send() async {
    if (_isDisposed) {
      return;
    }
    final body = composerController.text.trim();
    if (body.isEmpty) {
      return;
    }

    state = state.copyWith(isSending: true, errorMessage: null);

    try {
      final message = await ref
          .read(chatUseCaseProvider)
          .sendMessage(conversationId, body);
      if (_isDisposed) {
        return;
      }
      composerController.clear();
      state = state
          .appendMessage(message)
          .copyWith(isSending: false, errorMessage: null);
      ref.invalidate(chatConversationsProvider);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(isSending: false, errorMessage: error.toString());
    }
  }
}

List<ChatMessageEntity> _sortMessages(List<ChatMessageEntity> messages) {
  return [...messages]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}
