import 'package:achievia/core/utils/auth_error_utils.dart';
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
      if (!isChatPeopleAutocompleteActive(trimmedQuery)) {
        return Future.value([]);
      }
      return ref.read(chatUseCaseProvider).searchPeople(trimmedQuery);
    });

bool isChatPeopleAutocompleteActive(String query) => query.trim().length >= 2;

class ChatThreadState {
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final List<ChatMessageEntity> messages;
  final Set<String> typingProfileIds;

  const ChatThreadState({
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.messages = const [],
    this.typingProfileIds = const {},
  });

  bool get isAnyoneTyping => typingProfileIds.isNotEmpty;

  ChatThreadState copyWith({
    bool? isLoading,
    bool? isSending,
    Object? errorMessage = _unchanged,
    List<ChatMessageEntity>? messages,
    Set<String>? typingProfileIds,
  }) {
    return ChatThreadState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      messages: messages ?? this.messages,
      typingProfileIds: typingProfileIds ?? this.typingProfileIds,
    );
  }

  ChatThreadState appendMessage(ChatMessageEntity message) {
    if (messages.any((existing) => existing.id == message.id)) {
      return this;
    }

    return copyWith(messages: _sortMessages([...messages, message]));
  }

  ChatThreadState applyTypingIndicator({
    required String profileId,
    required bool isTyping,
  }) {
    final nextTypingProfileIds = {...typingProfileIds};
    if (isTyping) {
      nextTypingProfileIds.add(profileId);
    } else {
      nextTypingProfileIds.remove(profileId);
    }

    return copyWith(typingProfileIds: nextTypingProfileIds);
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

  late TextEditingController composerController;
  StreamSubscription<ChatMessageEntity>? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingIdleTimer;

  /// Clears a remote "is typing" flag when no update arrives. The sender
  /// stops after 3 seconds of idling, but a closed app never sends `false`.
  final Map<String, Timer> _remoteTypingTimers = {};
  static const _remoteTypingTimeout = Duration(seconds: 6);
  var _lastTypingSent = false;
  var _isDisposed = false;

  @override
  ChatThreadState build() {
    composerController = TextEditingController();
    composerController.addListener(_onComposerChanged);
    ref.onDispose(() {
      _isDisposed = true;
      composerController.removeListener(_onComposerChanged);
      _typingIdleTimer?.cancel();
      for (final timer in _remoteTypingTimers.values) {
        timer.cancel();
      }
      _remoteTypingTimers.clear();
      _messagesSubscription?.cancel();
      _typingSubscription?.cancel();
      if (_lastTypingSent) {
        unawaited(_sendTypingIndicator(false));
      }
      composerController.dispose();
    });

    Future<void>.microtask(load);
    _subscribe();
    _subscribeToTyping();

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
        messages: _sortMessages(
          {
            for (final message in [...messages, ...state.messages])
              message.id: message,
          }.values.toList(),
        ),
      );
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: userFacingError(error),
      );
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
            state = state.copyWith(errorMessage: userFacingError(error));
          },
        );
  }

  void _subscribeToTyping() {
    _typingSubscription?.cancel();
    _typingSubscription = ref
        .read(chatUseCaseProvider)
        .subscribeToTypingIndicators(conversationId)
        .listen(
          (event) {
            if (_isDisposed) {
              return;
            }
            _remoteTypingTimers.remove(event.profileId)?.cancel();
            if (event.isTyping) {
              _remoteTypingTimers[event.profileId] = Timer(
                _remoteTypingTimeout,
                () {
                  _remoteTypingTimers.remove(event.profileId);
                  if (_isDisposed) return;
                  state = state.applyTypingIndicator(
                    profileId: event.profileId,
                    isTyping: false,
                  );
                },
              );
            }
            state = state.applyTypingIndicator(
              profileId: event.profileId,
              isTyping: event.isTyping,
            );
          },
          onError: (Object error) {
            if (_isDisposed) {
              return;
            }
            state = state.copyWith(errorMessage: userFacingError(error));
          },
        );
  }

  void _onComposerChanged() {
    if (_isDisposed) {
      return;
    }

    final isTyping = composerController.text.trim().isNotEmpty;
    if (isTyping) {
      if (!_lastTypingSent) {
        unawaited(_sendTypingIndicator(true));
      }
      _typingIdleTimer?.cancel();
      _typingIdleTimer = Timer(const Duration(seconds: 3), () {
        unawaited(_sendTypingIndicator(false));
      });
      return;
    }

    _typingIdleTimer?.cancel();
    if (_lastTypingSent) {
      unawaited(_sendTypingIndicator(false));
    }
  }

  Future<void> _sendTypingIndicator(bool isTyping) async {
    if (_lastTypingSent == isTyping) {
      return;
    }
    _lastTypingSent = isTyping;
    try {
      await ref
          .read(chatUseCaseProvider)
          .sendTypingIndicator(conversationId, isTyping);
    } catch (_) {
      // Typing indicators are ephemeral; message send/read should not fail
      // because a transient presence broadcast failed.
    }
  }

  Future<void> send() async {
    if (_isDisposed || state.isSending) {
      return;
    }
    final body = composerController.text.trim();
    if (body.isEmpty) {
      return;
    }

    state = state.copyWith(isSending: true, errorMessage: null);
    await _sendTypingIndicator(false);

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
      state = state.copyWith(
        isSending: false,
        errorMessage: userFacingError(error),
      );
    }
  }
}

List<ChatMessageEntity> _sortMessages(List<ChatMessageEntity> messages) {
  return [...messages]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}
