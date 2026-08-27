import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/about/about_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/cards/author_card.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/empty_state_widget.dart';

class AuthorContentScreen extends ConsumerWidget {
  const AuthorContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsAsync = ref.watch(authorItemsProvider);

    return Scaffold(
      body: authorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load authors: $error')),
        data: (authors) => authors.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.people_outline,
                title: 'No authors yet',
                subtitle: 'Study content contributors will appear here.',
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: level2,
                  child: Column(
                    children: [
                      ...authors.asMap().entries.map((entry) {
                        final index = entry.key;
                        final author = entry.value;
                        return Column(
                          children: [
                            if (index > 0) const SizedBox(height: 16),
                            AuthorCard(
                              imageUrl: author.image,
                              name: author.name,
                              university: author.university,
                              achievement: author.achievement,
                              greeting: author.greeting,
                              message: author.message,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
