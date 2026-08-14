import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuestionBankTopicsScreen extends ConsumerWidget {
  final QuestionBankSubject subject;

  const QuestionBankTopicsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(questionBankTopicsProvider(subject.id));

    return Scaffold(
      appBar: CustomAppBar(title: subject.title, centerTitle: true),
      body: topics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => QuestionBankStatusView(
          icon: Icons.cloud_off_outlined,
          message: 'We could not load the topics for this subject.',
          actionLabel: 'Retry',
          onAction: () =>
              ref.invalidate(questionBankTopicsProvider(subject.id)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const QuestionBankStatusView(
              icon: Icons.quiz_outlined,
              message: 'No practice topics are available for this subject yet.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(questionBankTopicsProvider(subject.id));
              await ref.read(questionBankTopicsProvider(subject.id).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final topic = items[index];
                return SizedBox(
                  height: 104,
                  child: ReviewerCategoryCard(
                    icon: Icons.quiz_outlined,
                    title: topic.title,
                    subtitle: 'Practice up to 20 questions',
                    onTap: () => context.push(
                      RouteConstants.questionBankPractice,
                      extra: QuestionBankPracticeArgs(
                        QuestionBankSelection(subject: subject, topic: topic),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
