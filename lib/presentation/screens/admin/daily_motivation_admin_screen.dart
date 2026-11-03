import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Admin-only management of the Daily Motivation pool. The UI gate is only a
/// convenience; the database enforces admin-only writes through RLS.
class DailyMotivationAdminScreen extends ConsumerWidget {
  const DailyMotivationAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(title: 'Daily Motivation'),
      body: isAdmin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Notice('Unable to verify your access.'),
        data: (allowed) =>
            allowed ? const _AdminList() : const _Notice('Admins only.'),
      ),
      floatingActionButton: isAdmin.value == true
          ? FloatingActionButton.extended(
              onPressed: () => showMotivationEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

class _AdminList extends ConsumerWidget {
  const _AdminList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(adminMotivationsProvider);
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load motivations.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  ref.read(adminMotivationsProvider.notifier).reload(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (list) => list.isEmpty
          ? const _Notice('No motivations yet. Tap Add to create one.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MotivationTile(item: list[i]),
            ),
    );
  }
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action,
  String success,
) async {
  try {
    await action();
    if (context.mounted) AppToast.showSuccess(context, success);
  } catch (error) {
    debugPrint('DailyMotivation admin action failed: $error');
    if (context.mounted) {
      AppToast.showError(context, _friendly(error));
    }
  }
}

String _friendly(Object error) {
  if (error is ArgumentError) return error.message.toString();
  final text = error.toString();
  if (text.contains('23505')) return 'That message already exists.';
  if (text.contains('42501') || text.contains('row-level security')) {
    return 'You do not have permission to do that.';
  }
  return 'Something went wrong. Please try again.';
}

class _MotivationTile extends ConsumerWidget {
  const _MotivationTile({required this.item});
  final DailyMotivationEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(adminMotivationsProvider.notifier);
    final created = item.createdAt == null
        ? null
        : DateFormat('MMM d, yyyy').format(item.createdAt!.toLocal());

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.isActive
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${item.displayOrder}'
                    '${created == null ? '' : ' · $created'}'
                    ' · ${item.isActive ? 'Active' : 'Inactive'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Switch(
                  value: item.isActive,
                  onChanged: (value) => _run(
                    context,
                    () => notifier.setActive(item.id, value),
                    value ? 'Activated.' : 'Deactivated.',
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      showMotivationEditor(context, ref, existing: item),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, notifier),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminMotivationsNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete motivation?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _run(context, () => notifier.delete(item.id), 'Deleted.');
    }
  }
}

Future<void> showMotivationEditor(
  BuildContext context,
  WidgetRef ref, {
  DailyMotivationEntity? existing,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MotivationEditor(existing: existing),
  );
}

class _MotivationEditor extends ConsumerStatefulWidget {
  const _MotivationEditor({this.existing});
  final DailyMotivationEntity? existing;

  @override
  ConsumerState<_MotivationEditor> createState() => _MotivationEditorState();
}

class _MotivationEditorState extends ConsumerState<_MotivationEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.existing?.message ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminMotivationsProvider.notifier);
    final existing = widget.existing;
    final message = _controller.text;
    try {
      if (existing == null) {
        await notifier.add(message);
      } else {
        await notifier.edit(existing.id, message);
      }
      if (!mounted) return;
      AppToast.showSuccess(context, existing == null ? 'Added.' : 'Saved.');
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('DailyMotivation save failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.showError(context, _friendly(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add motivation' : 'Edit motivation',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          enabled: !_saving,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write a motivational message',
            counterText: '',
          ),
          validator: DailyMotivationEntity.validateMessage,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
