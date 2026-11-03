import 'package:achievia/presentation/provider/reviewer/supplementals_provider.dart';
import 'package:flutter/material.dart';

class SupplementalFilterChips extends StatelessWidget {
  final SupplementalFilter activeFilter;
  final ValueChanged<SupplementalFilter> onSelected;

  const SupplementalFilterChips({
    super.key,
    required this.activeFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SupplementalChip(
            label: 'All',
            selected: activeFilter == SupplementalFilter.all,
            onTap: () => onSelected(SupplementalFilter.all),
          ),
          _SupplementalChip(
            label: 'Mnemonics',
            selected: activeFilter == SupplementalFilter.mnemonics,
            onTap: () => onSelected(SupplementalFilter.mnemonics),
          ),
          _SupplementalChip(
            label: 'Abbreviations',
            selected: activeFilter == SupplementalFilter.abbreviations,
            onTap: () => onSelected(SupplementalFilter.abbreviations),
          ),
          _SupplementalChip(
            label: 'Computations',
            selected: activeFilter == SupplementalFilter.procedures,
            onTap: () => onSelected(SupplementalFilter.procedures),
          ),
        ],
      ),
    );
  }
}

class _SupplementalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SupplementalChip({
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
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
