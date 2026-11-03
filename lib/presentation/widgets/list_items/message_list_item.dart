import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/time_ago_formatter.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessageListItem extends StatelessWidget {
  final List<ChatConversationEntity> conversations;

  const MessageListItem({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final latestMessage = conversation.latestMessage?.trim();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: conversation.profileImage == null
                ? null
                : NetworkImage(conversation.profileImage!),
            onBackgroundImageError: conversation.profileImage == null
                ? null
                : (_, _) {},
            child: conversation.profileImage == null
                ? Text(
                    _avatarInitial(conversation.title),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          title: Text(
            conversation.title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            latestMessage == null || latestMessage.isEmpty
                ? 'No messages yet'
                : latestMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: conversation.lastMessageAt == null
              ? null
              : Text(
                  TimeAgoFormatter.format(conversation.lastMessageAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
          onTap: () {
            context.push(RouteConstants.chatThread, extra: conversation);
          },
        );
      },
    );
  }

  String _avatarInitial(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return '?';
    }

    return trimmedTitle.characters.first.toUpperCase();
  }
}
