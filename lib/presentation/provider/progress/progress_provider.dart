import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/progress_aggregator.dart';
import 'package:achievia/core/utils/streak_rules.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/domain/use_cases/progress/progress_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/progress/screentime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';

final progressUseCaseProvider = Provider<ProgressUseCase>((ref) {
  return sl<ProgressUseCase>();
});

final progressProvider = FutureProvider.autoDispose<ProgressEntity>((
  ref,
) async {
  final today = ref.watch(localDayProvider);
  final todayMet = ref.watch(todayStreakMetProvider);
  final token = await ref.watch(tokenStream.future);
  final normalizedToday = DateTime(today.year, today.month, today.day);
  if (token == null || token.isEmpty) {
    return aggregateProgress(
      snapshot: const ProgressSnapshotDto(
        activeDays: [],
        quizAttempts: [],
        studySessions: [],
      ),
      startDate: normalizedToday,
      today: normalizedToday,
    );
  }

  DateTime startDate = normalizedToday;
  try {
    final profile = await ref.watch(profileProvider.future);
    final createdAt = profile.createdAt;
    if (createdAt != null) {
      final normalizedCreated = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );
      if (!normalizedCreated.isAfter(normalizedToday)) {
        startDate = normalizedCreated;
      }
    }
  } catch (_) {
    // Progress rows remain authoritative even if the profile header is unavailable.
  }

  final useCase = ref.read(progressUseCaseProvider);
  final fetched = await useCase.getSnapshot();
  // A day is blue only after 60 minutes of use; opening the screen no longer
  // counts. Earlier days stay as stored.
  final snapshot = ProgressSnapshotDto(
    activeDays: applyDailyUsageRule(
      days: fetched.activeDays,
      today: normalizedToday,
      todaySeconds: todayMet ? kStreakRequiredSeconds : 0,
    ),
    quizAttempts: fetched.quizAttempts,
    studySessions: fetched.studySessions,
    subjectExamAttempts: fetched.subjectExamAttempts,
  );

  return aggregateProgress(
    snapshot: snapshot,
    startDate: startDate,
    today: normalizedToday,
  );
}, retry: (_, _) => null);

final gradingBracketsProvider = Provider<List<GradingBracket>>((ref) {
  return gradingBrackets;
});
