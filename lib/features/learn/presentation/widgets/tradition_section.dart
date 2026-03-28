import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/tradition.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_progress.dart';
import 'lesson_list_item.dart';

/// An expandable section for a tradition's variants in the Learn Hub.
class TraditionSectionWidget extends StatefulWidget {
  final LessonSection section;
  final Tradition tradition;
  final int completedCount;
  final Map<String, LessonStatus> lessonStatuses;
  final bool initiallyExpanded;
  final ValueChanged<Lesson> onLessonTap;

  const TraditionSectionWidget({
    super.key,
    required this.section,
    required this.tradition,
    required this.completedCount,
    required this.lessonStatuses,
    this.initiallyExpanded = false,
    required this.onLessonTap,
  });

  @override
  State<TraditionSectionWidget> createState() => _TraditionSectionWidgetState();
}

class _TraditionSectionWidgetState extends State<TraditionSectionWidget>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.section.lessons.length;
    final completed = widget.completedCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header — tappable to expand/collapse.
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.md,
              vertical: TavliSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: TavliColors.primary,
              borderRadius: BorderRadius.circular(TavliRadius.lg),
            ),
            child: Row(
              children: [
                Text(
                  widget.tradition.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: TavliSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.tradition.displayName} — ${widget.tradition.regionLabel}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: TavliTheme.serifFamily,
                          fontWeight: FontWeight.w600,
                          color: TavliColors.light,
                        ),
                      ),
                      Text(
                        '$total variants \u2022 $completed complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: TavliColors.light.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: TavliColors.light.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable lesson list.
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                for (int i = 0; i < widget.section.lessons.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  LessonListItem(
                    lesson: widget.section.lessons[i],
                    status: widget.lessonStatuses[widget.section.lessons[i].id] ??
                        LessonStatus.notStarted,
                    onTap: () => widget.onLessonTap(widget.section.lessons[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
