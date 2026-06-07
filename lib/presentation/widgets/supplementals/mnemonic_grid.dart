import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_tile_decoration.dart';
import 'package:flutter/material.dart';

class MnemonicGrid extends StatelessWidget {
  final List<NotesEntity> items;

  const MnemonicGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptySupplementalSection();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final icon = _mnemonicIcon(index);
        return _MnemonicTile(title: item.title, icon: icon);
      },
    );
  }
}

IconData _mnemonicIcon(int index) {
  const icons = [
    Icons.dashboard_customize,
    Icons.water_drop,
    Icons.coronavirus,
    Icons.bug_report,
  ];
  return icons[index % icons.length];
}

class _MnemonicTile extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MnemonicTile({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: supplementalTileDecoration(theme),
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;

  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 21),
    );
  }
}
