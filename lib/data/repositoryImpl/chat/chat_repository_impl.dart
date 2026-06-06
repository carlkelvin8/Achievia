import 'dart:async';

import 'package:achievia/data/data_source/chat/chat_remote_datasource.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/domain/repository/chat/chat_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatDataSource datasource;

  ChatRepositoryImpl(this.datasource);

  @override
  Future<List<ChatConversationEntity>> getConversations() async {
    final dtos = await datasource.getConversations();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    final dtos = await datasource.getMessages(conversationId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<ChatPersonEntity>> searchPeople(String query) async {
    final dtos = await datasource.searchPeople(query);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ChatConversationEntity> startDirectConversation(
    String profileId,
  ) async {
    final dto = await datasource.startDirectConversation(profileId);
    return dto.toEntity();
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String body,
  ) async {
    final dto = await datasource.sendMessage(conversationId, body);
    return dto.toEntity();
  }

  @override
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    return datasource
        .subscribeToMessages(conversationId)
        .map((dto) => dto.toEntity());
  }
}
