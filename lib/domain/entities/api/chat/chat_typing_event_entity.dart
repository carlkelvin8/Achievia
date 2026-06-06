class ChatTypingEventEntity {
  final String profileId;
  final bool isTyping;

  const ChatTypingEventEntity({
    required this.profileId,
    required this.isTyping,
  });
}
