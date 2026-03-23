import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../../game/data/models/game_result.dart';

/// Types of challenges players can complete.
enum ChallengeType {
  /// Win N games total this week.
  winGames,

  /// Win N games by gammon or backgammon.
  winByGammon,

  /// Win N games in a row (streak).
  winStreak,

  /// Win a game on a specific difficulty.
  winOnDifficulty,

  /// Play N games total.
  playGames,

  /// Bear off all checkers in under N moves.
  fastBearOff,

  /// Win without getting any checkers hit.
  flawlessWin,
}

/// A single challenge instance.
class Challenge {
  final String id;
  final String title;
  final String titleGreek;
  final String description;
  final ChallengeType type;
  final int target;
  final int rewardCoins;
  final Map<String, dynamic> params;

  const Challenge({
    required this.id,
    required this.title,
    required this.titleGreek,
    required this.description,
    required this.type,
    required this.target,
    required this.rewardCoins,
    this.params = const {},
  });
}

/// Player's progress on a challenge.
class ChallengeProgress {
  final String challengeId;
  int current;
  final int target;
  bool completed;
  bool rewardClaimed;

  ChallengeProgress({
    required this.challengeId,
    required this.current,
    required this.target,
    this.completed = false,
    this.rewardClaimed = false,
  });

  double get fraction => (current / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': challengeId,
        'cur': current,
        'tgt': target,
        'done': completed,
        'claimed': rewardClaimed,
      };

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      challengeId: json['id'] as String,
      current: json['cur'] as int,
      target: json['tgt'] as int,
      completed: json['done'] as bool? ?? false,
      rewardClaimed: json['claimed'] as bool? ?? false,
    );
  }
}

/// Challenge templates that get rotated weekly.
abstract final class ChallengeTemplates {
  static const List<Challenge> pool = [
    Challenge(
      id: 'win_5', title: 'Winner', titleGreek: 'Νικητής',
      description: 'Win 5 games this week.',
      type: ChallengeType.winGames, target: 5, rewardCoins: 50,
    ),
    Challenge(
      id: 'win_10', title: 'Dominant', titleGreek: 'Κυρίαρχος',
      description: 'Win 10 games this week.',
      type: ChallengeType.winGames, target: 10, rewardCoins: 100,
    ),
    Challenge(
      id: 'gammon_3', title: 'Gammon Hunter', titleGreek: 'Κυνηγός Γκάμον',
      description: 'Win 3 games by gammon or backgammon.',
      type: ChallengeType.winByGammon, target: 3, rewardCoins: 75,
    ),
    Challenge(
      id: 'streak_3', title: 'Hot Streak', titleGreek: 'Καυτό Σερί',
      description: 'Win 3 games in a row.',
      type: ChallengeType.winStreak, target: 3, rewardCoins: 60,
    ),
    Challenge(
      id: 'streak_5', title: 'Unstoppable', titleGreek: 'Ασταμάτητος',
      description: 'Win 5 games in a row.',
      type: ChallengeType.winStreak, target: 5, rewardCoins: 120,
    ),
    Challenge(
      id: 'play_15', title: 'Dedicated', titleGreek: 'Αφοσιωμένος',
      description: 'Play 15 games this week.',
      type: ChallengeType.playGames, target: 15, rewardCoins: 40,
    ),
    Challenge(
      id: 'play_25', title: 'Kafeneio Regular', titleGreek: 'Θαμώνας',
      description: 'Play 25 games this week.',
      type: ChallengeType.playGames, target: 25, rewardCoins: 80,
    ),
    Challenge(
      id: 'win_hard', title: 'Challenger', titleGreek: 'Προκλητής',
      description: 'Win a game on Hard difficulty.',
      type: ChallengeType.winOnDifficulty, target: 1, rewardCoins: 60,
      params: {'difficulty': 'hard'},
    ),
    Challenge(
      id: 'win_pappous', title: 'Legend Seeker', titleGreek: 'Αναζητητής Θρύλου',
      description: 'Beat Παππούς this week.',
      type: ChallengeType.winOnDifficulty, target: 1, rewardCoins: 100,
      params: {'difficulty': 'pappous'},
    ),
    Challenge(
      id: 'flawless', title: 'Untouched', titleGreek: 'Ανέγγιχτος',
      description: 'Win a game without getting any checkers hit.',
      type: ChallengeType.flawlessWin, target: 1, rewardCoins: 80,
    ),
  ];
}

/// Manages weekly challenges — rotation, progress tracking, rewards.
class ChallengeService {
  static const _activeKey = 'tavli_active_challenges';
  static const _progressKey = 'tavli_challenge_progress';
  static const _weekKey = 'tavli_challenge_week';
  static const _streakKey = 'tavli_challenge_streak';
  static const _challengesPerWeek = 3;

  static ChallengeService? _instance;
  final SharedPreferences _prefs;

  List<Challenge> _activeChallenges = [];
  List<ChallengeProgress> _progress = [];
  int _currentStreak = 0;

