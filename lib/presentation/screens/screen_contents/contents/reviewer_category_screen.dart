import 'package:achievia/presentation/screens/screen_contents/contents/mother_notes_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/questions_content_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/supplementals_content_screen.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';

class MotherNotesScreen extends StatelessWidget {
  const MotherNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReviewerCategoryScreen(
      title: 'Mother Notes',
      child: MotherNotesContent(),
    );
  }
}

class QuestionBankScreen extends StatelessWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReviewerCategoryScreen(
      title: 'Question Bank',
      child: QuestionsContentScreen(),
    );
  }
}

class SupplementalsScreen extends StatelessWidget {
  const SupplementalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReviewerCategoryScreen(
      title: 'Supplementals',
      child: SupplementalsContentScreen(),
    );
  }
}

class _ReviewerCategoryScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReviewerCategoryScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: title,
        centerTitle: true,
        titleStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: child,
    );
  }
}
