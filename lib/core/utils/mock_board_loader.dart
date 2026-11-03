import 'dart:math';

import 'package:achievia/const.dart';
import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/data_source/soft_delete_columns.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';

/// Read access the Mock Board generator needs. Every method returns only
/// live (`deleted_at IS NULL`) rows; the implementation below is paged and
/// chunked so no request hits the API's 1,000-row cap or the URL length limit.
abstract class MockBoardSource {
  Future<List<Map<String, dynamic>>> liveQuizzes(int subjectId);
  Future<List<int>> liveQuestionIds(int quizId);
  Future<List<Map<String, dynamic>>> questions(List<int> ids);
  Future<List<Map<String, dynamic>>> choices(List<int> questionIds);
}

class SupabaseMockBoardSource implements MockBoardSource {
  static const _pageSize = 1000;
  static const _idChunk = 150;

  @override
  Future<List<Map<String, dynamic>>> liveQuizzes(int subjectId) async {
    final rows = await (await SoftDeleteColumns.liveSelect(
      supabase,
      'quizzes',
      '*',
    )).eq('subject_id', subjectId).order('created_at');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<int>> liveQuestionIds(int quizId) async {
    final ids = <int>[];
    for (var from = 0; ; from += _pageSize) {
      final page = await (await SoftDeleteColumns.liveSelect(
        supabase,
        'questions',
        'id',
      )).eq('quiz_id', quizId).order('id').range(from, from + _pageSize - 1);
      ids.addAll(page.map((row) => readInt(row['id'])).whereType<int>());
      if (page.length < _pageSize) return ids;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> questions(List<int> ids) async {
    final out = <Map<String, dynamic>>[];
    for (var start = 0; start < ids.length; start += _idChunk) {
      final chunk = ids.sublist(start, min(start + _idChunk, ids.length));
      final rows = await (await SoftDeleteColumns.liveSelect(
        supabase,
        'questions',
        'id, quiz_id, question_text, image_path, rationale, '
            'correct_description',
      )).inFilter('id', chunk);
      out.addAll(rows.map((row) => Map<String, dynamic>.from(row)));
    }
    return out;
  }

  @override
  Future<List<Map<String, dynamic>>> choices(List<int> questionIds) async {
    final out = <Map<String, dynamic>>[];
    for (var start = 0; start < questionIds.length; start += _idChunk) {
      final chunk = questionIds.sublist(
        start,
        min(start + _idChunk, questionIds.length),
      );
      for (var from = 0; ; from += _pageSize) {
        final page =
            await (await SoftDeleteColumns.liveSelect(
                  supabase,
                  'choices',
                  'id, choice_text, is_correct, question_id',
                ))
                .inFilter('question_id', chunk)
                .order('id')
                .range(from, from + _pageSize - 1);
        out.addAll(page.map((row) => Map<String, dynamic>.from(row)));
        if (page.length < _pageSize) break;
      }
    }
    return out;
  }
}

/// How many topics are loaded in parallel.
const int _topicConcurrency = 8;

/// Builds the Mock Board sections for the given (live) [subjects].
///
/// Only the questions that can actually be used are downloaded: per subtopic
/// a random batch of candidates is loaded and checked with the shared
/// eligibility rule, and more batches are loaded only while the subtopic is
/// still short of its configured count (or, for a pooled subject, of the
/// pool's count). Failures carry a [MockBoardFailure].
Future<List<QuizDtoItems>> loadMockBoardQuizItems(
  List<Map<String, dynamic>> subjects, {
  MockBoardSource? source,
  Random? random,
}) async {
  final data = source ?? SupabaseMockBoardSource();
  final rng = random ?? Random();

  final quizzesBySubject = <int, List<Map<String, dynamic>>>{};
  await Future.wait([
    for (final subject in subjects)
      if (readInt(subject['id']) case final subjectId?)
        data.liveQuizzes(subjectId).then((rows) {
          quizzesBySubject[subjectId] = rows;
        }),
  ]);

  // How many questions each subtopic must supply (max over the sections that
  // use it). A missing/inconsistent configuration fails here, before any
  // question is downloaded.
  final needByQuiz = <int, int>{};
  for (final spec in mockBoardSectionSpecs) {
    final sourceSubjects = subjects
        .where((s) => isMockBoardSectionSubject(s, spec))
        .toList();
    if (sourceSubjects.isEmpty) {
      throw MockBoardException(
        MockBoardFailure.notConfigured,
        '${spec.title} has no configured database section',
      );
    }
    final quizzes = [
      for (final subject in sourceSubjects)
        ...?quizzesBySubject[readInt(subject['id'])],
    ];
    if (quizzes.isEmpty) {
      throw MockBoardException(
        MockBoardFailure.notConfigured,
        '${spec.title} has no configured topics',
      );
    }
    // A pooled topic may supply up to the whole pool count, so that many of
    // its questions are loaded; the pick across the pool happens later.
    mockBoardSectionBlueprint(
      subjects: sourceSubjects,
      quizzesBySubject: quizzesBySubject,
      label: spec.title,
    ).maxNeedByQuiz.forEach((quizId, count) {
      if (count > (needByQuiz[quizId] ?? 0)) needByQuiz[quizId] = count;
    });
  }

  final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
  final choicesByQuestion = <int, List<Map<String, dynamic>>>{};

  Future<void> loadQuiz(int quizId, int need) async {
    final ids = await data.liveQuestionIds(quizId);
    ids.shuffle(rng);
    final eligible = <Map<String, dynamic>>[];
    var cursor = 0;
    while (eligible.length < need && cursor < ids.length) {
      final end = min(cursor + (need - eligible.length) + 20, ids.length);
      final batch = ids.sublist(cursor, end);
      cursor = end;
      final batchRows = await Future.wait([
        data.questions(batch),
        data.choices(batch),
      ]);
      final questionRows = batchRows[0];
      final choiceRows = batchRows[1];
      final grouped = <int, List<Map<String, dynamic>>>{};
      for (final choice in choiceRows) {
        final questionId = readInt(choice['question_id']);
        if (questionId != null) {
          grouped.putIfAbsent(questionId, () => []).add(choice);
        }
      }
      for (final question in questionRows) {
        final questionId = readInt(question['id']);
        if (questionId == null) continue;
        final choices = grouped[questionId] ?? const [];
        if (!isEligibleMockBoardQuestion(question, choices)) continue;
        eligible.add(question);
        choicesByQuestion[questionId] = choices;
      }
    }
    questionsByQuiz[quizId] = eligible;
  }

  // Sequential loading took one round trip per topic (about 450 requests),
  // which was too slow on a mobile connection. A few topics load at once.
  final pending = [
    for (final entry in needByQuiz.entries)
      if (entry.value > 0) entry,
  ];
  for (var start = 0; start < pending.length; start += _topicConcurrency) {
    final group = pending.skip(start).take(_topicConcurrency);
    await Future.wait([
      for (final entry in group) loadQuiz(entry.key, entry.value),
    ]);
  }

  return buildMockBoardQuizItemsFromRows(
    subjects: subjects,
    quizzesBySubject: quizzesBySubject,
    questionsByQuiz: questionsByQuiz,
    choicesByQuestion: choicesByQuestion,
    random: rng,
  );
}
