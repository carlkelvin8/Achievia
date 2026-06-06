import 'dart:async';

import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/repository/chat/chat_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ChatUseCase {
  final ChatRepository repository;

  ChatUseCase(this.repository);

  Future<List<ChatConversationEntity>> getConversations() {
    return repository.getConversations();
  }

  Future<List<ChatMessageEntity>> getMessages(String conversationId) {
    return repository.getMessages(conversationId);
  }

  Future<ChatMessageEntity> sendMessage(String conversationId, String body) {
    return repository.sendMessage(conversationId, body);
  }

  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    return repository.subscribeToMessages(conversationId);
  }
}
