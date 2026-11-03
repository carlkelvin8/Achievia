import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/questions/mock_board_review.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/builders/summary_listview.dart';
import 'package:achievia/presentation/widgets/cards/questions_content_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every question of a Mock Board with the student's answer, the correct one
/// and the rationale. With [attemptNo] it shows that attempt (also when it is
/// reopened later from Profile); without, the board in memory.
class SummaryScreen extends ConsumerStatefulWidget {
  final int? attemptNo;

  const SummaryScreen({super.key, this.attemptNo});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  Widget _list(List<QuizItemEntity> board, Map<String, int> selectedAnswers) {
    final flattened = [
      for (final quiz in board)
        for (final question in quiz.questions)
          (answerKey: '${quiz.id}:${question.id}', question: question),
    ];

    return SummaryListview(
      itemCount: flattened.length,
      itemBuilder: (context, index) {
        final item = flattened[index];
        return QuestionsContentList(
          questionText: '${index + 1}. ${item.question.questionText}',
          imagePath: item.question.imagePath,
          rationale: item.question.rationale,
          choices: item.question.choices,
          selectedIndex: selectedAnswers[item.answerKey],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attemptNo = widget.attemptNo;
    final Widget body;
    if (attemptNo != null && attemptNo > 0) {
      body = ref
          .watch(mockBoardReviewProvider(attemptNo))
          .when(
            data: (review) => review == null
                ? const _Unavailable()
                : _list(review.board, review.selectedAnswers),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(userFacingError(error))),
          );
    } else {
      final selectedAnswers = ref.watch(examSelectedAnswersProvider);
      body = ref
          .watch(getGeneratedQuestions)
          .when(
            data: (board) => _list(board, selectedAnswers),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(userFacingError(error))),
          );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: body,
    );
  }
}

/// An attempt whose answers are not on this device (taken on another phone,
/// or before summaries were kept).
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'The question-by-question summary of this attempt is not available '
          'on this device. Your scores are still saved in your results.',
          key: const ValueKey('mock-summary-unavailable'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
