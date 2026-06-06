import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('people search autocomplete activates after two characters', () {
    expect(isChatPeopleAutocompleteActive(''), isFalse);
    expect(isChatPeopleAutocompleteActive(' a '), isFalse);
    expect(isChatPeopleAutocompleteActive('jo'), isTrue);
  });

  test('appendMessage ignores duplicate message ids', () {
    final state = ChatThreadState(
      messages: [
        ChatMessageEntity(
          id: 'm1',
          conversationId: 'c1',
          senderId: 'u1',
          body: 'Hello',
          createdAt: DateTime.utc(2026, 6, 5),
        ),
      ],
    );

    final next = state.appendMessage(
      ChatMessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Hello',
        createdAt: DateTime.utc(2026, 6, 5),
      ),
    );

    expect(next.messages, hasLength(1));
  });

  test('appendMessage ignores broadcast duplicate after sent message', () {
    final sentMessage = ChatMessageEntity(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'u1',
      body: 'Hello',
      createdAt: DateTime.utc(2026, 6, 5),
    );

    final state = const ChatThreadState().appendMessage(sentMessage);
    final next = state.appendMessage(
      ChatMessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Hello',
        createdAt: DateTime.utc(2026, 6, 5),
      ),
    );

    expect(next.messages, hasLength(1));
    expect(next.messages.single.id, sentMessage.id);
  });

  test('typing indicator tracks and removes remote typers', () {
    final typing = const ChatThreadState().applyTypingIndicator(
      profileId: 'user-2',
      isTyping: true,
    );

    expect(typing.isAnyoneTyping, isTrue);
    expect(typing.typingProfileIds, {'user-2'});

    final stopped = typing.applyTypingIndicator(
      profileId: 'user-2',
      isTyping: false,
    );

    expect(stopped.isAnyoneTyping, isFalse);
    expect(stopped.typingProfileIds, isEmpty);
  });
}
