import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/tradition.dart';
import '../../../../shared/services/settings_service.dart';
import '../../../../shared/widgets/gradient_scaffold.dart';
import '../../data/models/lesson.dart';
import '../../domain/learn_content.dart';
import '../providers/learn_providers.dart';
import '../widgets/bot_dialogue_box.dart';
import '../widgets/rule_section.dart';

/// Full-screen lesson viewer with structured content and prev/next navigation.
class LessonDetailScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final int lessonIndex;

  const LessonDetailScreen({
    super.key,
    required this.sectionId,
    required this.lessonIndex,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  late Tradition _tradition;
  late List<LessonSection> _sections;
  late LessonSection _section;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _tradition = SettingsService.instance.tradition;
    _sections = LearnContent.sectionsForTradition(_tradition);
    _section = _sections.firstWhere((s) => s.id == widget.sectionId);
    _currentIndex = widget.lessonIndex.clamp(0, _section.lessons.length - 1);
  }

  Lesson get _lesson => _section.lessons[_currentIndex];
  bool get _isFirst => _currentIndex == 0;
  bool get _isLast => _currentIndex == _section.lessons.length - 1;

  void _next() {
    if (_isLast) {
      _markComplete();
      context.pop();
    } else {
      _markComplete();
      setState(() => _currentIndex++);
    }
  }

  void _previous() {
    if (!_isFirst) setState(() => _currentIndex--);
  }

  Future<void> _markComplete() async {
    final repo = await ref.read(learnProgressProvider.future);
    await repo.markCompleted(_lesson.id);
  }

  IconData _mechanicIcon(MechanicFamily? family) => switch (family) {
        MechanicFamily.hitting => Icons.gavel,
        MechanicFamily.pinning => Icons.push_pin,
        MechanicFamily.running => Icons.directions_run,
        null => _lesson.icon,
      };

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final total = _section.lessons.length;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TavliColors.light),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / $total',
          style: const TextStyle(
            color: TavliColors.light,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar.
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor: TavliColors.primary.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation(TavliColors.light),
            minHeight: 3,
          ),

          // Scrollable content.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: TavliSpacing.sm),

                  // Lesson header — icon + title + native name.
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: TavliColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mechanicIcon(lesson.mechanicFamily),
                          color: TavliColors.light,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: TavliSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.nativeTitle != null
                                  ? '${lesson.title} (${lesson.nativeTitle})'
                                  : lesson.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontFamily: TavliTheme.serifFamily,
                                fontWeight: FontWeight.w600,
                                color: TavliColors.light,
                              ),
                            ),
                            if (lesson.mechanicFamily != null)
                              Text(
                                lesson.mechanicFamily!.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: TavliColors.light.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: TavliSpacing.lg),

                  // Bot dialogue.
                  BotDialogueBox(
                    text: lesson.botDialogue,
                    tradition: lesson.tradition,
                  ),

                  const SizedBox(height: TavliSpacing.lg),

                  // Board diagram (if present).
                  if (lesson.diagram != null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(TavliRadius.sm),
                        border: Border.all(
                          color: TavliColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(TavliRadius.sm),
                        child: CustomPaint(
                          painter: lesson.diagram!,
                          size: const Size(double.infinity, 200),
                        ),
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.lg),
                  ],

                  // Setup.
                  if (lesson.setup != null) ...[
                    RuleSection(
                      title: 'Setup',
                      items: [lesson.setup!],
                    ),
                    const SizedBox(height: TavliSpacing.md),
                  ],

                  // Core mechanic.
                  RuleSection(
                    title: 'Core Mechanic',
                    items: lesson.coreMechanic,
                  ),
                  if (lesson.coreMechanic.isNotEmpty)
                    const SizedBox(height: TavliSpacing.md),

                  // Special rules.
                  RuleSection(
                    title: 'Special Rules',
                    items: lesson.specialRules,
                  ),
                  if (lesson.specialRules.isNotEmpty)
                    const SizedBox(height: TavliSpacing.md),

                  // Scoring.
                  RuleSection(
                    title: 'Scoring',
                    items: lesson.scoring,
                  ),
                  if (lesson.scoring.isNotEmpty)
                    const SizedBox(height: TavliSpacing.md),

                  // Strategy tips.
                  RuleSection(
                    title: 'Strategy Tips',
                    items: lesson.strategyTips,
                  ),
                  if (lesson.strategyTips.isNotEmpty)
                    const SizedBox(height: TavliSpacing.md),

                  // What makes it unique.
                  RuleSection(
                    title: 'What Makes It Unique',
                    items: lesson.uniquePoints,
                  ),

                  const SizedBox(height: TavliSpacing.lg),
                ],
              ),
            ),
          ),

          // Bottom navigation.
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        TavliSpacing.md,
        TavliSpacing.md,
        TavliSpacing.md,
        TavliSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: TavliColors.primary.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          if (!_isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: _previous,
                child: const Text('Previous'),
              ),
            ),
          if (!_isFirst) const SizedBox(width: TavliSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_isLast ? 'Done' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
