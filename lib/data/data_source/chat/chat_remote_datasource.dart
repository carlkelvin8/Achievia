import 'dart:async';

import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatDataSource {
  Future<List<ChatConversationDto>> getConversations();
  Future<List<ChatMessageDto>> getMessages(String conversationId);
  Future<ChatMessageDto> sendMessage(String conversationId, String body);
  Stream<ChatMessageDto> subscribeToMessages(String conversationId);
}

@LazySingleton(as: ChatDataSource)
class ChatRemoteDatasource implements ChatDataSource {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<ChatConversationDto>> getConversations() async {
    final userId = _currentAuthUserId();
    final memberRows = await _supabase
        .from('chat_members')
        .select('conversation_id')
        .eq('profile_id', userId);

    final conversationIds = memberRows
        .map((row) => row['conversation_id'] as String)
        .toList();
    if (conversationIds.isEmpty) return [];

    final conversationRows = await _supabase
        .from('chat_conversations')
        .select(
          'id, type, title, created_by, created_at, updated_at, last_message_at, latest_message',
        )
        .inFilter('id', conversationIds)
        .order('last_message_at', ascending: false, nullsFirst: false);

    return conversationRows.map((row) {
      return ChatConversationDto.fromJson(row);
    }).toList();
  }

  @override
  Future<List<ChatMessageDto>> getMessages(String conversationId) async {
    final rows = await _supabase
        .from('chat_messages')
        .select('id, conversation_id, sender_id, body, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at')
        .limit(100);

    return rows.map((row) => ChatMessageDto.fromJson(row)).toList();
  }

  @override
  Future<ChatMessageDto> sendMessage(String conversationId, String body) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError.value(body, 'body', 'Message body cannot be empty');
    }

    final userId = _currentAuthUserId();
    final row = await _supabase
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'body': trimmedBody,
        })
        .select('id, conversation_id, sender_id, body, created_at')
        .single();

    final dto = ChatMessageDto.fromJson(row);

    await _supabase
        .from('chat_conversations')
        .update({
          'last_message_at': dto.createdAt.toIso8601String(),
          'latest_message': dto.body,
        })
        .eq('id', conversationId);

    await _supabase
        .channel('chat:$conversationId')
        .sendBroadcastMessage(
          event: 'message.created',
          payload: _messageToJson(dto),
        );

    return dto;
  }

  @override
  Stream<ChatMessageDto> subscribeToMessages(String conversationId) {
    late final RealtimeChannel channel;
    final controller = StreamController<ChatMessageDto>();

    channel = _supabase
        .channel('chat:$conversationId')
        .onBroadcast(
          event: 'message.created',
          callback: (payload) {
            final json = _messagePayload(payload);
            controller.add(ChatMessageDto.fromJson(json));
          },
        );

    controller.onListen = () {
      channel.subscribe();
    };
    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  String _currentAuthUserId() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw Exception('User is not authenticated');
    }
    return id;
  }

  Map<String, dynamic> _messageToJson(ChatMessageDto dto) {
    return {
      'id': dto.id,
      'conversation_id': dto.conversationId,
      'sender_id': dto.senderId,
      'body': dto.body,
      'created_at': dto.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _messagePayload(Map<String, dynamic> payload) {
    final json = _messagePayloadCandidate(payload);
    if (json == null) {
      throw const FormatException('Broadcast payload is missing message data');
    }
    return json;
  }

  Map<String, dynamic>? _messagePayloadCandidate(
    Map<String, dynamic> payload, [
    int depth = 0,
  ]) {
    if (_isMessageJson(payload)) return payload;
    if (depth >= 2) return null;

    final envelopePayload = payload['payload'];
    final envelopeJson = _asJsonMap(envelopePayload);
    if (envelopeJson != null) {
      final message = _messagePayloadCandidate(envelopeJson, depth + 1);
      if (message != null) return message;
    }

    final messageJson = _asJsonMap(payload['message']);
    if (messageJson != null) {
      final message = _messagePayloadCandidate(messageJson, depth + 1);
      if (message != null) return message;
    }

    return null;
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  bool _isMessageJson(Map<String, dynamic> json) {
    return json.containsKey('id') &&
        json.containsKey('conversation_id') &&
        json.containsKey('sender_id') &&
        json.containsKey('body') &&
        json.containsKey('created_at');
  }
}
