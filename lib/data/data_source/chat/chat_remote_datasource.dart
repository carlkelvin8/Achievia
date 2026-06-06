import 'dart:async';

import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:achievia/data/models/chat/chat_person_dto.dart';
import 'package:achievia/domain/entities/api/chat/chat_typing_event_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatDataSource {
  Future<List<ChatConversationDto>> getConversations();
  Future<List<ChatMessageDto>> getMessages(String conversationId);
  Future<List<ChatPersonDto>> searchPeople(String query);
  Future<ChatConversationDto> startDirectConversation(String profileId);
  Future<ChatMessageDto> sendMessage(String conversationId, String body);
  Stream<ChatMessageDto> subscribeToMessages(String conversationId);
  Future<void> sendTypingIndicator(String conversationId, bool isTyping);
  Stream<ChatTypingEventEntity> subscribeToTypingIndicators(
    String conversationId,
  );
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

    final directTitles = await _directConversationTitles(
      currentUserId: userId,
      conversationRows: conversationRows,
    );

    return conversationRows.map((row) {
      final json = Map<String, dynamic>.from(row);
      json['title'] = directTitles[json['id']] ?? json['title'];
      return ChatConversationDto.fromJson(json);
    }).toList();
  }

  Future<Map<String, String>> _directConversationTitles({
    required String currentUserId,
    required List<dynamic> conversationRows,
  }) async {
    final directConversationIds = conversationRows
        .where((row) => row['type'] == 'direct')
        .where((row) {
          final title = row['title'] as String?;
          return title == null || title.trim().isEmpty;
        })
        .map((row) => row['id'] as String)
        .toList();

    if (directConversationIds.isEmpty) {
      return {};
    }

    final memberRows = await _supabase
        .from('chat_members')
        .select('conversation_id, profile_id')
        .inFilter('conversation_id', directConversationIds);

    final targetProfileByConversation = <String, String>{};
    final targetProfileIds = <String>{};
    for (final row in memberRows) {
      final profileId = row['profile_id'] as String;
      if (profileId == currentUserId) {
        continue;
      }

      final conversationId = row['conversation_id'] as String;
      targetProfileByConversation[conversationId] = profileId;
      targetProfileIds.add(profileId);
    }

    if (targetProfileIds.isEmpty) {
      return {};
    }

    final profileRows = await _supabase.rpc<List<dynamic>>(
      'chat_profile_summaries',
      params: {'profile_ids': targetProfileIds.toList()},
    );

    final peopleById = {
      for (final row in profileRows)
        row['id'] as String: ChatPersonDto.fromJson(
          Map<String, dynamic>.from(row),
        ).toEntity(),
    };

    return {
      for (final entry in targetProfileByConversation.entries)
        if (peopleById[entry.value] != null)
          entry.key: peopleById[entry.value]!.displayName,
    };
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
  Future<List<ChatPersonDto>> searchPeople(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return [];
    }

    _currentAuthUserId();
    final rows = await _supabase.rpc<List<dynamic>>(
      'search_profiles_for_chat',
      params: {'search_query': trimmedQuery},
    );

    return rows
        .map((row) => ChatPersonDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<ChatConversationDto> startDirectConversation(String profileId) async {
    final trimmedProfileId = profileId.trim();
    if (trimmedProfileId.isEmpty) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'Profile ID is required',
      );
    }

    _currentAuthUserId();
    final rows = await _supabase.rpc<List<dynamic>>(
      'get_or_create_direct_chat',
      params: {'target_profile_id': trimmedProfileId},
    );

    if (rows.isEmpty) {
      throw Exception('Unable to start direct chat');
    }

    return ChatConversationDto.fromJson(Map<String, dynamic>.from(rows.first));
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

  @override
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    final profileId = _currentAuthUserId();
    final channel = _supabase.channel('chat-typing:$conversationId');
    await channel.sendBroadcastMessage(
      event: 'typing.changed',
      payload: {
        'conversation_id': conversationId,
        'profile_id': profileId,
        'is_typing': isTyping,
      },
    );
    await _supabase.removeChannel(channel);
  }

  @override
  Stream<ChatTypingEventEntity> subscribeToTypingIndicators(
    String conversationId,
  ) {
    final currentProfileId = _currentAuthUserId();
    late final RealtimeChannel channel;
    final controller = StreamController<ChatTypingEventEntity>();

    channel = _supabase
        .channel('chat-typing:$conversationId')
        .onBroadcast(
          event: 'typing.changed',
          callback: (payload) {
            final json = _typingPayload(payload);
            if (json == null) {
              return;
            }

            final profileId = json['profile_id'] as String?;
            final isTyping = json['is_typing'] as bool?;
            if (profileId == null ||
                profileId == currentProfileId ||
                isTyping == null) {
              return;
            }

            controller.add(
              ChatTypingEventEntity(profileId: profileId, isTyping: isTyping),
            );
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

  Map<String, dynamic>? _typingPayload(Map<String, dynamic> payload) {
    final direct = _asJsonMap(payload);
    if (direct != null && direct.containsKey('profile_id')) {
      return direct;
    }

    final nested = _asJsonMap(payload['payload']);
    if (nested != null && nested.containsKey('profile_id')) {
      return nested;
    }

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
