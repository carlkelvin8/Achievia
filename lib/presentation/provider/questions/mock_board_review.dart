import 'dart:convert';

import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/data/data_source/home/mock_board_progress_remote.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A finished Mock Board as the student answered it: the 600 questions in
/// exam order and the choice index picked for each (keyed
/// `'<batchId>:<questionId>'`), for the question-by-question Summary.
class MockBoardReview {
  final int attemptNo;
  final List<QuizItemEntity> board;
  final Map<String, int> selectedAnswers;

  const MockBoardReview({
    required this.attemptNo,
    required this.board,
    required this.selectedAnswers,
  });
}

/// Keeps each submitted board on the device so a past attempt's Summary can
/// be opened again. The server keeps only the subject scores, so this is the
/// only record of which choice was picked.
///
/// Only ids are stored (question ids, choice order and the picks, a few KB
/// per attempt); the content is downloaded again when the Summary opens.
class MockBoardReviewStore {
  const MockBoardReviewStore();

  /// Attempts kept per user (the Profile's history window and then some).
  static const keep = 30;

  static String _indexKey(String userId) => 'mock_board_reviews_$userId';
  static String _key(String userId, int attemptNo) =>
      'mock_board_review_${userId}_$attemptNo';

  Future<void> save(
    String userId,
    int attemptNo,
    MockBoardSession session,
    Map<String, int> selectedAnswers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId, attemptNo),
      jsonEncode({
        'compact': session.toCompactJson(),
        'selectedAnswers': selectedAnswers,
      }),
    );
    final index = [
      attemptNo,
      for (final no in prefs.getStringList(_indexKey(userId)) ?? const [])
        if (int.tryParse(no) case final int n when n != attemptNo) n,
    ];
    for (final stale in index.skip(keep)) {
      await prefs.remove(_key(userId, stale));
    }
    await prefs.setStringList(_indexKey(userId), [
      for (final no in index.take(keep)) '$no',
    ]);
  }

  /// The compact board and the picks, or null when this device has none.
  Future<({Map<String, dynamic> compact, Map<String, int> answers})?> load(
    String userId,
    int attemptNo,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, attemptNo));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final compact = json['compact'];
      final answers = json['selectedAnswers'];
      if (compact is! Map || answers is! Map) return null;
      return (
        compact: Map<String, dynamic>.from(compact),
        answers: {
          for (final entry in answers.entries)
            if (entry.value is int) entry.key.toString(): entry.value as int,
        },
      );
    } on FormatException {
      return null;
    }
  }
}

final mockBoardReviewStoreProvider = Provider<MockBoardReviewStore>(
  (ref) => const MockBoardReviewStore(),
);

/// The attempt that was just submitted, still in memory: its Summary opens
/// without downloading anything.
final lastMockBoardReviewProvider = StateProvider<MockBoardReview?>(
  (ref) => null,
);

/// Saves the just-submitted board for its Summary (in memory and on the
/// device). Best effort: a failure never affects the saved result.
Future<void> keepMockBoardReview(
  Ref ref, {
  required int attemptNo,
  required MockBoardSession? session,
  required Map<String, int> selectedAnswers,
}) async {
  if (session == null) return;
  ref.read(lastMockBoardReviewProvider.notifier).state = MockBoardReview(
    attemptNo: attemptNo,
    board: _entities(session.board),
    selectedAnswers: Map.of(selectedAnswers),
  );
  final userId = ref.read(mockBoardUserIdProvider)();
  if (userId == null) return;
  try {
    await ref
        .read(mockBoardReviewStoreProvider)
        .save(userId, attemptNo, session, selectedAnswers);
  } catch (error) {
    debugPrint('Mock Board summary not kept on the device: $error');
  }
}

List<QuizItemEntity> _entities(List<Map<String, dynamic>> board) => [
  for (final section in board) QuizDtoItems.fromJson(section).toEntity(),
];

/// The Summary of Mock Board attempt number `attemptNo`: from memory right
/// after submitting, otherwise rebuilt from the copy kept on this device.
/// Null when this device has no copy (an attempt taken elsewhere or before
/// summaries were kept).
final mockBoardReviewProvider = FutureProvider.autoDispose
    .family<MockBoardReview?, int>((ref, attemptNo) async {
      final last = ref.read(lastMockBoardReviewProvider);
      if (last != null && last.attemptNo == attemptNo) return last;

      final userId = ref.read(mockBoardUserIdProvider)();
      if (userId == null) return null;
      final kept = await ref
          .read(mockBoardReviewStoreProvider)
          .load(userId, attemptNo);
      if (kept == null) return null;
      final session = await SupabaseMockBoardProgressStore().rebuildFromCompact(
        kept.compact,
      );
      if (session == null) return null;
      return MockBoardReview(
        attemptNo: attemptNo,
        board: _entities(session.board),
        selectedAnswers: kept.answers,
      );
    });
