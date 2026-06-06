import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/list_items/message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _openingProfileId;

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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search people or conversations',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close),
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
            Expanded(
              child: _isSearchingPeople
                  ? _PeopleSearchResults(
                      query: _searchQuery,
                      openingProfileId: _openingProfileId,
                      onOpenPerson: _openDirectChat,
                    )
                  : Column(
                      children: [
                        TabBar(
                          controller: controller,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor:
                              theme.colorScheme.onSurfaceVariant,
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
                                        conversation.type ==
                                        ChatConversationType.group,
                                  )
                                  .toList();
                              final directConversations = conversations
                                  .where(
                                    (conversation) =>
                                        conversation.type ==
                                        ChatConversationType.direct,
                                  )
                                  .toList();

                              return TabBarView(
                                controller: controller,
                                children: [
                                  MessageListItem(conversations: conversations),
                                  MessageListItem(
                                    conversations: groupConversations,
                                  ),
                                  MessageListItem(
                                    conversations: directConversations,
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stackTrace) => _MessagesErrorState(
                              message: error.toString(),
                              onRetry: () =>
                                  ref.invalidate(chatConversationsProvider),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isSearchingPeople => _searchQuery.trim().length >= 2;

  Future<void> _openDirectChat(ChatPersonEntity person) async {
    if (_openingProfileId != null) {
      return;
    }

    setState(() {
      _openingProfileId = person.id;
    });

    try {
      final conversation = await ref
          .read(chatUseCaseProvider)
          .startDirectConversation(person.id);
      ref.invalidate(chatConversationsProvider);

      if (!mounted) {
        return;
      }

      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });
      context.push(RouteConstants.chatThread, extra: conversation);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open chat: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _openingProfileId = null;
        });
      }
    }
  }
}

class _PeopleSearchResults extends ConsumerWidget {
  final String query;
  final String? openingProfileId;
  final ValueChanged<ChatPersonEntity> onOpenPerson;

  const _PeopleSearchResults({
    required this.query,
    required this.openingProfileId,
    required this.onOpenPerson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(chatPeopleSearchProvider(query));

    return resultsAsync.when(
      data: (people) {
        if (people.isEmpty) {
          return const _PeopleSearchEmptyState();
        }

        return ListView.separated(
          itemCount: people.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final person = people[index];
            final isOpening = person.id == openingProfileId;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: person.profileImage == null
                    ? null
                    : NetworkImage(person.profileImage!),
                child: person.profileImage == null
                    ? Text(_initialsFor(person.displayName))
                    : null,
              ),
              title: Text(person.displayName),
              subtitle: Text(_subtitleFor(person)),
              trailing: isOpening
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              onTap: isOpening ? null : () => onOpenPerson(person),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _MessagesErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(chatPeopleSearchProvider(query)),
      ),
    );
  }

  String _initialsFor(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String _subtitleFor(ChatPersonEntity person) {
    final username = person.username;
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    return person.email ?? 'Tap to start a chat';
  }
}

class _PeopleSearchEmptyState extends StatelessWidget {
  const _PeopleSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No people found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by name, username, or email.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
