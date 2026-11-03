import 'package:achievia/core/constants/subject_icons.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class QuestionBankSubjectsScreen extends ConsumerWidget {
  const QuestionBankSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(questionBankSubjectsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Question Bank', centerTitle: true),
      body: subjects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => QuestionBankStatusView(
          icon: error is QuestionBankCourseMissingException
              ? Icons.school_outlined
              : Icons.cloud_off_outlined,
          message: error is QuestionBankCourseMissingException
              ? 'Your profile needs a course assignment before you can practice.'
              : 'We could not load your subjects. Please try again.',
          actionLabel: error is QuestionBankCourseMissingException
              ? null
              : 'Retry',
          onAction: error is QuestionBankCourseMissingException
              ? null
              : () => ref.invalidate(questionBankSubjectsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const QuestionBankStatusView(
              icon: Icons.menu_book_outlined,
              message:
                  'No Question Bank subjects are available for your course yet.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(questionBankSubjectsProvider);
              ref.invalidate(recentQuestionBankAttemptsProvider);
              await ref.read(questionBankSubjectsProvider.future);
            },
            child: _SubjectList(subjects: items),
          );
        },
      ),
    );
  }
}

class _SubjectList extends ConsumerWidget {
  final List<QuestionBankSubject> subjects;

  const _SubjectList({required this.subjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttempts = ref.watch(recentQuestionBankAttemptsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          'Choose a subject from your registered course.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 18),
        for (final subject in subjects) ...[
          SizedBox(
            height: 104,
            child: ReviewerCategoryCard(
              icon: Icons.science_outlined,
              iconAsset: subjectIconAsset(subject.title),
              title: subject.title,
              subtitle: normalizeQuestionBankOptionalText(subject.description),
              onTap: () => context.push(
                RouteConstants.questionBankTopics,
                extra: QuestionBankTopicArgs(subject),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        recentAttempts.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (attempts) {
            if (attempts.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Recent Practice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final attempt in attempts)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(attempt.topicTitle),
                      subtitle: Text(
                        '${attempt.subjectTitle} • ${DateFormat.yMMMd().format(attempt.completedAt)}',
                      ),
                      trailing: Text(
                        '${attempt.correctAnswers}/${attempt.totalQuestions}\n${attempt.score.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
