import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_tile_decoration.dart';
import 'package:flutter/material.dart';
import 'supplemental_detail_screen.dart';

class AbbreviationList extends StatelessWidget {
  final List<MedicalAbbreviation> items;

  const AbbreviationList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptySupplementalSection();

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AbbreviationTile(item: items[index]),
          if (index < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AbbreviationTile extends StatelessWidget {
  final MedicalAbbreviation item;

  const _AbbreviationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: supplementalTileDecoration(theme),
        child: InkWell(
          onTap: () => SupplementalDetailScreen.open(
            context,
            title: item.abbreviation,
            content: item.expansion,
            description: item.description,
          ),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: theme.colorScheme.primary,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InlineHtmlText(
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
                    child: InlineHtmlText(
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
                  // One simple arrow: the item can be opened.
                  Icon(
                    Icons.chevron_right,
                    key: const ValueKey('abbreviation-chevron'),
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
