import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:achievia/data/models/chat/chat_person_dto.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps chat conversation row to entity', () {
    final dto = ChatConversationDto.fromJson({
      'id': 'conversation-1',
      'type': 'group',
      'title': 'Achievian RMT',
      'created_by': 'user-1',
      'created_at': '2026-06-05T01:00:00.000Z',
      'updated_at': '2026-06-05T01:05:00.000Z',
      'last_message_at': '2026-06-05T01:06:00.000Z',
      'latest_message': 'Hello',
    });

    final entity = dto.toEntity();

    expect(entity.id, 'conversation-1');
    expect(entity.type, ChatConversationType.group);
    expect(entity.title, 'Achievian RMT');
    expect(entity.latestMessage, 'Hello');
  });

  test('maps chat message row to entity', () {
    final dto = ChatMessageDto.fromJson({
      'id': 'message-1',
      'conversation_id': 'conversation-1',
      'sender_id': 'user-1',
      'body': 'Hello',
      'created_at': '2026-06-05T01:00:00.000Z',
    });

    final entity = dto.toEntity();

    expect(entity.id, 'message-1');
    expect(entity.conversationId, 'conversation-1');
    expect(entity.senderId, 'user-1');
    expect(entity.body, 'Hello');
  });

  test('throws for unsupported chat conversation type', () {
    final dto = ChatConversationDto.fromJson({
      'id': 'conversation-1',
      'type': 'unsupported',
      'title': 'Achievian RMT',
      'created_by': 'user-1',
      'created_at': '2026-06-05T01:00:00.000Z',
      'updated_at': '2026-06-05T01:05:00.000Z',
      'last_message_at': null,
      'latest_message': null,
    });

    expect(
      dto.toEntity,
      throwsA(
        isA<ArgumentError>()
            .having(
              (error) => error.invalidValue,
              'invalidValue',
              'unsupported',
            )
            .having((error) => error.name, 'name', 'type')
            .having(
              (error) => error.message,
              'message',
              'Unsupported chat conversation type',
            ),
      ),
    );
  });

  test('maps chat person search row to entity', () {
    final dto = ChatPersonDto.fromJson({
      'id': 'user-2',
      'first_name': 'Juan',
      'last_name': 'Dela Cruz',
      'username': 'juan',
      'email': 'juan@example.com',
      'profile_image': 'https://example.com/avatar.png',
    });

    final entity = dto.toEntity();

    expect(entity.id, 'user-2');
    expect(entity.displayName, 'Juan Dela Cruz');
    expect(entity.username, 'juan');
    expect(entity.email, 'juan@example.com');
    expect(entity.profileImage, 'https://example.com/avatar.png');
  });

  test('chat person display name falls back to username then email', () {
    final usernameDto = ChatPersonDto.fromJson({
      'id': 'user-2',
      'first_name': null,
      'last_name': null,
      'username': 'juan',
      'email': 'juan@example.com',
      'profile_image': null,
    });
    final emailDto = ChatPersonDto.fromJson({
      'id': 'user-3',
      'first_name': '',
      'last_name': '',
      'username': '',
      'email': 'maria@example.com',
      'profile_image': null,
    });

    expect(usernameDto.toEntity().displayName, 'juan');
    expect(emailDto.toEntity().displayName, 'maria@example.com');
  });
}
