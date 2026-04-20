import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/badges/editable_board_exam_badge.dart';
import 'package:achievia/presentation/widgets/cards/examination_results_card.dart';
import 'package:achievia/presentation/widgets/cards/mantra_card.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:achievia/presentation/widgets/badges/countdown_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreenContent extends ConsumerWidget {
  const ProfileScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileViewAsync = ref.watch(profileScreenViewProvider);

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
                  purpose: view.card.purpose,
                  dateOfExam: view.card.dateOfExam,
                  profileImageUrl: view.card.profileImageUrl,
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
                ExaminationResultsCard(title: 'Examination Results:'),
                const SizedBox(height: 20),
                ExaminationResultsCard(title: 'Mock Boards Result:'),
              ],
            ),
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileStatusCard(),
                const SizedBox(height: 20),
                CountdownBadge(
                  label: 'Date of Board Exam:',
                  value: 'N/A',
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 20),
                const MantraCard(),
                const SizedBox(height: 20),
                ExaminationResultsCard(title: 'Examination Results:'),
                const SizedBox(height: 20),
                ExaminationResultsCard(title: 'Mock Boards Result:'),
              ],
            ),
            error: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileStatusCard(),
                const SizedBox(height: 20),
                CountdownBadge(
                  label: 'Date of Board Exam:',
                  value: 'N/A',
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
                CountdownBadge(
                  label: 'Days left before Board Exam:',
                  value: 'N/A',
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
                const MantraCard(),
                const SizedBox(height: 20),
                ExaminationResultsCard(title: 'Examination Results:'),
                const SizedBox(height: 20),
                ExaminationResultsCard(title: 'Mock Boards Result:'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
