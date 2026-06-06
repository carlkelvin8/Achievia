import 'dart:async';

import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';

abstract class ChatRepository {
  Future<List<ChatConversationEntity>> getConversations();
  Future<List<ChatMessageEntity>> getMessages(String conversationId);
  Future<List<ChatPersonEntity>> searchPeople(String query);
  Future<ChatConversationEntity> startDirectConversation(String profileId);
  Future<ChatMessageEntity> sendMessage(String conversationId, String body);
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId);
}
