import 'package:flutter/material.dart';

class MessageListItem extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const MessageListItem({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              message['name'][0],
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          title: Text(
            message['name'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            message['message'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // Handle message tap
          },
        );
      },
    );;
  }
}