class ChatPersonEntity {
  final String id;
  final String displayName;
  final String? username;
  final String? email;
  final String? profileImage;

  const ChatPersonEntity({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.profileImage,
  });
}
