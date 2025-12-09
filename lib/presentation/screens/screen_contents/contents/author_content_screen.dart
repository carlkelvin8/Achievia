import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/about/about_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/cards/author_card.dart';

class AuthorContentScreen extends ConsumerWidget {
  const AuthorContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authors = ref.watch(authorItemsProvider);

    return Scaffold(
      body: SingleChildScrollView(
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
    );
  }
}
