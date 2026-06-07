import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_category_card.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReviewersScreen extends StatelessWidget {
  const ReviewersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 22.0;
            const topPadding = 18.0;
            const bottomPadding = 28.0;
            const cardGap = 14.0;
            final compact = constraints.maxHeight < 590;

            const header = ReviewerScreenHeader();
            final cards = [
              ReviewerCategoryCard(
                icon: Icons.menu_book_outlined,
                title: 'Mother Notes',
                subtitle: 'Study materials and notes.',
                onTap: () => context.push(RouteConstants.motherNotes),
              ),
              ReviewerCategoryCard(
                icon: Icons.help_outline,
                title: 'Question Bank',
                subtitle: 'Practice questions and mock exams.',
                onTap: () => context.push(RouteConstants.questionBank),
              ),
              ReviewerCategoryCard(
                icon: Icons.emoji_events_outlined,
                title: 'Supplementals',
                subtitle: 'Mnemonics, abbreviations,\nprocedures.',
                onTap: () => context.push(RouteConstants.supplementals),
              ),
            ];

            if (compact) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                children: [
                  header,
                  const SizedBox(height: 22),
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: cardGap),
                    SizedBox(height: 164, child: cards[i]),
                  ],
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 22),
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: cardGap),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
