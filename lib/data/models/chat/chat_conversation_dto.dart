import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';

class ChatConversationDto {
  final String id;
  final String type;
  final String? title;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? latestMessage;

  /// Picture of the other person in a direct conversation.
  final String? profileImage;

  const ChatConversationDto({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.createdBy,
    this.lastMessageAt,
    this.latestMessage,
    this.profileImage,
  });

  factory ChatConversationDto.fromJson(Map<String, dynamic> json) {
    return ChatConversationDto(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      latestMessage: json['latest_message'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }

  ChatConversationEntity toEntity() {
    return ChatConversationEntity(
      id: id,
      type: _conversationTypeFromString(type),
      title: title?.trim().isNotEmpty == true ? title! : 'Conversation',
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessageAt: lastMessageAt,
      latestMessage: latestMessage,
      profileImage: profileImage?.trim().isNotEmpty == true
          ? profileImage
          : null,
    );
  }

  ChatConversationType _conversationTypeFromString(String type) {
    return switch (type) {
      'direct' => ChatConversationType.direct,
      'group' => ChatConversationType.group,
      _ => throw ArgumentError.value(
        type,
        'type',
        'Unsupported chat conversation type',
      ),
    };
  }
}
