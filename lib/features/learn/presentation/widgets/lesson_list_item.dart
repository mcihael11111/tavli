import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/colors.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_progress.dart';

/// A tappable card representing a lesson in the Learn Hub.
class LessonListItem extends StatefulWidget {
  final Lesson lesson;
  final LessonStatus status;
  final bool locked;
  final VoidCallback? onTap;

  const LessonListItem({
    super.key,
    required this.lesson,
    required this.status,
    this.locked = false,
    this.onTap,
  });

  @override
  State<LessonListItem> createState() => _LessonListItemState();
}

class _LessonListItemState extends State<LessonListItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.status == LessonStatus.completed;
    final isLocked = widget.locked;

    return Semantics(
      button: !isLocked,
      label: '${widget.lesson.title}${isCompleted ? ', completed' : ''}${isLocked ? ', locked' : ''}',
      child: GestureDetector(
        onTap: isLocked ? null : widget.onTap,
        onTapDown: isLocked ? null : (_) => setState(() => _pressed = true),
        onTapUp: isLocked ? null : (_) => setState(() => _pressed = false),
        onTapCancel: isLocked ? null : () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeIn,
          transform: _pressed
              ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: TavliSpacing.md,
            vertical: TavliSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? TavliColors.primaryActive
                : TavliColors.primary,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
          ),
          child: Row(
            children: [
              // Status icon.
              _StatusIcon(
                status: widget.status,
                locked: isLocked,
              ),
              const SizedBox(width: TavliSpacing.sm),

              // Lesson info.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.nativeTitle != null
                          ? '${widget.lesson.title} (${widget.lesson.nativeTitle})'
                          : widget.lesson.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: TavliTheme.serifFamily,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? TavliColors.light.withValues(alpha: 0.5)
                            : TavliColors.light,
                      ),
                    ),
                    if (widget.lesson.mechanicFamily != null)
                      Text(
                        widget.lesson.mechanicFamily!.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked
                              ? TavliColors.light.withValues(alpha: 0.4)
                              : TavliColors.light.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),

              // Chevron.
              if (!isLocked)
                Icon(
                  Icons.chevron_right,
                  color: TavliColors.light.withValues(alpha: 0.6),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final LessonStatus status;
  final bool locked;

  const _StatusIcon({required this.status, required this.locked});

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(
        Icons.lock_outline,
        size: 20,
        color: TavliColors.light.withValues(alpha: 0.4),
      );
    }

    return switch (status) {
      LessonStatus.completed => const Icon(
          Icons.check_circle,
          size: 20,
          color: TavliColors.light,
        ),
      LessonStatus.inProgress => Icon(
          Icons.circle,
          size: 10,
          color: TavliColors.light.withValues(alpha: 0.8),
        ),
      LessonStatus.notStarted => Icon(
          Icons.circle_outlined,
          size: 20,
          color: TavliColors.light.withValues(alpha: 0.5),
        ),
    };
  }
}
