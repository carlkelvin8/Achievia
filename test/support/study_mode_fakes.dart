import 'package:achievia/core/utils/study_deck.dart';
import 'package:achievia/core/utils/study_progress_store.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/study_deck_repository.dart';

/// [n] questions with ids [base]..[base]+n-1. Each has three choices; the
/// correct one rotates (question id % 3), so tests cannot pass by always
/// picking the first option. Even ids have a rationale, odd ids none.
List<QuestionItemEntity> studyQuestions(int n, {int base = 1}) => [
  for (var i = 0; i < n; i++)
    QuestionItemEntity(
      id: base + i,
      questionText: 'Study question ${base + i}',
      rationale: (base + i).isEven ? 'Because reason ${base + i}' : '',
      choices: [
        for (var c = 0; c < 3; c++)
          ChoiceEntity(
            id: (base + i) * 10 + c,
            questiondId: base + i,
            choiceText: 'Option ${base + i}-$c',
            isCorrect: c == (base + i) % 3,
          ),
      ],
    ),
];

int correctChoiceId(QuestionItemEntity q) =>
    q.choices.firstWhere((c) => c.isCorrect).id;

int wrongChoiceId(QuestionItemEntity q) =>
    q.choices.firstWhere((c) => !c.isCorrect).id;

class FakeStudyRepo implements StudyDeckRepository {
  FakeStudyRepo(this.byQuiz);

  /// Eligible questions per subtopic (quiz) id.
  final Map<int, List<QuestionItemEntity>> byQuiz;
  bool fail = false;
  final requested = <int>[];

  @override
  Future<List<QuestionItemEntity>> getStudyQuestions(int quizId) async {
    requested.add(quizId);
    if (fail) throw Exception('offline');
    return byQuiz[quizId] ?? const [];
  }
}

class MemoryStudyStore implements StudyProgressStore {
  final data = <String, String>{};
  bool failSave = false;
  bool failLoad = false;
  int saves = 0;

  static String keyOf(String user, int quiz) =>
      SharedPrefsStudyProgressStore.key(user, quiz);

  StudyProgress? peek(String user, int quiz) =>
      StudyProgress.tryParse(data[keyOf(user, quiz)]);

  @override
  Future<StudyProgress?> load(String userId, int quizId) async {
    if (failLoad) throw Exception('read failed');
    return StudyProgress.tryParse(data[keyOf(userId, quizId)]);
  }

  @override
  Future<void> save(String userId, int quizId, StudyProgress progress) async {
    if (failSave) throw Exception('write failed');
    saves++;
    data[keyOf(userId, quizId)] = progress.toJsonString();
  }
}
