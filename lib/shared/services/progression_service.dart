import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ai/difficulty/difficulty_level.dart';
import '../../features/game/data/models/game_result.dart';

/// Stats for a single difficulty level.
class DifficultyStats {
  final int wins;
  final int losses;
  final int currentStreak;
  final int bestStreak;
  final int gammons;
  final int backgammons;

  const DifficultyStats({
    this.wins = 0,
    this.losses = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.gammons = 0,
    this.backgammons = 0,
  });

  int get totalGames => wins + losses;
  double get winRate => totalGames == 0 ? 0.0 : wins / totalGames;

  DifficultyStats recordWin(GameResultType type) {
    final newStreak = currentStreak + 1;
    return DifficultyStats(
      wins: wins + 1,
      losses: losses,
      currentStreak: newStreak,
      bestStreak: newStreak > bestStreak ? newStreak : bestStreak,
      gammons: gammons + (type == GameResultType.gammon ? 1 : 0),
      backgammons: backgammons + (type == GameResultType.backgammon ? 1 : 0),
    );
  }

  DifficultyStats recordLoss() {
    return DifficultyStats(
      wins: wins,
      losses: losses + 1,
      currentStreak: 0,
      bestStreak: bestStreak,
      gammons: gammons,
      backgammons: backgammons,
    );
  }

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'losses': losses,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'gammons': gammons,
        'backgammons': backgammons,
      };

  factory DifficultyStats.fromJson(Map<String, dynamic> json) {
    return DifficultyStats(
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      gammons: json['gammons'] as int? ?? 0,
      backgammons: json['backgammons'] as int? ?? 0,
    );
  }
}

/// Tracks player progression: wins, losses, streaks, and difficulty unlocks.
class ProgressionService {
  static const _storageKey = 'tavli_progression';
  static ProgressionService? _instance;

  final SharedPreferences _prefs;
  final Map<DifficultyLevel, DifficultyStats> _stats = {};

  ProgressionService._(this._prefs) {
    _load();
  }

  /// Initialize the singleton. Call once at app startup.
  static Future<ProgressionService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = ProgressionService._(prefs);
    return _instance!;
  }

  /// Get the initialized instance. Throws if not yet initialized.
  static ProgressionService get instance {
    if (_instance == null) {
      throw StateError('ProgressionService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Get stats for a difficulty level.
  DifficultyStats statsFor(DifficultyLevel level) {
    return _stats[level] ?? const DifficultyStats();
  }

  /// Record a completed game.
  void recordGame(DifficultyLevel level, GameResult result) {
    final current = statsFor(level);
    final playerWon = result.winner == 1;

    _stats[level] = playerWon
        ? current.recordWin(result.type)
        : current.recordLoss();

    _save();
  }

  /// Whether a difficulty level is unlocked.
  bool isUnlocked(DifficultyLevel level) {
    return switch (level) {
      DifficultyLevel.easy => true,
      DifficultyLevel.easyWithHelp => true,
      DifficultyLevel.medium => _checkUnlock(
          prerequisite: DifficultyLevel.easy,
          winsRequired: 3,
          streakAlternative: null,
        ),
      DifficultyLevel.hard => _checkUnlock(
          prerequisite: DifficultyLevel.medium,
          winsRequired: 5,
          streakAlternative: 3,
        ),
      DifficultyLevel.pappous => _checkUnlock(
          prerequisite: DifficultyLevel.hard,
          winsRequired: 5,
          streakAlternative: 3,
        ),
    };
  }

  bool _checkUnlock({
    required DifficultyLevel prerequisite,
    required int winsRequired,
    int? streakAlternative,
  }) {
    final stats = statsFor(prerequisite);
    if (stats.wins >= winsRequired) return true;
    if (streakAlternative != null && stats.bestStreak >= streakAlternative) return true;
    return false;
  }

  /// Overall stats across all difficulties.
  DifficultyStats get overallStats {
    int wins = 0, losses = 0, gammons = 0, backgammons = 0, bestStreak = 0;
    for (final s in _stats.values) {
      wins += s.wins;
      losses += s.losses;
      gammons += s.gammons;
      backgammons += s.backgammons;
      if (s.bestStreak > bestStreak) bestStreak = s.bestStreak;
    }
    return DifficultyStats(
      wins: wins,
      losses: losses,
      bestStreak: bestStreak,
      gammons: gammons,
      backgammons: backgammons,
    );
  }

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;

    final Map<String, dynamic> json = jsonDecode(raw);
    for (final level in DifficultyLevel.values) {
      final data = json[level.name];
      if (data != null) {
        _stats[level] = DifficultyStats.fromJson(data as Map<String, dynamic>);
      }
    }
  }

  void _save() {
    final json = <String, dynamic>{};
    for (final entry in _stats.entries) {
      json[entry.key.name] = entry.value.toJson();
    }
    _prefs.setString(_storageKey, jsonEncode(json));
  }
}
