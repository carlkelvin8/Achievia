import 'dart:convert';

import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Today's resolved Question of the Day, kept on the device per account so the
/// card can render immediately instead of repeating the whole lookup (subjects,
/// eligibility, question, choices, answer) on every launch.
///
/// The entry is only ever read for the same account and the same UTC+8 day it
/// was written for; the saved answer is re-checked in the background.
class QotdCacheEntry {
  // Refresh older payloads once so the admin's correct_description fallback
  // is included in the cached rationale.
  static const _version = 3;
  final String dayKey;
  final String subjectTitle;
  final QotdDailyQuestion question;
  final QotdUserAnswer? answer;

  const QotdCacheEntry({
    required this.dayKey,
    required this.subjectTitle,
    required this.question,
    required this.answer,
  });

  Map<String, Object?> toJson() => {
    'version': _version,
    'dayKey': dayKey,
    'subjectTitle': subjectTitle,
    'question': {
      'id': question.questionId,
      'quizId': question.quizId,
      'text': question.questionText,
      'imagePath': question.imagePath,
      'rationale': question.rationale,
      'choices': [
        for (final c in question.choices)
          {'id': c.id, 'text': c.text, 'correct': c.isCorrect},
      ],
    },
    'answer': answer == null
        ? null
        : {
            'choiceId': answer!.choiceId,
            'correct': answer!.isCorrect,
            'at': answer!.answeredAt.toUtc().toIso8601String(),
          },
  };

  static QotdCacheEntry? fromJson(Object? raw) {
    if (raw is! Map || raw['version'] != _version) return null;
    final q = raw['question'];
    if (q is! Map || raw['dayKey'] is! String) return null;
    final choices = q['choices'];
    if (choices is! List || choices.length < 2) return null;
    final answer = raw['answer'];
    return QotdCacheEntry(
      dayKey: raw['dayKey'] as String,
      subjectTitle: (raw['subjectTitle'] ?? '').toString(),
      question: QotdDailyQuestion(
        questionId: q['id'] as int,
        quizId: q['quizId'] as int,
        questionText: (q['text'] ?? '').toString(),
        imagePath: (q['imagePath'] ?? '').toString(),
        rationale: (q['rationale'] ?? '').toString(),
        choices: [
          for (final c in choices)
            QotdChoice(
              id: (c as Map)['id'] as int,
              text: (c['text'] ?? '').toString(),
              isCorrect: c['correct'] == true,
            ),
        ],
      ),
      answer: answer is Map
          ? QotdUserAnswer(
              choiceId: answer['choiceId'] as int,
              isCorrect: answer['correct'] == true,
              answeredAt:
                  DateTime.tryParse(answer['at']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            )
          : null,
    );
  }
}

class QotdCacheStore {
  const QotdCacheStore(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(String accountId) => 'qotd_cache_$accountId';

  /// The entry for [accountId] and [dayKey], or null when missing, from
  /// another day, or unreadable. Never throws.
  QotdCacheEntry? read(String accountId, String dayKey) {
    try {
      final raw = _prefs.getString(keyFor(accountId));
      if (raw == null) return null;
      final entry = QotdCacheEntry.fromJson(jsonDecode(raw));
      return entry != null && entry.dayKey == dayKey ? entry : null;
    } catch (error) {
      debugPrint('QotdCacheStore.read failed: $error');
      return null;
    }
  }

  Future<void> write(String accountId, QotdCacheEntry entry) async {
    try {
      await _prefs.setString(keyFor(accountId), jsonEncode(entry.toJson()));
    } catch (error) {
      debugPrint('QotdCacheStore.write failed: $error');
    }
  }
}
