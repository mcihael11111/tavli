import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/tradition.dart';
import '../../../../shared/services/settings_service.dart';
import '../../../../shared/widgets/content_module.dart';
import '../../../../shared/widgets/gradient_scaffold.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_progress.dart';
import '../../domain/learn_content.dart';
import '../../domain/mechanic_comparisons.dart';
import '../providers/learn_providers.dart';
import '../widgets/lesson_list_item.dart';
import '../widgets/progress_overview_card.dart';
import '../widgets/tradition_section.dart';

/// Main hub for the Learn to Play module.
///
/// Shows progress, foundation lessons, player's tradition variants,
/// other traditions (expandable), and mechanic deep dives.
class LearnHubScreen extends ConsumerStatefulWidget {
  final String? initialSection;
  final String? initialLesson;

  const LearnHubScreen({
    super.key,
    this.initialSection,
    this.initialLesson,
  });

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
  late Tradition _tradition;
  Map<String, LessonStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _tradition = SettingsService.instance.tradition;
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final repo = await ref.read(learnProgressProvider.future);
    final allLessons = LearnContent.allLessons(_tradition);
    final map = <String, LessonStatus>{};
    for (final lesson in allLessons) {
      map[lesson.id] = repo.getStatus(lesson.id);
    }
    if (mounted) setState(() => _statuses = map);
  }

  void _openLesson(LessonSection section, int index) {
    context.push('/learn/lesson', extra: {
      'sectionId': section.id,
      'lessonIndex': index,
    });
  }

  void _openComparison(String family) {
    context.push('/learn/compare', extra: {'family': family});
  }

  @override
  Widget build(BuildContext context) {
    final sections = LearnContent.sectionsForTradition(_tradition);
    final allIds = LearnContent.allLessonIds(_tradition);
    final completedCount =
        _statuses.values.where((s) => s == LessonStatus.completed).length;
    final totalCount = allIds.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    // Separate sections by type.
    final foundation =
        sections.where((s) => s.type == LessonSectionType.foundation).first;
    final playerTradition =
        sections.where((s) => s.type == LessonSectionType.tradition).first;
    final discoveries =
        sections.where((s) => s.type == LessonSectionType.discovery).toList();

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TavliColors.light),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Learn to Play',
          style: TextStyle(
            color: TavliColors.light,
            fontFamily: TavliTheme.serifFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadStatuses,
          color: TavliColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: TavliSpacing.md),

                // Progress overview.
                ProgressOverviewCard(
                  progress: progress,
                  completed: completedCount,
                  total: totalCount,
                ),

                const SizedBox(height: TavliSpacing.lg),

                // Foundation section.
                _sectionHeader('Foundations'),
                const SizedBox(height: TavliSpacing.sm),
                _buildFoundationSection(foundation),

                const SizedBox(height: TavliSpacing.lg),

                // Player's tradition section.
                _sectionHeader(
                  '${_tradition.displayName} ${_tradition.flagEmoji}',
                ),
                const SizedBox(height: TavliSpacing.sm),
                _buildTraditionLessons(playerTradition),

                const SizedBox(height: TavliSpacing.lg),

                // Other traditions.
                _sectionHeader('Explore Other Traditions'),
                const SizedBox(height: TavliSpacing.sm),
                for (int i = 0; i < discoveries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  TraditionSectionWidget(
                    section: discoveries[i],
                    tradition: discoveries[i].tradition!,
                    completedCount: _sectionCompletedCount(discoveries[i]),
                    lessonStatuses: _statuses,
                    onLessonTap: (lesson) {
                      final idx = discoveries[i]
                          .lessons
                          .indexWhere((l) => l.id == lesson.id);
                      _openLesson(discoveries[i], idx);
                    },
                  ),
                ],

                const SizedBox(height: TavliSpacing.lg),

                // Mechanic deep dives.
                _sectionHeader('Mechanic Deep Dives'),
                const SizedBox(height: TavliSpacing.sm),
                _buildDeepDives(),

                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontFamily: TavliTheme.serifFamily,
        fontWeight: FontWeight.w600,
        color: TavliColors.light,
      ),
    );
  }

  Widget _buildFoundationSection(LessonSection section) {
    return Column(
      children: [
        for (int i = 0; i < section.lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          LessonListItem(
            lesson: section.lessons[i],
            status: _statuses[section.lessons[i].id] ?? LessonStatus.notStarted,
            onTap: () => _openLesson(section, i),
          ),
        ],
      ],
    );
  }

  Widget _buildTraditionLessons(LessonSection section) {
    return Column(
      children: [
        for (int i = 0; i < section.lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          LessonListItem(
            lesson: section.lessons[i],
            status: _statuses[section.lessons[i].id] ?? LessonStatus.notStarted,
            onTap: () => _openLesson(section, i),
          ),
        ],
      ],
    );
  }

  Widget _buildDeepDives() {
    return Column(
      children: [
        ContentModule(
          icon: Icons.gavel,
          title: 'Hitting Games Compared',
          body: '${hittingComparison.variants.length} variants across traditions',
          trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
          onTap: () => _openComparison('hitting'),
        ),
        const SizedBox(height: TavliSpacing.sm),
        ContentModule(
          icon: Icons.push_pin,
          title: 'Pinning Games Compared',
          body: '${pinningComparison.variants.length} variants across traditions',
          trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
          onTap: () => _openComparison('pinning'),
        ),
        const SizedBox(height: TavliSpacing.sm),
        ContentModule(
          icon: Icons.directions_run,
          title: 'Running Games Compared',
          body: '${runningComparison.variants.length} variants across traditions',
          trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
          onTap: () => _openComparison('running'),
        ),
      ],
    );
  }

  int _sectionCompletedCount(LessonSection section) {
    return section.lessons
        .where((l) => _statuses[l.id] == LessonStatus.completed)
        .length;
  }
}
