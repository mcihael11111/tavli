import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/tradition.dart';
import '../../game/domain/engine/variants/game_variant.dart';

/// Tracks cross-cultural play patterns and manages discovery prompts.
///
/// Encourages players to explore variants from other traditions through
/// achievements, weekly spotlights, and contextual suggestions.
class DiscoveryService {
  static const _gamesPlayedPrefix = 'discovery_games_';
  static const _winsPrefix = 'discovery_wins_';
  static const _traditionsTriedKey = 'discovery_traditions_tried';
  static const _lastSpotlightKey = 'discovery_last_spotlight_week';
  static const _discoveryPromptShownKey = 'discovery_prompt_shown';

  static DiscoveryService? _instance;
  final SharedPreferences _prefs;

  DiscoveryService._(this._prefs);

  static Future<DiscoveryService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = DiscoveryService._(prefs);
    return _instance!;
  }

  static DiscoveryService get instance {
    if (_instance == null) {
      throw StateError('DiscoveryService not initialized.');
    }
    return _instance!;
  }

  // ── Game Tracking ──────────────────────────────────────────

  /// Record a game played for a specific variant.
  void recordGame(GameVariant variant, {required bool won}) {
    final gamesKey = '$_gamesPlayedPrefix${variant.name}';
    final current = _prefs.getInt(gamesKey) ?? 0;
    _prefs.setInt(gamesKey, current + 1);

    if (won) {
      final winsKey = '$_winsPrefix${variant.name}';
      final currentWins = _prefs.getInt(winsKey) ?? 0;
      _prefs.setInt(winsKey, currentWins + 1);
    }

    // Track traditions tried.
    final tried = traditionsTried;
    if (!tried.contains(variant.tradition.name)) {
      tried.add(variant.tradition.name);
      _prefs.setStringList(_traditionsTriedKey, tried.toList());
    }
  }

  /// Number of games played for a variant.
  int gamesPlayed(GameVariant variant) =>
      _prefs.getInt('$_gamesPlayedPrefix${variant.name}') ?? 0;

  /// Number of wins for a variant.
  int winsFor(GameVariant variant) =>
      _prefs.getInt('$_winsPrefix${variant.name}') ?? 0;

  /// Total games across all variants of a tradition.
  int gamesInTradition(Tradition tradition) {
    int total = 0;
    for (final v in tradition.variants) {
      total += gamesPlayed(v);
    }
    return total;
  }

  /// Total wins across all variants of a tradition.
  int winsInTradition(Tradition tradition) {
    int total = 0;
    for (final v in tradition.variants) {
      total += winsFor(v);
    }
    return total;
  }

  /// Set of tradition names the player has tried.
  Set<String> get traditionsTried =>
      (_prefs.getStringList(_traditionsTriedKey) ?? []).toSet();

  /// Number of distinct traditions tried.
  int get traditionsTriedCount => traditionsTried.length;

  // ── Discovery Prompts ──────────────────────────────────────

  /// Should we show a "try another tradition" prompt?
  /// True if player has 10+ games in one tradition but hasn't tried others.
  bool shouldShowDiscoveryPrompt(Tradition currentTradition) {
    if (_prefs.getBool(_discoveryPromptShownKey) == true) return false;
    if (traditionsTriedCount >= 2) return false;
    return gamesInTradition(currentTradition) >= 10;
  }

  /// Mark that we showed the discovery prompt.
  void markDiscoveryPromptShown() {
    _prefs.setBool(_discoveryPromptShownKey, true);
  }

  /// Get a suggestion for which tradition to try next.
  Tradition? suggestTradition(Tradition current) {
    final tried = traditionsTried;
    for (final t in Tradition.values) {
      if (t != current && !tried.contains(t.name)) return t;
    }
    return null;
  }

  /// Get a cross-tradition variant suggestion based on mechanic affinity.
  /// "Players who enjoy Plakoto often like Mahbusa."
  String? crossTraditionSuggestion(GameVariant mostPlayed) {
    final mechanic = mostPlayed.mechanicFamily;
    // Find a variant with the same mechanic in a different tradition.
    for (final v in GameVariant.values) {
      if (v.mechanicFamily == mechanic &&
          v.tradition != mostPlayed.tradition &&
          gamesPlayed(v) == 0) {
        return 'Players who enjoy ${mostPlayed.displayName} often like '
            '${v.displayName} (${v.tradition.displayName})';
      }
    }
    return null;
  }

  // ── Weekly Cultural Spotlight ──────────────────────────────

  /// Get the featured tradition for this week.
  /// Rotates weekly, deterministic based on week number.
  Tradition weeklySpotlight() {
    final weekNumber = DateTime.now().difference(
      DateTime(2026, 1, 1),
    ).inDays ~/ 7;
    return Tradition.values[weekNumber % Tradition.values.length];
  }

  /// Whether the weekly spotlight has changed since last seen.
  bool isSpotlightNew() {
    final currentWeek = DateTime.now().difference(
      DateTime(2026, 1, 1),
    ).inDays ~/ 7;
    final lastSeen = _prefs.getInt(_lastSpotlightKey) ?? -1;
    return currentWeek != lastSeen;
  }

  /// Mark the current spotlight as seen.
  void markSpotlightSeen() {
    final currentWeek = DateTime.now().difference(
      DateTime(2026, 1, 1),
    ).inDays ~/ 7;
    _prefs.setInt(_lastSpotlightKey, currentWeek);
  }

  // ── Cross-Cultural Achievements ────────────────────────────

  /// Check which cross-cultural achievements have been newly unlocked.
  List<DiscoveryAchievement> checkAchievements() {
    final unlocked = <DiscoveryAchievement>[];

    for (final a in DiscoveryAchievement.values) {
      final key = 'discovery_achievement_${a.name}';
      if (_prefs.getBool(key) == true) continue; // Already unlocked.
      if (a.isUnlocked(this)) {
        _prefs.setBool(key, true);
        unlocked.add(a);
      }
    }

    return unlocked;
  }

  /// Whether an achievement has been unlocked.
  bool isAchievementUnlocked(DiscoveryAchievement a) =>
      _prefs.getBool('discovery_achievement_${a.name}') ?? false;
}

