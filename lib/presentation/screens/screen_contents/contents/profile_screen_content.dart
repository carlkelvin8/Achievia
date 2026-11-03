import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/core/utils/recent_results.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/badges/editable_board_exam_badge.dart';
import 'package:achievia/presentation/widgets/cards/examination_results_card.dart';
import 'package:achievia/presentation/widgets/cards/mantra_card.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:achievia/presentation/widgets/badges/countdown_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreenContent extends ConsumerWidget {
  const ProfileScreenContent({super.key});

  /// Reopens the exact persisted summary by attempt id. The route carries only
  /// the id, so it works with no in-memory exam state. A Mock Board opens its
  /// results overview first; its 600-question Summary is one tap further.
  Future<void> _openSummary(BuildContext context, ExaminationResult result) {
    final mockBoardNo = result.mockBoardAttemptNo;
    if (mockBoardNo != null) {
      return context.push<void>(
        RouteConstants.attemptScreen,
        extra: mockBoardNo,
      );
    }
    return context.push<void>(
      Uri(
        path: RouteConstants.questionBankExamSummary,
        queryParameters: {'attempt': result.attemptId},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileViewAsync = ref.watch(profileScreenViewProvider);
    final questionBankAttempts = ref.watch(recentSubjectExamAttemptsProvider);
    final mockBoardResults = ref.watch(recentMockBoardResultsProvider);
    final recentResults = mergeRecentExamResults(
      questionBankAttempts: questionBankAttempts.value ?? const [],
      mockBoardResults: mockBoardResults.value ?? const [],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: profileViewAsync.when(
            data: (view) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileStatusCard(
                  lastName: view.card.lastName,
                  firstName: view.card.firstName,
                  middleName: view.card.middleName,
                  university: view.card.university,
                  dateOfExam: view.card.dateOfExam,
                  profileImageUrl: view.card.profileImageUrl,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('edit-profile-button'),
                    onPressed: () => context.push(RouteConstants.editProfile),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(height: 20),
                EditableBoardExamBadge(
                  value: view.boardExamDateLabel,
                  currentDate: view.boardExamDate,
                ),
                const SizedBox(height: 20),
                CountdownBadge(
                  label: 'Days left before Board Exam:',
                  value: view.daysLeftLabel,
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
                MantraCard(initialMantra: view.mantraText),
                const SizedBox(height: 20),
                ExaminationResultsCard(
                  title: 'Recent Results:',
                  results: recentResults,
                  initialCount: recentResultsPerKind,
                  onResultTap: (result) => _openSummary(context, result),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 320,
              child: Center(
                child: CircularProgressIndicator(
                  key: ValueKey('profile-loading'),
                ),
              ),
            ),
            error: (_, __) => SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'We could not load your profile.',
                      key: ValueKey('profile-error'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const ValueKey('profile-retry'),
                      onPressed: () => ref.invalidate(profileProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
