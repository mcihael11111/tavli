import '../../../core/constants/tradition.dart';
import '../data/models/lesson.dart';
import 'foundation_lessons.dart';
import 'tradition_lessons.dart';

/// Assembles all lesson sections for the Learn to Play module.
class LearnContent {
  /// All sections for a player with the given tradition.
  /// Order: Foundation → Player's Tradition → Other Traditions.
  static List<LessonSection> sectionsForTradition(Tradition playerTradition) {
    final sections = <LessonSection>[
      foundationSection,
      sectionForTradition(playerTradition),
    ];

    // Other traditions as discovery sections.
    for (final t in Tradition.values) {
      if (t == playerTradition) continue;
      final section = sectionForTradition(t);
      sections.add(LessonSection(
        id: section.id,
        title: section.title,
        type: LessonSectionType.discovery,
        tradition: t,
        lessons: section.lessons,
      ));
    }

    return sections;
  }

  /// All lesson IDs across all sections.
  static List<String> allLessonIds(Tradition playerTradition) {
    return sectionsForTradition(playerTradition)
        .expand((s) => s.lessons)
        .map((l) => l.id)
        .toList();
  }

  /// Get a flat list of all lessons for a given tradition's sections.
  static List<Lesson> allLessons(Tradition playerTradition) {
    return sectionsForTradition(playerTradition)
        .expand((s) => s.lessons)
        .toList();
  }

  /// Find a lesson by ID across all sections.
  static Lesson? findLesson(String lessonId, Tradition playerTradition) {
    for (final section in sectionsForTradition(playerTradition)) {
      for (final lesson in section.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }

  /// Find which section a lesson belongs to.
  static LessonSection? findSection(String lessonId, Tradition playerTradition) {
    for (final section in sectionsForTradition(playerTradition)) {
      for (final lesson in section.lessons) {
        if (lesson.id == lessonId) return section;
      }
    }
    return null;
  }
}
