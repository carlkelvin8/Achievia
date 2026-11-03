import 'dart:async';

import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_typing_event_entity.dart';
import 'package:achievia/domain/use_cases/chat/chat_use_case.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatUseCase implements ChatUseCase {
  final typing = StreamController<ChatTypingEventEntity>.broadcast();

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async =>
      const [];

  @override
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) =>
      const Stream.empty();

  @override
  Stream<ChatTypingEventEntity> subscribeToTypingIndicators(
    String conversationId,
  ) => typing.stream;

  @override
  Future<void> sendTypingIndicator(
    String conversationId,
    bool isTyping,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('a remote typing flag expires when no update arrives', (
    tester,
  ) async {
    final fake = _FakeChatUseCase();
    addTearDown(fake.typing.close);
    final container = ProviderContainer(
      overrides: [chatUseCaseProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final provider = chatThreadProvider('c1');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await tester.pump();
    fake.typing.add(
      const ChatTypingEventEntity(profileId: 'u2', isTyping: true),
    );
    await tester.pump();
    expect(container.read(provider).isAnyoneTyping, isTrue);

    await tester.pump(const Duration(seconds: 7));
    expect(container.read(provider).isAnyoneTyping, isFalse);
  });

  testWidgets('a fresh typing update keeps the flag alive', (tester) async {
    final fake = _FakeChatUseCase();
    addTearDown(fake.typing.close);
    final container = ProviderContainer(
      overrides: [chatUseCaseProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final provider = chatThreadProvider('c1');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await tester.pump();
    const typing = ChatTypingEventEntity(profileId: 'u2', isTyping: true);
    fake.typing.add(typing);
    await tester.pump(const Duration(seconds: 4));
    fake.typing.add(typing);
    await tester.pump(const Duration(seconds: 4));

    expect(container.read(provider).isAnyoneTyping, isTrue);

    // Let the expiry timer fire so no timer is left pending.
    await tester.pump(const Duration(seconds: 7));
  });
}
