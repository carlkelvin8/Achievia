import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/widgets/chat/chat_bubble.dart';
import 'package:achievia/presentation/widgets/chat/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatThreadScreen extends ConsumerWidget {
  final ChatConversationEntity conversation;

  const ChatThreadScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatThreadProvider(conversation.id);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text(conversation.title)),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: notifier.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: _MessageList(
              isLoading: state.isLoading,
              messages: state.messages,
              currentUserId: currentUserId,
            ),
          ),
          if (state.isAnyoneTyping) const _TypingIndicator(),
          ChatComposer(
            controller: notifier.composerController,
            isSending: state.isSending,
            onSend: notifier.send,
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          'Someone is typing...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final bool isLoading;
  final List<ChatMessageEntity> messages;
  final String? currentUserId;

  const _MessageList({
    required this.isLoading,
    required this.messages,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];

        return ChatBubble(
          message: message,
          isMine: message.senderId == currentUserId,
        );
      },
    );
  }
}
