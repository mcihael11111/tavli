import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_progress.dart';

/// Persists learn-to-play progress in SharedPreferences.
class LearnProgressRepository {
  static const _prefix = 'learn_';
  static const _completedSuffix = '_completed';
  static const _timestampSuffix = '_ts';

  final SharedPreferences _prefs;

  LearnProgressRepository(this._prefs);

  /// Get the status for a specific lesson.
  LessonStatus getStatus(String lessonId) {
    final completed = _prefs.getBool('$_prefix$lessonId$_completedSuffix');
    if (completed == true) return LessonStatus.completed;
    return LessonStatus.notStarted;
  }

  /// Get full progress for a lesson.
  LessonProgress getProgress(String lessonId) {
    final status = getStatus(lessonId);
    final ts = _prefs.getInt('$_prefix$lessonId$_timestampSuffix');
    return LessonProgress(
      lessonId: lessonId,
      status: status,
      completedAt:
          ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
    );
  }

  /// Mark a lesson as completed.
  Future<void> markCompleted(String lessonId) async {
    await _prefs.setBool('$_prefix$lessonId$_completedSuffix', true);
    await _prefs.setInt(
        '$_prefix$lessonId$_timestampSuffix',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset progress for a lesson.
  Future<void> reset(String lessonId) async {
    await _prefs.remove('$_prefix$lessonId$_completedSuffix');
    await _prefs.remove('$_prefix$lessonId$_timestampSuffix');
  }

  /// Count completed lessons from a list of IDs.
  int completedCount(List<String> lessonIds) {
    return lessonIds
        .where((id) => getStatus(id) == LessonStatus.completed)
        .length;
  }

  /// Check if all lessons in a list are completed.
  bool allCompleted(List<String> lessonIds) {
    return completedCount(lessonIds) == lessonIds.length;
  }

  /// Auto-migrate from old tutorial system.
  Future<void> migrateFromOldTutorial() async {
    final oldCompleted = _prefs.getBool('tutorial_completed') ?? false;
    if (oldCompleted) {
      // Mark all foundation lessons as completed.
      for (final id in [
        'foundation_board',
        'foundation_moving',
        'foundation_hitting',
        'foundation_bearing_off',
        'foundation_strategy',
        'foundation_doubling_cube',
      ]) {
        await markCompleted(id);
      }
    }
  }
}
