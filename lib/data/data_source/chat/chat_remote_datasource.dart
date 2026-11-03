import 'dart:async';

import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:achievia/data/models/chat/chat_person_dto.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_typing_event_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatDataSource {
  Future<List<ChatConversationDto>> getConversations();
  Future<List<ChatMessageDto>> getMessages(String conversationId);
  Future<List<ChatPersonDto>> searchPeople(String query);
  Future<List<ChatPersonDto>> listPeople({int limit = 50, int offset = 0});
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
  final SupabaseClient? client;
  ChatRemoteDatasource({@ignoreParam this.client});

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

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

    final directPeople = await _directConversationPeople(
      currentUserId: userId,
      conversationRows: conversationRows,
    );

    return conversationRows.map((row) {
      final json = Map<String, dynamic>.from(row);
      final person = directPeople[json['id']];
      json['title'] = person?.displayName ?? json['title'];
      json['profile_image'] = person?.profileImage;
      return ChatConversationDto.fromJson(json);
    }).toList();
  }

  /// The other person in each direct conversation (name and picture).
  Future<Map<String, ChatPersonEntity>> _directConversationPeople({
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
          entry.key: peopleById[entry.value]!,
    };
  }

  @override
  Future<List<ChatMessageDto>> getMessages(String conversationId) async {
    final rows = await _supabase
        .from('chat_messages')
        .select('id, conversation_id, sender_id, body, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(100);

    return rows.reversed.map((row) => ChatMessageDto.fromJson(row)).toList();
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
  Future<List<ChatPersonDto>> listPeople({
    int limit = 50,
    int offset = 0,
  }) async {
    _currentAuthUserId();
    final rows = await _supabase.rpc<List<dynamic>>(
      'list_profiles_for_chat',
      params: {'result_limit': limit, 'result_offset': offset},
    );

    return rows
        .map((row) => ChatPersonDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// The first object of an RPC result that is either one object or a list.
  static Map<String, dynamic>? _singleRow(Object? result) {
    final value = result is List
        ? (result.isEmpty ? null : result.first)
        : result;
    return value is Map ? Map<String, dynamic>.from(value) : null;
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
    // The function is declared as returning one conversation object, but a
    // deployed variant answers with a one-element list. Both are accepted so
    // opening a chat never depends on which one the database returns.
    final result = await _supabase.rpc<dynamic>(
      'get_or_create_direct_chat',
      params: {'target_profile_id': trimmedProfileId},
    );
    final row = _singleRow(result);
    if (row == null || row.isEmpty) {
      throw Exception('Unable to start direct chat');
    }

    return ChatConversationDto.fromJson(row);
  }

  @override
  Future<ChatMessageDto> sendMessage(String conversationId, String body) async {
    final trimmedBody = body.trim();
    if (trimmedBody.length > 10000) {
      throw ArgumentError('Messages must be at most 10000 characters');
    }
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

    return dto;
  }

  @override
  Stream<ChatMessageDto> subscribeToMessages(String conversationId) {
    late final RealtimeChannel channel;
    final controller = StreamController<ChatMessageDto>();

    channel = _supabase
        .channel('chat:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(ChatMessageDto.fromJson(payload.newRecord));
            }
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
    final channel = _supabase.channel(
      'chat-typing:$conversationId',
      opts: const RealtimeChannelConfig(private: true),
    );
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
        .channel(
          'chat-typing:$conversationId',
          opts: const RealtimeChannelConfig(private: true),
        )
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

            if (controller.isClosed) {
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
}
