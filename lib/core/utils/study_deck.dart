import 'dart:convert';
import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

/// Persisted state of one user's study deck for one subtopic.
///
/// Every question belongs to exactly ONE category, so the counters can never
/// disagree with each other:
///   * Repeat    = questions marked Study Again that are still being studied
///                 ([repeatIds], always a subset of [queue]);
///   * Done      = questions marked Already Know ([known]);
///   * Remaining = every other active question (the rest of [queue]).
/// Remaining + Repeat + Done = deck size, and current = [queue].first.
///
/// This is deliberately independent of Take an Exam: it never touches exam
/// attempts, scores or timers.
class StudyProgress {
  /// Ids of the active (not archived) questions in presentation order; the
  /// first one is the current question.
  final List<int> queue;

  /// Ids archived with Already Know for the current deck lifecycle.
  final List<int> known;

  /// Ids marked Study Again that are still active. A question leaves this set
  /// the moment it is marked Already Know, and never belongs to [known] too.
  final List<int> repeatIds;

  final bool shuffleQuestions;
  final bool shuffleChoices;

  /// Stable per-question display order of choice ids. Kept for the whole deck
  /// lifecycle so a requeued question shows its choices in the same order.
  final Map<int, List<int>> choiceOrders;

  const StudyProgress({
    this.queue = const [],
    this.known = const [],
    this.repeatIds = const [],
    this.shuffleQuestions = false,
    this.shuffleChoices = false,
    this.choiceOrders = const {},
  });

  /// Active questions that are not marked Study Again.
  int get remaining => queue.where((id) => !repeatIds.contains(id)).length;
  int get repeat => repeatIds.length;
  int get done => known.length;
  int get deckSize => queue.length + known.length;
  int? get currentId => queue.isEmpty ? null : queue.first;
  bool get isEmpty => deckSize == 0;
  bool get isComplete => queue.isEmpty && known.isNotEmpty;

  StudyProgress copyWith({
    List<int>? queue,
    List<int>? known,
    List<int>? repeatIds,
    bool? shuffleQuestions,
    bool? shuffleChoices,
    Map<int, List<int>>? choiceOrders,
  }) => StudyProgress(
    queue: queue ?? this.queue,
    known: known ?? this.known,
    repeatIds: repeatIds ?? this.repeatIds,
    shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
    shuffleChoices: shuffleChoices ?? this.shuffleChoices,
    choiceOrders: choiceOrders ?? this.choiceOrders,
  );

  static const _version = 1;

  String toJsonString() => jsonEncode({
    'v': _version,
    'queue': queue,
    'known': known,
    'repeatIds': repeatIds,
    'shuffleQuestions': shuffleQuestions,
    'shuffleChoices': shuffleChoices,
    'choiceOrders': {for (final e in choiceOrders.entries) '${e.key}': e.value},
  });

  /// Parses stored data; returns null for anything unreadable or invalid so a
  /// corrupt entry falls back to a fresh deck instead of crashing.
  static StudyProgress? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['v'] != _version) return null;
      List<int> ints(Object? value) {
        if (value is! List) throw const FormatException('list');
        return [for (final v in value) v as int];
      }

      final orders = json['choiceOrders'];
      if (orders is! Map) return null;
      final queue = ints(json['queue']);
      final known = ints(json['known']);
      if (queue.toSet().length != queue.length ||
          known.toSet().length != known.length ||
          queue.toSet().intersection(known.toSet()).isNotEmpty) {
        return null;
      }
      // Older saves kept a plain press counter and no set: those start with
      // nothing marked, which is the only honest reading of them.
      final rawRepeat = json['repeatIds'];
      final repeatIds = <int>{
        if (rawRepeat is List)
          for (final id in ints(rawRepeat))
            if (queue.contains(id)) id,
      }.toList();
      return StudyProgress(
        queue: queue,
        known: known,
        repeatIds: repeatIds,
        shuffleQuestions: json['shuffleQuestions'] == true,
        shuffleChoices: json['shuffleChoices'] == true,
        choiceOrders: {
          for (final e in orders.entries) int.parse('${e.key}'): ints(e.value),
        },
      );
    } catch (_) {
      return null;
    }
  }
}

/// Pure deck transitions. Every function returns a new, internally consistent
/// [StudyProgress]; randomness is injected so behaviour is testable.
class StudyDeck {
  const StudyDeck._();

  /// Deck for [questions] (canonical order: ascending id, as supplied).
  static StudyProgress create(
    List<QuestionItemEntity> questions, {
    required Random random,
    bool shuffleQuestions = false,
    bool shuffleChoices = false,
  }) {
    final ids = [for (final q in questions) q.id];
    return StudyProgress(
      queue: shuffleQuestions ? _shuffled(ids, random) : ids,
      shuffleQuestions: shuffleQuestions,
      shuffleChoices: shuffleChoices,
      choiceOrders: shuffleChoices
          ? {for (final q in questions) q.id: _shuffledChoices(q, random)}
          : const {},
    );
  }