/// Cross-cultural discovery achievements.
enum DiscoveryAchievement {
  /// Try a variant from a second tradition.
  curious(
    name: 'curious',
    title: 'Curious Traveler',
    description: 'Play a game in a second tradition',
    icon: '\u{1F30D}', // 🌍
    rewardCoins: 50,
  ),

  /// Win a game in 2 different traditions.
  worldTraveler(
    name: 'worldTraveler',
    title: 'World Traveler',
    description: 'Win a game in 2 different traditions',
    icon: '\u{2708}', // ✈
    rewardCoins: 100,
  ),

  /// Win a game in all 4 traditions.
  cosmopolitan(
    name: 'cosmopolitan',
    title: 'Cosmopolitan',
    description: 'Win a game in all 4 traditions',
    icon: '\u{1F3C6}', // 🏆
    rewardCoins: 200,
  ),

  /// Play 10 games in each tradition.
  dedicatedExplorer(
    name: 'dedicatedExplorer',
    title: 'Dedicated Explorer',
    description: 'Play 10 games in each tradition',
    icon: '\u{1F9ED}', // 🧭
    rewardCoins: 300,
  ),

  /// Win 10 games in each tradition.
  masterOfAll(
    name: 'masterOfAll',
    title: 'Master of All',
    description: 'Win 10 games in each tradition',
    icon: '\u{1F451}', // 👑
    rewardCoins: 500,
  ),

  /// Win with every mechanic family.
  mechanicMaster(
    name: 'mechanicMaster',
    title: 'Mechanic Master',
    description: 'Win a hitting, pinning, and running game',
    icon: '\u{2699}', // ⚙
    rewardCoins: 150,
  );

  final String name;
  final String title;
  final String description;
  final String icon;
  final int rewardCoins;

  const DiscoveryAchievement({
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    required this.rewardCoins,
  });

  bool isUnlocked(DiscoveryService service) => switch (this) {
        curious => service.traditionsTriedCount >= 2,
        worldTraveler => _winsInDifferentTraditions(service) >= 2,
        cosmopolitan => _winsInDifferentTraditions(service) >= 4,
        dedicatedExplorer => Tradition.values
            .every((t) => service.gamesInTradition(t) >= 10),
        masterOfAll => Tradition.values
            .every((t) => service.winsInTradition(t) >= 10),
        mechanicMaster => _hasWonEachMechanic(service),
      };

  static int _winsInDifferentTraditions(DiscoveryService service) {
    int count = 0;
    for (final t in Tradition.values) {
      if (service.winsInTradition(t) > 0) count++;
    }
    return count;
  }

  static bool _hasWonEachMechanic(DiscoveryService service) {
    bool hasHitting = false, hasPinning = false, hasRunning = false;
    for (final v in GameVariant.values) {
      if (service.winsFor(v) > 0) {
        switch (v.mechanicFamily) {
          case MechanicFamily.hitting:
            hasHitting = true;
          case MechanicFamily.pinning:
            hasPinning = true;
          case MechanicFamily.running:
            hasRunning = true;
        }
      }
    }
    return hasHitting && hasPinning && hasRunning;
  }
}
