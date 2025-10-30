import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/qotd_entity.dart';
import 'package:achievia/domain/entities/goal_entity.dart';

class QotdNotifier extends Notifier<QotdEntity> {
  @override
  QotdEntity build() {
    // Seed with previous hard-coded demo data
    return const QotdEntity(
      id: 'qotd-2025-07-05',
      question:
          'What conditions are associated with a secretory defect in bilirubin metabolism?',
      options: [
        'Physiologic jaundice of the newborn',
        'Dubin-Johnson syndrome and Rotor syndrome',
        'Crigler-Najjar syndrome',
        'Gilbert syndrome',
      ],
    );
  }

  void selectOption(int index) {
    if (index < 0 || index >= state.options.length) return;
    state = state.copyWith(selectedIndex: index);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final qotdProvider = NotifierProvider<QotdNotifier, QotdEntity>(
  () => QotdNotifier(),
);

class GoalNotifier extends Notifier<GoalEntity> {
  @override
  GoalEntity build() {
    return GoalEntity(
      id: 'goal-2025-07-05',
      date: DateTime(2025, 7, 5),
      title: 'Hematology topic 1',
      details: 'Page 1 - page 12\nJuly 5, 2025',
      isChecked: false,
    );
  }

  void toggleChecked() {
    state = state.copyWith(isChecked: !state.isChecked);
  }
}

final goalProvider = NotifierProvider<GoalNotifier, GoalEntity>(
  () => GoalNotifier(),
);
