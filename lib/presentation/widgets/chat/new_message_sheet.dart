import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/chat/chat_person_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing every student with an account, so nobody has to guess
/// whether a classmate has signed up. Pops the tapped [ChatPersonEntity].
class NewMessageSheet extends ConsumerStatefulWidget {
  const NewMessageSheet({super.key});

  @override
  ConsumerState<NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends ConsumerState<NewMessageSheet> {
  static const _pageSize = 50;

  final _people = <ChatPersonEntity>[];
  final _scrollController = ScrollController();
  final _filterController = TextEditingController();
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(chatUseCaseProvider)
          .listPeople(limit: _pageSize, offset: _people.length);
      if (!mounted) return;
      setState(() {
        _people.addAll(page);
        _hasMore = page.length == _pageSize;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  List<ChatPersonEntity> get _visiblePeople {
    final query = _filter.trim().toLowerCase();
    if (query.isEmpty) return _people;
    return _people
        .where(
          (person) =>
              person.displayName.toLowerCase().contains(query) ||
              (person.username ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _visiblePeople;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, sheetController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'New message',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _filterController,
                onChanged: (value) => setState(() => _filter = value),
                decoration: InputDecoration(
                  hintText: 'Filter students',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildList(theme, visible, sheetController)),
          ],
        );
      },
    );
  }

  Widget _buildList(
    ThemeData theme,
    List<ChatPersonEntity> visible,
    ScrollController sheetController,
  ) {
    if (_people.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_people.isEmpty && _error != null) {
      return _SheetMessage(
        text: userFacingError(_error!),
        actionLabel: 'Retry',
        onAction: _loadMore,
      );
    }
    if (_people.isEmpty) {
      return const _SheetMessage(text: 'No other students have signed up yet.');
    }

    return ListView.builder(
      controller: sheetController,
      itemCount: visible.length + 1,
      itemBuilder: (context, index) {
        if (index == visible.length) return _buildFooter(theme, visible);
        final person = visible[index];
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
          subtitle: person.username == null
              ? null
              : Text('@${person.username}'),
          trailing: const Icon(Icons.chat_bubble_outline),
          onTap: () => Navigator.of(context).pop(person),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, List<ChatPersonEntity> visible) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return TextButton(
        onPressed: _loadMore,
        child: const Text('Could not load more. Tap to retry'),
      );
    }
    if (_filter.trim().isNotEmpty && visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _hasMore
              ? 'No match yet. Scroll or keep loading to see more students.'
              : 'No student with that name.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  String _initialsFor(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part.characters.first.toUpperCase()).join();
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
