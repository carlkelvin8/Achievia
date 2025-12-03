import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/core/utils/helpers.dart';

class ProgressNotifier extends Notifier<ProgressEntity> {
  @override
  ProgressEntity build() {
    // Use demo data from helpers.dart
    return demoProgressData;
  }

  void updateScore(double newScore) {
    state = state.copyWith(currentScore: newScore);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressEntity>(
  () => ProgressNotifier(),
);

// Grading brackets provider - uses data from helpers.dart
final gradingBracketsProvider = Provider<List<GradingBracket>>((ref) {
  return gradingBrackets;
});
