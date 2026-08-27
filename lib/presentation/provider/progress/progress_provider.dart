import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/progress_aggregator.dart';
import 'package:achievia/data/models/progress/progress_day_dto.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/domain/use_cases/progress/progress_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressUseCaseProvider = Provider<ProgressUseCase>((ref) {
  return sl<ProgressUseCase>();
});

final progressProvider = FutureProvider.autoDispose<ProgressEntity>((
  ref,
) async {
  final token = ref.watch(tokenStream).value;
  final today = DateTime.now();
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
  var snapshot = await useCase.getSnapshot();
  final hasToday = snapshot.activeDays.any(
    (day) => _dateKey(day.activityDate) == _dateKey(normalizedToday),
  );
  if (!hasToday) {
    await useCase.markTodayActive();
    snapshot = ProgressSnapshotDto(
      activeDays: [
        ...snapshot.activeDays,
        ProgressDayDto(
          id: 0,
          userId: '',
          activityDate: normalizedToday,
          isActive: true,
        ),
      ],
      quizAttempts: snapshot.quizAttempts,
      studySessions: snapshot.studySessions,
    );
  }

  return aggregateProgress(
    snapshot: snapshot,
    startDate: startDate,
    today: normalizedToday,
  );
}, retry: (_, _) => null);

String _dateKey(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).toIso8601String().split('T').first;

final gradingBracketsProvider = Provider<List<GradingBracket>>((ref) {
  return gradingBrackets;
});
