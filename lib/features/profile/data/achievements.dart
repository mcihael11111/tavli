import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/progression_service.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../game/data/models/game_result.dart';

/// Achievement categories per spec.
enum AchievementCategory { beginner, skill, social, mastery }

/// A single achievement definition.
class Achievement {
  final String id;
  final String name;
  final String nameGreek;
  final String description;
  final AchievementCategory category;
  final String icon;
  final int rewardCoins;

  const Achievement({
    required this.id,
    required this.name,
    required this.nameGreek,
    required this.description,
    required this.category,
    this.icon = '🏆',
    this.rewardCoins = 0,
  });
}

/// All achievements in the game.
abstract final class Achievements {
  static const List<Achievement> all = [
    // ── Beginner ────────────────────────────────────────────
    Achievement(
      id: 'first_game',
      name: 'First Roll', nameGreek: 'Πρώτο Ζάρι',
      description: 'Complete your first game.',
      category: AchievementCategory.beginner, icon: '🎲',
      rewardCoins: 10,
    ),
    Achievement(
      id: 'first_win',
      name: 'First Victory', nameGreek: 'Πρώτη Νίκη',
      description: 'Win your first game.',
      category: AchievementCategory.beginner, icon: '⭐',
      rewardCoins: 20,
    ),
    Achievement(
      id: 'tutorial_complete',
      name: 'Student', nameGreek: 'Μαθητής',
      description: 'Complete all tutorial lessons.',
      category: AchievementCategory.beginner, icon: '📚',
      rewardCoins: 15,
    ),
    Achievement(
      id: 'ten_games',
      name: 'Regular', nameGreek: 'Θαμώνας',
      description: 'Play 10 games.',
      category: AchievementCategory.beginner, icon: '☕',
      rewardCoins: 25,
    ),

    // ── Skill ───────────────────────────────────────────────
    Achievement(
      id: 'win_gammon',
      name: 'Gammon!', nameGreek: 'Γκάμον!',
      description: 'Win a game by gammon.',
      category: AchievementCategory.skill, icon: '💪',
      rewardCoins: 20,
    ),
    Achievement(
      id: 'win_backgammon',
      name: 'Backgammon!', nameGreek: 'Πόρτες Κλειστές',
      description: 'Win a game by backgammon.',
      category: AchievementCategory.skill, icon: '🔥',
      rewardCoins: 30,
    ),
    Achievement(
      id: 'three_streak',
      name: 'Hat Trick', nameGreek: 'Τρεις στη Σειρά',
      description: 'Win 3 games in a row.',
      category: AchievementCategory.skill, icon: '🎩',
      rewardCoins: 25,
    ),
    Achievement(
      id: 'five_streak',
      name: 'On Fire', nameGreek: 'Φωτιά!',
      description: 'Win 5 games in a row.',
      category: AchievementCategory.skill, icon: '🔥',
      rewardCoins: 40,
    ),
    Achievement(
      id: 'beat_medium',
      name: 'Contender', nameGreek: 'Αντίπαλος',
      description: 'Beat the bot on Medium.',
      category: AchievementCategory.skill, icon: '⚔️',
      rewardCoins: 25,
    ),
    Achievement(
      id: 'beat_hard',
      name: 'Warrior', nameGreek: 'Πολεμιστής',
      description: 'Beat the bot on Hard.',
      category: AchievementCategory.skill, icon: '🛡️',
      rewardCoins: 35,
    ),
    Achievement(
      id: 'beat_pappous',
      name: 'Legend Slayer', nameGreek: 'Θρυλοκτόνος',
      description: 'Beat Παππούς.',
      category: AchievementCategory.skill, icon: '👑',
      rewardCoins: 50,
    ),
    Achievement(
      id: 'double_win',
      name: 'Bold Move', nameGreek: 'Τολμηρή Κίνηση',
      description: 'Win a game after accepting a double.',
      category: AchievementCategory.skill, icon: '🎯',
      rewardCoins: 20,
    ),

    // ── Social ──────────────────────────────────────────────
    Achievement(
      id: 'first_online',
      name: 'Connected', nameGreek: 'Συνδεδεμένος',
      description: 'Play your first online game.',
      category: AchievementCategory.social, icon: '🌐',
      rewardCoins: 15,
    ),
    Achievement(
      id: 'invite_friend',
      name: 'Host', nameGreek: 'Οικοδεσπότης',
      description: 'Invite a friend to play.',
      category: AchievementCategory.social, icon: '📨',
      rewardCoins: 15,
    ),
    Achievement(
      id: 'ten_online',
      name: 'Social Butterfly', nameGreek: 'Κοινωνικός',
      description: 'Play 10 online games.',
      category: AchievementCategory.social, icon: '🦋',
      rewardCoins: 30,
    ),

    // ── Mastery ─────────────────────────────────────────────
    Achievement(
      id: 'fifty_wins',
      name: 'Veteran', nameGreek: 'Βετεράνος',
      description: 'Win 50 games total.',
      category: AchievementCategory.mastery, icon: '🎖️',
      rewardCoins: 50,
    ),
    Achievement(
      id: 'hundred_games',
      name: 'Kafeneio Regular', nameGreek: 'Θαμώνας Καφενείου',
      description: 'Play 100 games.',
      category: AchievementCategory.mastery, icon: '☕',
      rewardCoins: 50,
    ),
    Achievement(
      id: 'all_boards',
      name: 'Collector', nameGreek: 'Συλλέκτης',
      description: 'Play at least one game on each board set.',
      category: AchievementCategory.mastery, icon: '🎨',
      rewardCoins: 40,
    ),
    Achievement(
      id: 'all_difficulties',
      name: 'Complete Journey', nameGreek: 'Πλήρες Ταξίδι',
      description: 'Win at least one game on every difficulty.',
      category: AchievementCategory.mastery, icon: '🗺️',
      rewardCoins: 50,
    ),
  ];

