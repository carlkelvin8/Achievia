import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              CountdownBadge(
                label: 'Days left before Board Exam:',
                value: '98 Days',
                textColor: AppColors.primary,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
              const MantraCard(),
              const SizedBox(height: 20),
              ExaminationResultsCard(
                results: results,
                title: 'Examination Results:',
              ),
              const SizedBox(height: 20),
              ExaminationResultsCard(title: 'Mock Boards Result:'),
            ],
          ),
        ),
      ),
    );
  }
}
