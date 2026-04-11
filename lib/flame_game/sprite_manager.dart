import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Centralized sprite loading and caching for game assets.
///
/// Returns `null` for sets that don't have sprite assets yet,
/// allowing components to fall back to procedural Canvas rendering.
class SpriteManager {
  final Images _images = Flame.images;

  // Cached sprites keyed by asset path.
  final Map<String, Sprite> _cache = {};

  /// Board sprite asset paths per set index.
  static const _boardPaths = <int, String>{
    1: 'boards/set1_board.png',
  };

  /// Board shadow sprite asset paths per set index.
  static const _boardShadowPaths = <int, String>{
    1: 'boards/set1_board_shadow.png',
  };

  /// Checker sprite asset paths per set index.
  /// Key: '$setIndex_$type_$state' e.g. '1_light_normal'
  static String _checkerPath(int setIndex, String type, String state) =>
      'checkers/set${setIndex}_${type}_$state.png';

  /// Dice sprite asset paths per set index.
  static String _dicePath(int setIndex, int value) =>
      'dice/set${setIndex}_die_${value}_active.png';

  /// Whether a given set has sprite assets available.
  static const _availableSets = {1};

  bool hasSprites(int setIndex) => _availableSets.contains(setIndex);

  /// Load and cache a single sprite. Returns null if the asset doesn't exist.
  Future<Sprite?> _loadSprite(String path) async {
    if (_cache.containsKey(path)) return _cache[path];
    try {
      final image = await _images.load(path);
      final sprite = Sprite(image);
      _cache[path] = sprite;
      return sprite;
    } catch (e) {
      debugPrint('SpriteManager: failed to load $path — $e');
      return null;
    }
  }

  /// Load the board sprite for a set. Returns null if no sprite assets exist.
  Future<Sprite?> loadBoardSprite(int setIndex) async {
    final path = _boardPaths[setIndex];
    if (path == null) return null;
    return _loadSprite(path);
  }

  /// Load the board shadow sprite for a set.
  Future<Sprite?> loadBoardShadowSprite(int setIndex) async {
    final path = _boardShadowPaths[setIndex];
    if (path == null) return null;
    return _loadSprite(path);
  }

  /// Load all 4 checker sprites for a set (light/dark x normal/selected).
  /// Returns null if the set has no sprite assets.
  Future<CheckerSprites?> loadCheckerSprites(int setIndex) async {
    if (!hasSprites(setIndex)) return null;

    final lightNormal = await _loadSprite(_checkerPath(setIndex, 'light', 'normal'));
    final darkNormal = await _loadSprite(_checkerPath(setIndex, 'dark', 'normal'));
    final lightSelected = await _loadSprite(_checkerPath(setIndex, 'light', 'selected'));
    final darkSelected = await _loadSprite(_checkerPath(setIndex, 'dark', 'selected'));

    if (lightNormal == null || darkNormal == null) return null;

    return CheckerSprites(
      lightNormal: lightNormal,
      darkNormal: darkNormal,
      lightSelected: lightSelected,
      darkSelected: darkSelected,
    );
  }

  /// Load all 6 dice face sprites for a set.
  /// Returns null if the set has no sprite assets.
  Future<DiceSprites?> loadDiceSprites(int setIndex) async {
    if (!hasSprites(setIndex)) return null;

    final faces = <int, Sprite>{};
    for (int value = 1; value <= 6; value++) {
      final sprite = await _loadSprite(_dicePath(setIndex, value));
      if (sprite == null) return null;
      faces[value] = sprite;
    }

    return DiceSprites(activeFaces: faces);
  }
}

/// Holds all checker sprites for one set.
class CheckerSprites {
  final Sprite lightNormal;
  final Sprite darkNormal;
  final Sprite? lightSelected;
  final Sprite? darkSelected;

  const CheckerSprites({
    required this.lightNormal,
    required this.darkNormal,
    this.lightSelected,
    this.darkSelected,
  });

  /// Get the appropriate sprite for a player and selection state.
  Sprite getSprite(int player, bool isSelected) {
    if (player == 1) {
      return isSelected ? (lightSelected ?? lightNormal) : lightNormal;
    } else {
      return isSelected ? (darkSelected ?? darkNormal) : darkNormal;
    }
  }
}

/// Holds all dice sprites for one set.
class DiceSprites {
  final Map<int, Sprite> activeFaces;

  const DiceSprites({required this.activeFaces});

  /// Get the sprite for a given die value (1-6).
  Sprite? getFace(int value) => activeFaces[value];
}
