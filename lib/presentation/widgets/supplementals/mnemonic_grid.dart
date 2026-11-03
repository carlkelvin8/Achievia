import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_tile_decoration.dart';
import 'package:flutter/material.dart';
import 'supplemental_detail_screen.dart';

class MnemonicGrid extends StatefulWidget {
  final List<NotesEntity> items;

  const MnemonicGrid({super.key, required this.items});

  @override
  State<MnemonicGrid> createState() => _MnemonicGridState();
}

class _MnemonicGridState extends State<MnemonicGrid> {
  /// How many pictures are fetched ahead of a tap; the rest load on tap.
  static const _prefetchCount = 6;

  List<NotesEntity> get items => widget.items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final item in items.take(_prefetchCount)) {
      SupplementalDetailScreen.prefetchImage(context, item.image);
    }
  }

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
        return _MnemonicTile(item: items[index]);
      },
    );
  }
}

class _MnemonicTile extends StatelessWidget {
  final NotesEntity item;

  const _MnemonicTile({required this.item});

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
            title: item.title,
            content: item.content,
            imageUrl: item.image,
            fileUrl: item.fileUrl,
            isMnemonic: true,
            // The picture is shown in the page itself; no extra button.
            hideOpenFileForInlineImage: true,
          ),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InlineHtmlText(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
