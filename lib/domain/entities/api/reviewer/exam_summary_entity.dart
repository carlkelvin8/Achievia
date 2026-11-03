import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

/// One answer option exactly as it was shown during the exam.
class ExamSummaryChoice {
  /// Live choice id at exam time; informational only (the row may be deleted).
  final int? id;
  final String text;
  final bool isCorrect;

  const ExamSummaryChoice({
    this.id,
    required this.text,
    required this.isCorrect,
  });
}

enum ExamItemStatus { correct, incorrect, unanswered }

/// One question of a completed exam: an immutable snapshot of the question,
/// its choices (in the order shown) and what the user picked.
class ExamSummaryItem {
  /// 1-based position in the exam.
  final int position;

  /// Traceability reference; null once the live question was deleted.
  final int? questionId;
  final String questionText;
  final List<ExamSummaryChoice> choices;

  /// Index into [choices]; null when the item was left unanswered.
  final int? selectedIndex;
  final int correctIndex;

  /// Attachment of the question (empty when it has none) and its rationale.
  final String imagePath;
  final String rationale;

  const ExamSummaryItem({
    required this.position,
    this.questionId,
    required this.questionText,
    required this.choices,
    required this.selectedIndex,
    required this.correctIndex,
    this.imagePath = '',
    this.rationale = '',
  });

  /// Same item with the question's current attachment and rationale.
  ExamSummaryItem withExtras({String? imagePath, String? rationale}) =>
      ExamSummaryItem(
        position: position,
        questionId: questionId,
        questionText: questionText,
        choices: choices,
        selectedIndex: selectedIndex,
        correctIndex: correctIndex,
        imagePath: imagePath ?? this.imagePath,
        rationale: rationale ?? this.rationale,
      );

  bool get isAnswered => selectedIndex != null;

  /// Graded like the live exam: the chosen option's own correctness flag.
  bool get isCorrect =>
      selectedIndex != null &&
      selectedIndex! >= 0 &&
      selectedIndex! < choices.length &&
      choices[selectedIndex!].isCorrect;

  ExamItemStatus get status => !isAnswered
      ? ExamItemStatus.unanswered
      : (isCorrect ? ExamItemStatus.correct : ExamItemStatus.incorrect);

  /// What the client reports to `save_subject_exam_attempt`: only what
  /// happened in this session. Correctness, text, score and the correct choice
  /// are deliberately absent; the server derives them from the Question Bank.
  Map<String, Object?> toRpcJson() => {
    'position': position,
    'question_id': questionId,
    'selected_choice_id': selectedIndex == null
        ? null
        : choices[selectedIndex!].id,
    'choice_order': [for (final c in choices) c.id],
  };
}

/// Everything needed to persist (or, in development, show) an exact summary of
/// one exam session. [clientAttemptId] is the idempotency key of the session.
class ExamAttemptSnapshot {
  final String clientAttemptId;
  final List<ExamSummaryItem> items;

  const ExamAttemptSnapshot({
    required this.clientAttemptId,
    required this.items,
  });

  int get correctCount => items.where((i) => i.isCorrect).length;

  /// Builds the snapshot from the live session: original question order,
  /// selected answers keyed by question id, unanswered items included.
  /// Throws [StateError] if a question has no correct choice, because a
  /// summary cannot represent it honestly.
  factory ExamAttemptSnapshot.fromSession({
    required String clientAttemptId,
    required List<QuestionItemEntity> questions,
    required Map<int, int> selectedAnswers,
  }) {
    final items = <ExamSummaryItem>[];
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final correctIndex = question.choices.indexWhere((c) => c.isCorrect);
      if (correctIndex < 0) {
        throw StateError('Question ${question.id} has no correct choice.');
      }
      items.add(
        ExamSummaryItem(
          position: i + 1,
          questionId: question.id,
          questionText: question.questionText,
          choices: [
            for (final c in question.choices)
              ExamSummaryChoice(
                id: c.id,
                text: c.choiceText,
                isCorrect: c.isCorrect,
              ),
          ],
          selectedIndex: selectedAnswers[question.id],
          correctIndex: correctIndex,
          imagePath: question.imagePath,
          rationale: question.rationale,
        ),
      );
    }
    return ExamAttemptSnapshot(
      clientAttemptId: clientAttemptId,
      items: List.unmodifiable(items),
    );
  }

  ExamAttemptSummary toSummary({String attemptId = ''}) =>
      ExamAttemptSummary(attemptId: attemptId, items: items);
}

