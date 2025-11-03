import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';

class GridBadges extends StatelessWidget {
  final String text;
  final String text2;
  const GridBadges({super.key, required this.text, required this.text2});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ReusableButton(
            title: 'Mock Boards',
            onPressed: () {},
            width: 200,
            height: 30,
            backgroundColor: theme.colorScheme.primary,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list2.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1, // ensures all squares
          ),
          itemBuilder: (context, index) =>
              PdfBadge(tabType: 'questions', text: list2[index].text),
        ),

        const SizedBox(height: 24), // spacing between first and second grids
        // ---------- SECOND DAY ----------
        Text(
          text2,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: list3.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) =>
              PdfBadge(tabType: 'questions', text: list3[index].text),
        ),
      ],
    );
  }
}
