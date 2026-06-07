import 'package:achievia/presentation/provider/chat/messages_provider.dart';
import 'package:flutter/material.dart';

class MessageFilterChips extends StatelessWidget {
  final ChatConversationFilter activeFilter;
  final ValueChanged<ChatConversationFilter> onSelected;

  const MessageFilterChips({
    super.key,
    required this.activeFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _MessageFilterChip(
              label: 'All',
              selected: activeFilter == ChatConversationFilter.all,
              onTap: () => onSelected(ChatConversationFilter.all),
            ),
            _MessageFilterChip(
              label: 'Groups',
              selected: activeFilter == ChatConversationFilter.groups,
              onTap: () => onSelected(ChatConversationFilter.groups),
            ),
            _MessageFilterChip(
              label: 'Personal Message',
              selected: activeFilter == ChatConversationFilter.direct,
              onTap: () => onSelected(ChatConversationFilter.direct),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MessageFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
