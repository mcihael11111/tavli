import 'package:flutter/material.dart';
import '../../../tutorial/presentation/mini_board_painter.dart';
import '../../../game/domain/engine/variants/game_variant.dart';
import '../../../../core/constants/tradition.dart';

/// A single lesson in the Learn to Play module.
class Lesson {
  final String id;
  final String title;
  final String? nativeTitle;
  final MechanicFamily? mechanicFamily;
  final Tradition? tradition;
  final GameVariant? variant;
  final IconData icon;
  final String botDialogue;
  final MiniBoardPainter? diagram;
  final String? setup;
  final List<String> coreMechanic;
  final List<String> specialRules;
  final List<String> scoring;
  final List<String> strategyTips;
  final List<String> uniquePoints;

  const Lesson({
    required this.id,
    required this.title,
    this.nativeTitle,
    this.mechanicFamily,
    this.tradition,
    this.variant,
    required this.icon,
    required this.botDialogue,
    this.diagram,
    this.setup,
    this.coreMechanic = const [],
    this.specialRules = const [],
    this.scoring = const [],
    this.strategyTips = const [],
    this.uniquePoints = const [],
  });
}

/// A group of related lessons.
class LessonSection {
  final String id;
  final String title;
  final LessonSectionType type;
  final List<Lesson> lessons;
  final String? prerequisiteSectionId;
  final Tradition? tradition;

  const LessonSection({
    required this.id,
    required this.title,
    required this.type,
    required this.lessons,
    this.prerequisiteSectionId,
    this.tradition,
  });
}

enum LessonSectionType { foundation, tradition, discovery, deepDive }
