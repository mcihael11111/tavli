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
  /// All boards share the same 2102 × 2374 baked-bearoff art template (only
  /// colors differ), so the layout math in [BoardLayout] applies uniformly.
  static const _boardPaths = <int, String>{
    1: 'boards/set1_board.png', // Mahogany & olive (baked bear-off)
    2: 'boards/set2_board.png', // Walnut & navy (baked bear-off)
    3: 'boards/set3_board.png', // Teal & maple (baked bear-off)
  };

  /// Boards whose PNG includes top + bottom bear-off strips fused into the art.
  /// When in this set, the renderer must use [BoardLayout.useBakedBearOff].
  static const _bakedBearOffSets = {1, 2, 3};

  bool hasBakedBearOff(int setIndex) => _bakedBearOffSets.contains(setIndex);

  /// Checker sprite asset paths per set index.
  /// Key: '$setIndex_$type_$state' e.g. '1_light_normal'
  static String _checkerPath(int setIndex, String type, String state) =>
      'checkers/set${setIndex}_${type}_$state.png';

  /// Dice sprite asset paths per set index.
  static String _dicePath(int setIndex, int value) =>
      'dice/set${setIndex}_die_${value}_active.png';

  /// Set indices that ship full sprite art (board + checkers + shadows).
  /// Sets above this fall back to set 1's sprites — keeps the shop's set 4/5
  /// items playable without crashes if their assets are not in this build.
  static const _availableSets = {1, 2, 3};

  /// Set indices that have a full *dice* sprite set. Currently only set 1 —
  /// sets 2 & 3 reuse set 1's dice PNGs via [_normalizeDiceSet]. Re-export
  /// dice art per set later and add the indices here.
  static const _diceSpriteSets = {1};

  bool hasSprites(int setIndex) => _availableSets.contains(setIndex);

  /// Normalize an out-of-range set index to a supported one. The shop UI
  /// permits set 4 & 5 entries, so without this, selecting them would
  /// silently fall through to procedural rendering and look broken.
  int _normalizeSet(int setIndex) =>
      _availableSets.contains(setIndex) ? setIndex : 1;

  /// Dice sprites only exist for set 1 today. Any other index reuses set 1.
  int _normalizeDiceSet(int setIndex) =>
      _diceSpriteSets.contains(setIndex) ? setIndex : 1;

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

  /// Load the board sprite for a set. Out-of-range indices fall back to set 1
  /// so set 4/5 (selectable in the shop) don't render as procedural.
  Future<Sprite?> loadBoardSprite(int setIndex) async {
    final path = _boardPaths[_normalizeSet(setIndex)];
    if (path == null) return null;
    return _loadSprite(path);
  }

  /// Board shadow is baked into the new board PNGs — no separate sprite to
  /// load. Kept as an explicit no-op so the BoardComponent contract is stable.
  Future<Sprite?> loadBoardShadowSprite(int setIndex) async => null;

  /// Load vertical (on-edge) checker sprites for the bear-off tray.
  /// Returns null if the set has no vertical assets — bear-off then falls back
  /// to the regular top-down disc.
  Future<CheckerVerticalSprites?> loadCheckerVerticalSprites(int setIndex) async {
    final s = _normalizeSet(setIndex);
    final light = await _loadSprite('checkers/set${s}_light_vertical.png');
    final dark = await _loadSprite('checkers/set${s}_dark_vertical.png');
    if (light == null || dark == null) return null;
    return CheckerVerticalSprites(light: light, dark: dark);
  }

  /// Load shadow sprites for a set's checkers (drop-shadow baked under each
  /// disc). Returns null if the set has no shadow assets.
  Future<CheckerShadowSprites?> loadCheckerShadowSprites(int setIndex) async {
    final s = _normalizeSet(setIndex);
    final light = await _loadSprite('checkers/set${s}_light_shadow.png');
    final dark = await _loadSprite('checkers/set${s}_dark_shadow.png');
    if (light == null || dark == null) return null;
    return CheckerShadowSprites(light: light, dark: dark);
  }

  /// Load shadow sprites for the active dice set. Sets without bespoke dice
  /// art reuse set 1's shadows.
  Future<DiceShadowSprites?> loadDiceShadowSprites(int setIndex) async {
    final s = _normalizeDiceSet(setIndex);
    final faces = <int, Sprite>{};
    for (int v = 1; v <= 6; v++) {
      final spr = await _loadSprite('dice/set${s}_die_${v}_shadow.png');
      if (spr == null) return null;
      faces[v] = spr;
    }
    return DiceShadowSprites(faces: faces);
  }

  /// Load doubling-cube faces (2/4/8/16/32/64) plus drop shadows.
  Future<DoublingCubeSprites?> loadDoublingCubeSprites() async {
    final faces = <int, Sprite>{};
    final shadows = <int, Sprite>{};
    for (final v in const [2, 4, 8, 16, 32, 64]) {
      final f = await _loadSprite('dice/doubling_cube_$v.png');
      final s = await _loadSprite('dice/doubling_cube_${v}_shadow.png');
      if (f == null) return null;
      faces[v] = f;
      if (s != null) shadows[v] = s;
    }
    return DoublingCubeSprites(faces: faces, shadows: shadows);
  }

  /// Load all 4 checker sprites for a set (light/dark x normal/selected).
  /// Out-of-range indices fall back to set 1.
  Future<CheckerSprites?> loadCheckerSprites(int setIndex) async {
    final s = _normalizeSet(setIndex);

    final lightNormal = await _loadSprite(_checkerPath(s, 'light', 'normal'));
    final darkNormal = await _loadSprite(_checkerPath(s, 'dark', 'normal'));
    final lightSelected = await _loadSprite(_checkerPath(s, 'light', 'selected'));
    final darkSelected = await _loadSprite(_checkerPath(s, 'dark', 'selected'));

    if (lightNormal == null || darkNormal == null) return null;

    return CheckerSprites(
      lightNormal: lightNormal,
      darkNormal: darkNormal,
      lightSelected: lightSelected,
      darkSelected: darkSelected,
    );
  }

  /// Load all 6 dice face sprites for a set. Sets without dice art fall back
  /// to set 1's faces.
  Future<DiceSprites?> loadDiceSprites(int setIndex) async {
    final normalized = _normalizeDiceSet(setIndex);
    if (!hasSprites(normalized)) return null;

    final faces = <int, Sprite>{};
    for (int value = 1; value <= 6; value++) {
      final sprite = await _loadSprite(_dicePath(normalized, value));
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

/// On-edge (side-profile) checker sprites used inside the bear-off tray, so
/// borne-off checkers read as a real stacked pile of edges, not floating
/// discs. Source PNGs are 77 × 202 — narrow vertical slivers.
class CheckerVerticalSprites {
  final Sprite light;
  final Sprite dark;
  const CheckerVerticalSprites({required this.light, required this.dark});

  Sprite forPlayer(int player) => player == 1 ? light : dark;
}

/// Drop-shadow sprites that sit underneath each checker.
class CheckerShadowSprites {
  final Sprite light;
  final Sprite dark;
  const CheckerShadowSprites({required this.light, required this.dark});

  Sprite forPlayer(int player) => player == 1 ? light : dark;
}

/// Drop-shadow sprites that sit underneath each die face.
class DiceShadowSprites {
  final Map<int, Sprite> faces;
  const DiceShadowSprites({required this.faces});

  Sprite? forFace(int value) => faces[value];
}

/// Doubling-cube faces (2/4/8/16/32/64) plus matching shadow sprites.
class DoublingCubeSprites {
  final Map<int, Sprite> faces;
  final Map<int, Sprite> shadows;
  const DoublingCubeSprites({required this.faces, required this.shadows});

  Sprite? forValue(int value) => faces[value];
  Sprite? shadowForValue(int value) => shadows[value];
}
