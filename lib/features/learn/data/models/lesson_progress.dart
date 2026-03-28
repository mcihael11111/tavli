/// Tracks completion state for a single lesson.
class LessonProgress {
  final String lessonId;
  final LessonStatus status;
  final DateTime? completedAt;

  const LessonProgress({
    required this.lessonId,
    this.status = LessonStatus.notStarted,
    this.completedAt,
  });

  LessonProgress copyWith({
    LessonStatus? status,
    DateTime? completedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum LessonStatus { notStarted, inProgress, completed }
