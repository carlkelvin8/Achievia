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

  /// Picture of the other person in a direct conversation, when they have one.
  final String? profileImage;

  const ChatConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastMessageAt,
    this.latestMessage,
    this.profileImage,
  });
}