/// A completed exam, ready to render. [attemptId] is empty for an in-memory
/// summary of an attempt that was never persisted.
class ExamAttemptSummary {
  final String attemptId;
  final List<ExamSummaryItem> items;

  const ExamAttemptSummary({required this.attemptId, required this.items});

  bool get isPersisted => attemptId.isNotEmpty;

  int get total => items.length;
  int get correct =>
      items.where((i) => i.status == ExamItemStatus.correct).length;
  int get incorrect =>
      items.where((i) => i.status == ExamItemStatus.incorrect).length;
  int get unanswered =>
      items.where((i) => i.status == ExamItemStatus.unanswered).length;
}

/// Pure consistency checks between a summary and the saved result.
class ExamSummaryValidator {
  const ExamSummaryValidator._();

  /// Returns human-readable problems; empty means the summary is consistent.
  static List<String> validate(
    List<ExamSummaryItem> items, {
    required int savedCorrect,
    required int savedTotal,
  }) {
    final issues = <String>[];
    if (items.length != savedTotal) {
      issues.add('Expected $savedTotal items but found ${items.length}.');
    }
    final positions = items.map((i) => i.position).toList();
    if (positions.toSet().length != positions.length) {
      issues.add('Duplicate item positions.');
    }
    final expected = List.generate(items.length, (i) => i + 1);
    if (!_sameOrder(positions, expected)) {
      issues.add('Item positions are not 1..${items.length} in order.');
    }
    final ids = items.map((i) => i.questionId).whereType<int>().toList();
    if (ids.toSet().length != ids.length) {
      issues.add('The same question appears more than once.');
    }
    for (final item in items) {
      final ok =
          item.choices.isNotEmpty &&
          item.correctIndex >= 0 &&
          item.correctIndex < item.choices.length &&
          (item.selectedIndex == null ||
              (item.selectedIndex! >= 0 &&
                  item.selectedIndex! < item.choices.length));
      if (!ok) issues.add('Item ${item.position} is malformed.');
    }
    final correct = items.where((i) => i.isCorrect).length;
    if (correct != savedCorrect) {
      issues.add(
        'Summary has $correct correct but the result saved $savedCorrect.',
      );
    }
    final unanswered = items.where((i) => !i.isAnswered).length;
    final incorrect = items.length - correct - unanswered;
    if (correct + incorrect + unanswered != items.length) {
      issues.add('Item statuses do not add up.');
    }
    return issues;
  }

  static bool _sameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Random RFC 4122 v4 id for one exam session (idempotency key).
String newClientAttemptId([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int from, int to) => bytes
      .sublist(from, to)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Why a persisted summary could not be shown.
/// [invalidId]: the attempt id is empty or malformed (never queried).
/// [denied]: the backend refused access (row level security).
enum ExamSummaryFailure { notFound, unavailable, malformed, invalidId, denied }

class ExamSummaryException implements Exception {
  final ExamSummaryFailure failure;
  final List<String> issues;

  const ExamSummaryException(this.failure, [this.issues = const []]);

  @override
  String toString() => 'ExamSummaryException($failure, $issues)';
}

/// Route arguments for the read-only Exam Summary screen.
///
/// Persisted path: a non-empty [attemptId] loads the saved snapshot from the
/// backend, so Profile can reopen the same summary later with just an id.
/// Development fallback: [inMemory] holds the just-finished exam when nothing
/// was persisted; it is exact but disappears with the screen and is never
/// treated as saved.
class ExamSummaryArgs {
  final String? attemptId;
  final ExamAttemptSummary? inMemory;

  const ExamSummaryArgs({this.attemptId, this.inMemory});

  bool get isPersisted => attemptId != null && attemptId!.isNotEmpty;

  /// True when [attemptId] looks like a usable id. Anything else must never
  /// reach the backend and never fall back to "the latest attempt".
  bool get hasValidId => isValidExamAttemptId(attemptId);
}

final _attemptIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

bool isValidExamAttemptId(String? id) =>
    id != null && _attemptIdPattern.hasMatch(id);

/// Builds the summary route arguments from either navigation `extra` or the
/// `attempt` query parameter, so the route works when opened by id alone (no
/// hidden in-memory state). Returns null when neither is present.
ExamSummaryArgs? examSummaryArgsFromRoute({
  Object? extra,
  required Map<String, String> query,
}) {
  if (extra is ExamSummaryArgs) return extra;
  if (query.containsKey('attempt')) {
    return ExamSummaryArgs(attemptId: query['attempt']);
  }
  return null;
}
