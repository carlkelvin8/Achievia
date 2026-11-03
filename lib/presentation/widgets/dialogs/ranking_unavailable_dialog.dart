import 'package:flutter/material.dart';

/// What the user decided when the server could not record the exam start.
enum RankingUnavailableChoice { cancel, retry, continueUnranked }

/// Tells the user, BEFORE the exam starts, that the attempt will not be
/// eligible for the leaderboard because the server could not record its start.
Future<RankingUnavailableChoice?> showRankingUnavailableDialog(
  BuildContext context,
) {
  return showDialog<RankingUnavailableChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ranking unavailable'),
      content: const Text(
        "We couldn't reach the server to record the start of your exam. "
        'You can still take the exam and see your score, but this attempt '
        'will not be eligible for the leaderboard.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(RankingUnavailableChoice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(RankingUnavailableChoice.retry),
          child: const Text('Try again'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            dialogContext,
          ).pop(RankingUnavailableChoice.continueUnranked),
          child: const Text('Continue without ranking'),
        ),
      ],
    ),
  );
}

/// Records the exam start on the server and decides whether the exam may
/// begin. Returns true when the exam should start (start recorded, or the user
/// explicitly accepted an unranked attempt); false when the user cancelled.
Future<bool> confirmExamStart(
  BuildContext context,
  Future<bool> Function() recordStart,
) async {
  while (true) {
    if (await recordStart()) return true;
    if (!context.mounted) return false;
    final choice = await showRankingUnavailableDialog(context);
    switch (choice) {
      case RankingUnavailableChoice.retry:
        continue;
      case RankingUnavailableChoice.continueUnranked:
        return true;
      case RankingUnavailableChoice.cancel:
      case null:
        return false;
    }
  }
}
