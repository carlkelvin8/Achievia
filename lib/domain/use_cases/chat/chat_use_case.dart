import 'dart:async';

import 'package:achievia/data/repositoryImpl/chat/chat_repository_impl.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_typing_event_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class ChatUseCase {
  final ChatRepositoryImpl repository;

  ChatUseCase(this.repository);

  Future<List<ChatConversationEntity>> getConversations() async {
    return await repository.getConversations();
  }

  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    return await repository.getMessages(conversationId);
  }

  Future<List<ChatPersonEntity>> searchPeople(String query) async {
    return await repository.searchPeople(query);
  }

  Future<ChatConversationEntity> startDirectConversation(
    String profileId,
  ) async {
    return await repository.startDirectConversation(profileId);
  }

  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String body,
  ) async {
    return await repository.sendMessage(conversationId, body);
  }

  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    return repository.subscribeToMessages(conversationId);
  }

  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    await repository.sendTypingIndicator(conversationId, isTyping);
  }

  Stream<ChatTypingEventEntity> subscribeToTypingIndicators(
    String conversationId,
  ) {
    return repository.subscribeToTypingIndicators(conversationId);
  }
}
