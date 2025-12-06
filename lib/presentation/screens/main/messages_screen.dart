import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/list_items/message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabNotifier = ref.read(tabProvider.notifier);
    final controller = ref.watch(tabProvider);
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
            // Search bar
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
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // Tabs
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

            // Messages list
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                  // All messages
                  MessageListItem(messages: messages),
                  // Groups only
                  MessageListItem(messages: messages.where((m) => m['isGroup']).toList()),
                  // Personal messages only
                  MessageListItem(messages: messages.where((m) => !m['isGroup']).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
