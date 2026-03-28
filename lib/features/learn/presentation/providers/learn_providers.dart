import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/tradition.dart';
import '../../../../shared/services/settings_service.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/learn_progress_repository.dart';
import '../../domain/learn_content.dart';

/// Async provider that initializes the repository.
final learnProgressProvider = FutureProvider<LearnProgressRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final repo = LearnProgressRepository(prefs);
  await repo.migrateFromOldTutorial();
  return repo;
});

/// The player's current tradition from settings.
final learnTraditionProvider = Provider<Tradition>((ref) {
  return SettingsService.instance.tradition;
});

/// All sections ordered for the current player.
final learnSectionsProvider = Provider<List<LessonSection>>((ref) {
  final tradition = ref.watch(learnTraditionProvider);
  return LearnContent.sectionsForTradition(tradition);
});

/// Overall progress as a percentage (0.0 – 1.0).
final learnOverallProgressProvider = FutureProvider<double>((ref) async {
  final repo = await ref.watch(learnProgressProvider.future);
  final tradition = ref.watch(learnTraditionProvider);
  final allIds = LearnContent.allLessonIds(tradition);
  if (allIds.isEmpty) return 0.0;
  return repo.completedCount(allIds) / allIds.length;
});

/// Completed count for a specific section.
final sectionProgressProvider =
    FutureProvider.family<int, String>((ref, sectionId) async {
  final repo = await ref.watch(learnProgressProvider.future);
  final sections = ref.watch(learnSectionsProvider);
  final section = sections.where((s) => s.id == sectionId).firstOrNull;
  if (section == null) return 0;
  return repo.completedCount(section.lessons.map((l) => l.id).toList());
});

/// Status for a single lesson.
final lessonStatusProvider =
    FutureProvider.family<LessonStatus, String>((ref, lessonId) async {
  final repo = await ref.watch(learnProgressProvider.future);
  return repo.getStatus(lessonId);
});

/// Notifier to mark lessons complete (triggers rebuilds).
final markLessonCompleteProvider =
    FutureProvider.family<void, String>((ref, lessonId) async {
  final repo = await ref.watch(learnProgressProvider.future);
  await repo.markCompleted(lessonId);
  // Invalidate dependent providers.
  ref.invalidate(learnOverallProgressProvider);
  ref.invalidate(lessonStatusProvider(lessonId));
});
