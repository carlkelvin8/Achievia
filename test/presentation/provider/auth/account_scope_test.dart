import 'dart:async';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'account changes discard private caches; token refresh retains them',
    () async {
      var builds = 0;
      final ids = StreamController<String?>();
      final container = ProviderContainer(
        overrides: [
          activeAccountIdProvider.overrideWith((ref) => ids.stream),
          profileProvider.overrideWith((ref) async {
            builds++;
            return const ProfileEntity();
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await ids.close();
      });
      container.listen(accountCacheResetProvider, (_, _) {});
      ids.add('alice');
      await Future<void>.delayed(Duration.zero);
      await container.read(profileProvider.future);
      expect(builds, 1);
      ids.add('alice');
      await Future<void>.delayed(Duration.zero);
      await container.read(profileProvider.future);
      expect(builds, 1);
      ids.add(null);
      await Future<void>.delayed(Duration.zero);
      await container.read(profileProvider.future);
      ids.add('bob');
      await Future<void>.delayed(Duration.zero);
      await container.read(profileProvider.future);
      expect(builds, 3);
    },
  );

  test('switching accounts forgets the Mock Board answers', () async {
    final ids = StreamController<String?>();
    final container = ProviderContainer(
      overrides: [activeAccountIdProvider.overrideWith((ref) => ids.stream)],
    );
    addTearDown(() async {
      container.dispose();
      await ids.close();
      resetMockBoardAnswers();
    });
    container.listen(accountCacheResetProvider, (_, _) {});
    ids.add('alice');
    await Future<void>.delayed(Duration.zero);

    recordAnswer('Hematology', true, questionId: 41, choiceId: 411);
    ids.add('bob');
    await Future<void>.delayed(Duration.zero);

    expect(mockBoardSelections, isEmpty);
    expect(subjectScores, isEmpty);
    // Bob answering the same question id starts from nothing.
    recordAnswer('Hematology', false, questionId: 41, choiceId: 412);
    expect(subjectScores['Hematology']!.total, 1);
    expect(subjectScores['Hematology']!.correct, 0);
  });
}
