import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';

class ChatPersonDto {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? profileImage;

  const ChatPersonDto({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.profileImage,
  });

  factory ChatPersonDto.fromJson(Map<String, dynamic> json) {
    return ChatPersonDto(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }

  ChatPersonEntity toEntity() {
    return ChatPersonEntity(
      id: id,
      displayName: _displayName(),
      username: _blankToNull(username),
      email: _blankToNull(email),
      profileImage: _blankToNull(profileImage),
    );
  }

  String _displayName() {
    final fullName = [
      _blankToNull(firstName),
      _blankToNull(lastName),
    ].whereType<String>().join(' ');

    return _blankToNull(fullName) ??
        _blankToNull(username) ??
        _blankToNull(email) ??
        'Achievia user';
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