  ChallengeService._(this._prefs);

  static Future<ChallengeService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = ChallengeService._(prefs);
    _instance!._loadOrRotate();
    return _instance!;
  }

  static ChallengeService get instance {
    if (_instance == null) throw StateError('ChallengeService not initialized.');
    return _instance!;
  }

  List<Challenge> get activeChallenges => List.unmodifiable(_activeChallenges);
  List<ChallengeProgress> get progress => List.unmodifiable(_progress);
  int get currentStreak => _currentStreak;

  /// Get the ISO week number for a given date.
  int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  void _loadOrRotate() {
    final savedWeek = _prefs.getInt(_weekKey) ?? 0;
    final currentWeek = _weekNumber(DateTime.now());
    _currentStreak = _prefs.getInt(_streakKey) ?? 0;

    if (savedWeek != currentWeek) {
      _rotateChallenges(currentWeek);
    } else {
      _loadExisting();
    }
  }

  void _loadExisting() {
    final activeIds = _prefs.getStringList(_activeKey) ?? [];
    _activeChallenges = activeIds
        .map((id) {
          try {
            return ChallengeTemplates.pool.firstWhere((c) => c.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Challenge>()
        .toList();

    final progressRaw = _prefs.getString(_progressKey);
    if (progressRaw != null) {
      final list = jsonDecode(progressRaw) as List;
      _progress = list
          .map((e) => ChallengeProgress.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  void _rotateChallenges(int weekNumber) {
    // Deterministic but varied selection based on week number.
    final rng = Random(weekNumber * 7919); // prime seed for variety
    final shuffled = List<Challenge>.from(ChallengeTemplates.pool)
      ..shuffle(rng);
    _activeChallenges = shuffled.take(_challengesPerWeek).toList();

    _progress = _activeChallenges
        .map((c) => ChallengeProgress(
              challengeId: c.id,
              current: 0,
              target: c.target,
            ))
        .toList();

    _prefs.setInt(_weekKey, weekNumber);
    _prefs.setStringList(
        _activeKey, _activeChallenges.map((c) => c.id).toList());
    _saveProgress();
  }

  /// Update challenge progress after a game completes.
  ///
  /// Call this from the game completion handler with the game result,
  /// difficulty name, and whether the player was hit during the game.
  List<Challenge> updateProgress({
    required bool playerWon,
    required GameResultType resultType,
    required String difficultyName,
    bool wasHitDuringGame = true,
  }) {
    final newlyCompleted = <Challenge>[];

    if (playerWon) _currentStreak++;
    if (!playerWon) _currentStreak = 0;
    _prefs.setInt(_streakKey, _currentStreak);

    for (int i = 0; i < _activeChallenges.length; i++) {
      final challenge = _activeChallenges[i];
      final prog = _progress[i];

      if (prog.completed) continue;

      bool shouldIncrement = false;

      switch (challenge.type) {
        case ChallengeType.winGames:
          shouldIncrement = playerWon;
          break;
        case ChallengeType.winByGammon:
          shouldIncrement = playerWon &&
              (resultType == GameResultType.gammon ||
                  resultType == GameResultType.backgammon);
          break;
        case ChallengeType.winStreak:
          // Streak: set current to streak count, not increment
          if (playerWon) {
            prog.current = _currentStreak;
          } else {
            prog.current = 0;
          }
          if (prog.current >= prog.target) {
            prog.completed = true;
            newlyCompleted.add(challenge);
          }
          continue; // skip the increment logic below
        case ChallengeType.winOnDifficulty:
          shouldIncrement = playerWon &&
              difficultyName == challenge.params['difficulty'];
          break;
        case ChallengeType.playGames:
          shouldIncrement = true; // any game counts
          break;
        case ChallengeType.fastBearOff:
          // Would need move count data — skip for now
          break;
        case ChallengeType.flawlessWin:
          shouldIncrement = playerWon && !wasHitDuringGame;
          break;
      }

      if (shouldIncrement) {
        prog.current++;
        if (prog.current >= prog.target) {
          prog.completed = true;
          newlyCompleted.add(challenge);
        }
      }
    }

    _saveProgress();
    return newlyCompleted;
  }

  /// Claim the coin reward for a completed challenge.
  bool claimReward(String challengeId) {
    final idx = _progress.indexWhere((p) => p.challengeId == challengeId);
    if (idx < 0) return false;
    final prog = _progress[idx];
    if (!prog.completed || prog.rewardClaimed) return false;
    prog.rewardClaimed = true;
    _saveProgress();
    return true;
  }

  ChallengeProgress? progressFor(String challengeId) {
    try {
      return _progress.firstWhere((p) => p.challengeId == challengeId);
    } catch (_) {
      return null;
    }
  }

  void _saveProgress() {
    _prefs.setString(
      _progressKey,
      jsonEncode(_progress.map((p) => p.toJson()).toList()),
    );
  }
}