  /// Aligns [stored] progress with the questions that are eligible now.
  ///
  /// * ids that are no longer eligible are dropped from the queue and from
  ///   Already Know (so they leave the effective deck size);
  /// * newly eligible questions join the END of the active queue, never Done;
  /// * choice orders are kept only while they still list exactly the
  ///   question's current choices, otherwise they are regenerated (shuffle on)
  ///   or dropped (shuffle off);
  /// * Repeat keeps only ids that are still active.
  static StudyProgress reconcile(
    StudyProgress? stored,
    List<QuestionItemEntity> questions, {
    required Random random,
  }) {
    if (stored == null) return create(questions, random: random);
    final byId = {for (final q in questions) q.id: q};
    final queue = [
      for (final id in stored.queue)
        if (byId.containsKey(id)) id,
    ];
    final known = [
      for (final id in stored.known)
        if (byId.containsKey(id) && !queue.contains(id)) id,
    ];
    final seen = {...queue, ...known};
    final added = [
      for (final q in questions)
        if (!seen.contains(q.id)) q.id,
    ];
    queue.addAll(stored.shuffleQuestions ? _shuffled(added, random) : added);

    final orders = <int, List<int>>{};
    for (final q in questions) {
      final existing = stored.choiceOrders[q.id];
      if (existing != null && _sameChoices(existing, q)) {
        orders[q.id] = existing;
      } else if (stored.shuffleChoices) {
        orders[q.id] = _shuffledChoices(q, random);
      }
    }
    return stored.copyWith(
      queue: queue,
      known: known,
      repeatIds: [
        for (final id in stored.repeatIds)
          if (queue.contains(id)) id,
      ],
      choiceOrders: orders,
    );
  }

  /// Study Again: the question moves from Remaining to Repeat (Remaining -1,
  /// Repeat +1) and to the back of the queue, so it returns after every other
  /// active question. A question that is already in Repeat is not counted
  /// twice.
  static StudyProgress studyAgain(StudyProgress p) {
    if (p.queue.isEmpty) return p;
    final id = p.queue.first;
    return p.copyWith(
      queue: [...p.queue.skip(1), id],
      repeatIds: p.repeatIds.contains(id) ? p.repeatIds : [...p.repeatIds, id],
    );
  }

  /// Already Know: the question becomes Done and leaves whatever it was in.
  /// A Repeat question marked Already Know is removed from Repeat (Repeat -1,
  /// Done +1); a plain Remaining one goes Remaining -1, Done +1.
  static StudyProgress alreadyKnow(StudyProgress p) {
    if (p.queue.isEmpty) return p;
    final id = p.queue.first;
    return p.copyWith(
      queue: p.queue.sublist(1),
      known: p.known.contains(id) ? p.known : [...p.known, id],
      repeatIds: [
        for (final r in p.repeatIds)
          if (r != id) r,
      ],
    );
  }

  /// Reset Deck: everything active again, counters cleared, order and choice
  /// orders rebuilt from the current shuffle settings.
  static StudyProgress reset(
    StudyProgress p,
    List<QuestionItemEntity> questions, {
    required Random random,
  }) => create(
    questions,
    random: random,
    shuffleQuestions: p.shuffleQuestions,
    shuffleChoices: p.shuffleChoices,
  );

  /// Toggling Shuffle Questions reorders the active queue behind the current
  /// question (which stays put so the visible card never jumps). Already Know,
  /// Repeat and every counter are unchanged.
  static StudyProgress setShuffleQuestions(
    StudyProgress p,
    bool value,
    List<QuestionItemEntity> questions, {
    required Random random,
  }) {
    if (p.queue.length < 2) return p.copyWith(shuffleQuestions: value);
    final rank = {
      for (var i = 0; i < questions.length; i++) questions[i].id: i,
    };
    final rest = p.queue.sublist(1);
    final reordered = value
        ? _shuffled(rest, random)
        : ([...rest]..sort((a, b) => (rank[a] ?? 0).compareTo(rank[b] ?? 0)));
    return p.copyWith(
      shuffleQuestions: value,
      queue: [p.queue.first, ...reordered],
    );
  }

  /// Toggling Shuffle Choices regenerates orders for every question except
  /// [keepId] (the current question when it is already answered), so an
  /// answered card never reorders under the user.
  static StudyProgress setShuffleChoices(
    StudyProgress p,
    bool value,
    List<QuestionItemEntity> questions, {
    required Random random,
    int? keepId,
  }) {
    final orders = <int, List<int>>{};
    for (final q in questions) {
      if (q.id == keepId && p.choiceOrders[q.id] != null) {
        orders[q.id] = p.choiceOrders[q.id]!;
      } else if (value) {
        orders[q.id] = _shuffledChoices(q, random);
      }
    }
    return p.copyWith(shuffleChoices: value, choiceOrders: orders);
  }

  /// Choices of [question] in display order. Uses the stored order while it is
  /// valid, otherwise the canonical order (ascending id). Correctness always
  /// stays on the choice itself, so it is unaffected by display order.
  static List<ChoiceEntity> orderedChoices(
    QuestionItemEntity question,
    StudyProgress p,
  ) {
    final canonical = [...question.choices]..sort((a, b) => a.id - b.id);
    final order = p.choiceOrders[question.id];
    if (order == null || !_sameChoices(order, question)) return canonical;
    final byId = {for (final c in canonical) c.id: c};
    return [for (final id in order) byId[id]!];
  }

  static bool _sameChoices(List<int> order, QuestionItemEntity q) {
    final ids = q.choices.map((c) => c.id).toSet();
    return order.length == ids.length &&
        order.toSet().length == order.length &&
        order.toSet().containsAll(ids);
  }

  static List<int> _shuffledChoices(QuestionItemEntity q, Random random) =>
      _shuffled([...q.choices.map((c) => c.id)]..sort(), random);

  static List<int> _shuffled(List<int> ids, Random random) =>
      [...ids]..shuffle(random);
}
