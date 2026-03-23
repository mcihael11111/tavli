import 'dart:math';

import '../difficulty/difficulty_level.dart';
import '../personality/bot_personality.dart';
import '../personality/personality_dialogue_database.dart';
import 'dialogue_event.dart';

/// Manages bot dialogue with cooldown, deduplication, and event triggers.
class DialogueSystem {
  final Random _rng;

  /// Minimum time between any two dialogue lines.
  static const _globalCooldown = Duration(seconds: 6);

  /// Minimum time before repeating the same line.
  static const _repeatCooldown = Duration(minutes: 5);

  DateTime? _lastDialogueTime;
  final Map<String, DateTime> _recentLines = {};
  String? _currentLine;

  DialogueSystem({Random? rng}) : _rng = rng ?? Random();

  /// Current displayed dialogue line.
  String? get currentLine => _currentLine;

  /// Try to trigger dialogue for [event] at [difficulty] using [personality].
  /// Returns the line if one was selected, null if on cooldown or no match.
  String? trigger(
    DialogueEvent event,
    DifficultyLevel difficulty, {
    BotPersonality personality = BotPersonality.mikhail,
  }) {
    final now = DateTime.now();

    // Check global cooldown.
    if (_lastDialogueTime != null &&
        now.difference(_lastDialogueTime!) < _globalCooldown) {
      return null;
    }

    // Find matching lines for this event and difficulty.
    final lines = PersonalityDialogueDatabase.linesFor(personality);
    final candidates = lines.where((line) {
      if (line.event != event) return false;
      if (difficulty.index < line.minLevel.index) return false;
      if (difficulty.index > line.maxLevel.index) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // Filter out recently used lines.
    final available = candidates.where((line) {
      final lastUsed = _recentLines[line.text];
      if (lastUsed == null) return true;
      return now.difference(lastUsed) >= _repeatCooldown;
    }).toList();

    if (available.isEmpty) {
      // All lines on cooldown — clear oldest and retry.
      _recentLines.clear();
      return trigger(event, difficulty, personality: personality);
    }

    // Pick a random line from available.
    final selected = available[_rng.nextInt(available.length)];

    _currentLine = selected.text;
    _lastDialogueTime = now;
    _recentLines[selected.text] = now;

    return _currentLine;
  }

  /// Force a specific line (for scripted moments like game start).
  void setLine(String line) {
    _currentLine = line;
    _lastDialogueTime = DateTime.now();
  }

  /// Clear the current dialogue.
  void clear() {
    _currentLine = null;
  }

  /// Reset all cooldowns (e.g., for a new game).
  void reset() {
    _currentLine = null;
    _lastDialogueTime = null;
    _recentLines.clear();
  }
}
