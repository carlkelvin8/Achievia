import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/list_items/message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabNotifier = ref.read(tabProvider.notifier);
    final controller = ref.watch(tabProvider);
    final conversationsAsync = ref.watch(chatConversationsProvider);

    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabNotifier.createController(this, 3);
      });
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            TabBar(
              controller: controller,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Groups'),
                Tab(text: 'Personal Message'),
              ],
            ),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  final groupConversations = conversations
                      .where(
                        (conversation) =>
                            conversation.type == ChatConversationType.group,
                      )
                      .toList();
                  final directConversations = conversations
                      .where(
                        (conversation) =>
                            conversation.type == ChatConversationType.direct,
                      )
                      .toList();

                  return TabBarView(
                    controller: controller,
                    children: [
                      MessageListItem(conversations: conversations),
                      MessageListItem(conversations: groupConversations),
                      MessageListItem(conversations: directConversations),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _MessagesErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(chatConversationsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessagesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load conversations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
