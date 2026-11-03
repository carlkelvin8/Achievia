import 'package:achievia/core/utils/study_deck.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where Study Mode progress lives. Progress is stored on the device, scoped
/// to the signed-in user and the subtopic; it does not sync across devices.
abstract class StudyProgressStore {
  Future<StudyProgress?> load(String userId, int quizId);
  Future<void> save(String userId, int quizId, StudyProgress progress);
}

class SharedPrefsStudyProgressStore implements StudyProgressStore {
  const SharedPrefsStudyProgressStore();

  static String key(String userId, int quizId) =>
      'study_mode_${userId}_$quizId';

  @override
  Future<StudyProgress?> load(String userId, int quizId) async {
    final prefs = await SharedPreferences.getInstance();
    return StudyProgress.tryParse(prefs.getString(key(userId, quizId)));
  }

  @override
  Future<void> save(String userId, int quizId, StudyProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key(userId, quizId), progress.toJsonString());
  }
}
