// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GridBadges extends ConsumerWidget {
  final String token;
  final String id;
  final String title;
  const GridBadges({
    super.key,
    required this.token,
    required this.id,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questionsAsync = ref.watch(getQuestionsProviderState((token: token, id:id)));

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No questions available'));
        }

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
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => 
                  PdfBadge(tabType: 'questions', text: questions[index].title),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
