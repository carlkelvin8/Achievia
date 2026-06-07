import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_tile_decoration.dart';
import 'package:flutter/material.dart';

class AbbreviationList extends StatelessWidget {
  final List<MedicalAbbreviation> items;

  const AbbreviationList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptySupplementalSection();

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AbbreviationTile(
            item: items[index],
            trailingIcon: index.isEven ? Icons.bookmark_border : Icons.favorite,
          ),
          if (index < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AbbreviationTile extends StatelessWidget {
  final MedicalAbbreviation item;
  final IconData trailingIcon;

  const _AbbreviationTile({required this.item, required this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: supplementalTileDecoration(theme),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: theme.colorScheme.primary,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.abbreviation,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.expansion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(trailingIcon, color: theme.colorScheme.primary, size: 22),
        ],
      ),
    );
  }
}
