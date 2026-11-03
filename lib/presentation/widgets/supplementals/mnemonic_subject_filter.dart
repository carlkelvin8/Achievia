import 'package:achievia/core/utils/mnemonic_filters.dart';
import 'package:flutter/material.dart';

/// Button beside the search field that opens the "Filter by Subject" dialog.
/// Styled like the search field; it is highlighted while a subject filter is
/// active.
class SubjectFilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const SubjectFilterButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Filter by subject',
      child: Material(
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: const ValueKey('subject-filter-button'),
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.filter_list,
              size: 22,
              color: active
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the dialog. Returns the chosen subject ids (empty = All Subjects), or
/// null when the dialog was dismissed without applying.
Future<Set<int>?> showSubjectFilterDialog(
  BuildContext context, {
  required List<SupplementalSubject> subjects,
  required Set<int> selected,
}) {
  return showDialog<Set<int>>(
    context: context,
    builder: (context) =>
        _SubjectFilterDialog(subjects: subjects, initial: selected),
  );
}

class _SubjectFilterDialog extends StatefulWidget {
  final List<SupplementalSubject> subjects;
  final Set<int> initial;

  const _SubjectFilterDialog({required this.subjects, required this.initial});

  @override
  State<_SubjectFilterDialog> createState() => _SubjectFilterDialogState();
}

class _SubjectFilterDialogState extends State<_SubjectFilterDialog> {
  late Set<int> _selected = {...widget.initial};

  bool get _allSubjects => _selected.isEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Subject'),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            CheckboxListTile(
              key: const ValueKey('subject-filter-all'),
              value: _allSubjects,
              title: const Text('All Subjects'),
              controlAffinity: ListTileControlAffinity.leading,
              // All Subjects is the empty selection: choosing it clears the
              // individual subjects, and picking a subject leaves it.
              onChanged: (_) => setState(() => _selected = {}),
            ),
            const Divider(height: 1),
            for (final subject in widget.subjects)
              CheckboxListTile(
                key: ValueKey('subject-filter-${subject.id}'),
                value: _selected.contains(subject.id),
                title: Text(subject.title),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) => setState(() {
                  final next = {..._selected};
                  if (checked == true) {
                    next.add(subject.id);
                  } else {
                    next.remove(subject.id);
                  }
                  _selected = next;
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('subject-filter-clear'),
          onPressed: () => setState(() => _selected = {}),
          child: const Text('Clear'),
        ),
        FilledButton(
          key: const ValueKey('subject-filter-apply'),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Apply Filter'),
        ),
      ],
    );
  }
}

/// Shown instead of the mnemonic grid when a search and/or subject filter
/// leaves nothing. The search field and filter button stay above it.
class MnemonicEmptyState extends StatelessWidget {
  final bool searching;
  final bool filtering;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilter;

  const MnemonicEmptyState({
    super.key,
    required this.searching,
    required this.filtering,
    required this.onClearSearch,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String message;
    if (searching && filtering) {
      message =
          'No mnemonics match your search in the selected subjects. Try a '
          'different search or choose more subjects.';
    } else if (filtering) {
      message =
          'No mnemonics for the selected subjects yet. Choose another '
          'subject or clear the filter.';
    } else {
      message = 'No mnemonics match your search. Try a different keyword.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        key: const ValueKey('mnemonic-empty'),
        children: [
          Icon(
            Icons.search_off,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (searching)
                TextButton(
                  key: const ValueKey('mnemonic-empty-clear-search'),
                  onPressed: onClearSearch,
                  child: const Text('Clear search'),
                ),
              if (filtering)
                TextButton(
                  key: const ValueKey('mnemonic-empty-clear-filter'),
                  onPressed: onClearFilter,
                  child: const Text('Show all subjects'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