  static Achievement? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Tracks which achievements the player has unlocked.
class AchievementService {
  static const _key = 'tavli_achievements';
  static AchievementService? _instance;

  final SharedPreferences _prefs;
  final Set<String> _unlocked = {};

  AchievementService._(this._prefs) {
    _load();
  }

  static Future<AchievementService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = AchievementService._(prefs);
    return _instance!;
  }

  static AchievementService get instance {
    if (_instance == null) {
      throw StateError('AchievementService not initialized.');
    }
    return _instance!;
  }

  bool isUnlocked(String achievementId) => _unlocked.contains(achievementId);

  /// Unlock an achievement. Returns true if it was newly unlocked.
  bool unlock(String achievementId) {
    if (_unlocked.contains(achievementId)) return false;
    _unlocked.add(achievementId);
    _save();
    return true;
  }

  /// Check all achievement conditions and unlock any that are met.
  /// Returns the list of newly unlocked achievements.
  List<Achievement> checkAndUnlock({
    required GameResult result,
    required DifficultyLevel difficulty,
  }) {
    final newly = <Achievement>[];
    final prog = ProgressionService.instance;
    final overall = prog.overallStats;

    // Helper to try unlocking.
    void tryUnlock(String id) {
      if (unlock(id)) {
        final a = Achievements.byId(id);
        if (a != null) newly.add(a);
      }
    }

    // ── Beginner ──
    if (overall.totalGames >= 1) tryUnlock('first_game');
    if (overall.wins >= 1) tryUnlock('first_win');
    if (overall.totalGames >= 10) tryUnlock('ten_games');

    // ── Skill ──
    if (overall.gammons >= 1) tryUnlock('win_gammon');
    if (overall.backgammons >= 1) tryUnlock('win_backgammon');

    // Streaks — check all difficulties.
    for (final level in DifficultyLevel.values) {
      final s = prog.statsFor(level);
      if (s.bestStreak >= 3) tryUnlock('three_streak');
      if (s.bestStreak >= 5) tryUnlock('five_streak');
    }

    // Difficulty-specific wins.
    if (result.winner == 1) {
      if (difficulty == DifficultyLevel.medium) tryUnlock('beat_medium');
      if (difficulty == DifficultyLevel.hard) tryUnlock('beat_hard');
      if (difficulty == DifficultyLevel.pappous) tryUnlock('beat_pappous');
      if (result.cubeValue > 1) tryUnlock('double_win');
    }

    // ── Mastery ──
    if (overall.wins >= 50) tryUnlock('fifty_wins');
    if (overall.totalGames >= 100) tryUnlock('hundred_games');

    // All difficulties won.
    bool allDifficultiesWon = true;
    for (final level in DifficultyLevel.values) {
      if (prog.statsFor(level).wins == 0) {
        allDifficultiesWon = false;
        break;
      }
    }
    if (allDifficultiesWon) tryUnlock('all_difficulties');

    return newly;
  }

  List<Achievement> get unlockedAchievements =>
      Achievements.all.where((a) => _unlocked.contains(a.id)).toList();

  List<Achievement> get lockedAchievements =>
      Achievements.all.where((a) => !_unlocked.contains(a.id)).toList();

  int get unlockedCount => _unlocked.length;
  int get totalCount => Achievements.all.length;

  void _load() {
    final raw = _prefs.getStringList(_key);
    if (raw != null) _unlocked.addAll(raw);
  }

  void _save() {
    _prefs.setStringList(_key, _unlocked.toList());
  }
}
