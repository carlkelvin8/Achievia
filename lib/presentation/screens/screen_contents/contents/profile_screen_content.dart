import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/cards/examination_results_card.dart';
import 'package:achievia/presentation/widgets/cards/mantra_card.dart';
import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:achievia/presentation/widgets/badges/countdown_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreenContent extends ConsumerStatefulWidget {
  const ProfileScreenContent({super.key});

  @override
  ConsumerState<ProfileScreenContent> createState() =>
      _ProfileScreenContentState();
}

class _ProfileScreenContentState extends ConsumerState<ProfileScreenContent> {
  String _calculateDaysLeft(DateTime? examDate) {
    if (examDate == null) return 'N/A';

    final now = DateTime.now();
    final difference = examDate.difference(now);
    final days = difference.inDays;

    if (days < 0) {
      return 'Exam Passed';
    } else if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return '1 Day';
    } else {
      return '$days Days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileStatusCard(),
              const SizedBox(height: 20),
              profileAsync.when(
                data: (profile) => CountdownBadge(
                  label: 'Days left before Board Exam:',
                  value: _calculateDaysLeft(profile.dateOfExamination),
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => CountdownBadge(
                  label: 'Days left before Board Exam:',
                  value: 'N/A',
                  textColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
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
    );
  }
}
