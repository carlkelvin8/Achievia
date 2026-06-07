import 'package:achievia/domain/entities/widgets/pdf_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_tile_decoration.dart';
import 'package:flutter/material.dart';

class ProcedureGrid extends StatelessWidget {
  final List<PdfEntity> items;

  const ProcedureGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptySupplementalSection();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return _ProcedureTile(title: items[index].text);
      },
    );
  }
}

class _ProcedureTile extends StatelessWidget {
  final String title;

  const _ProcedureTile({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: theme.colorScheme.primary,
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
