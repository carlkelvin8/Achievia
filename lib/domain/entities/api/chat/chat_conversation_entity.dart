enum ChatConversationType { group, direct }

class ChatConversationEntity {
  final String id;
  final ChatConversationType type;
  final String title;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? latestMessage;

  const ChatConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastMessageAt,
    this.latestMessage,
  });
}
