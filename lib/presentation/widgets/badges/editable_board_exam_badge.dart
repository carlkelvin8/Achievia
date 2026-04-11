import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/badges/countdown_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableBoardExamBadge extends ConsumerWidget {
  final String value;
  final DateTime? currentDate;

  const EditableBoardExamBadge({
    super.key,
    required this.value,
    required this.currentDate,
  });

  Future<void> _pickBoardExamDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final safeInitialDate =
        (currentDate != null && !currentDate!.isBefore(today))
        ? DateTime(currentDate!.year, currentDate!.month, currentDate!.day)
        : today;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: today,
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Select Board Exam Date',
      cancelText: 'Cancel',
      confirmText: 'Save',
    );

    if (pickedDate == null) return;
    await ref.read(boardExamDateProvider.notifier).setDate(pickedDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CountdownBadge(
      label: 'Date of Board Exam:',
      value: value,
      onValueTap: () => _pickBoardExamDate(context, ref),
      textColor: AppColors.primary,
      valueColor: AppColors.primary,
    );
  }
}
