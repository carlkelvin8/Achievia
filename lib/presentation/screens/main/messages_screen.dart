import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/chat/messages_provider.dart';
import 'package:achievia/presentation/widgets/chat/message_filter_chips.dart';
import 'package:achievia/presentation/widgets/chat/message_search_bar.dart';
import 'package:achievia/presentation/widgets/list_items/message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messageState = ref.watch(messagesProvider);
    final messageNotifier = ref.read(messagesProvider.notifier);
    final conversationsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  MessageSearchBar(
                    controller: messageNotifier.searchController,
                    query: messageState.searchQuery,
                    onChanged: messageNotifier.setSearchQuery,
                    onClear: messageNotifier.clearSearch,
                  ),
                  if (_isSearchingPeople(messageState.searchQuery)) ...[
                    const SizedBox(height: 8),
                    _PeopleAutocompletePanel(
                      query: messageState.searchQuery,
                      openingProfileId: messageState.openingProfileId,
                      onOpenPerson: _openDirectChat,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  MessageFilterChips(
                    activeFilter: messageState.filter,
                    onSelected: messageNotifier.setFilter,
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.16),
                  ),
                  Expanded(
                    child: conversationsAsync.when(
                      data: (conversations) {
                        return MessageListItem(
                          conversations: messageState.filteredConversations(
                            conversations,
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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

  bool _isSearchingPeople(String query) =>
      isChatPeopleAutocompleteActive(query);

  Future<void> _openDirectChat(ChatPersonEntity person) async {
    final messageNotifier = ref.read(messagesProvider.notifier);
    final messageState = ref.read(messagesProvider);
    if (messageState.openingProfileId != null) {
      return;
    }

    messageNotifier.setOpeningProfileId(person.id);

    try {
      final conversation = await ref
          .read(chatUseCaseProvider)
          .startDirectConversation(person.id);
      ref.invalidate(chatConversationsProvider);

      if (!mounted) {
        return;
      }

      messageNotifier.clearSearch();
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
        messageNotifier.setOpeningProfileId(null);
      }
    }
  }
}

class _PeopleAutocompletePanel extends ConsumerWidget {
  final String query;
  final String? openingProfileId;
  final ValueChanged<ChatPersonEntity> onOpenPerson;

  const _PeopleAutocompletePanel({
    required this.query,
    required this.openingProfileId,
    required this.onOpenPerson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resultsAsync = ref.watch(chatPeopleSearchProvider(query));

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: resultsAsync.when(
          data: (people) {
            if (people.isEmpty) {
              return const _PeopleAutocompleteEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: people.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final person = people[index];
                final isOpening = person.id == openingProfileId;

                return ListTile(
                  dense: true,
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
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  onTap: isOpening ? null : () => onOpenPerson(person),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to search people',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(chatPeopleSearchProvider(query)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
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

class _PeopleAutocompleteEmptyState extends StatelessWidget {
  const _PeopleAutocompleteEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.person_search, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No people found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
