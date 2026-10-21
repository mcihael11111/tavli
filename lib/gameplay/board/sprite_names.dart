/// Asset keys and atlas frame names for the game board (design §5.5).
///
/// Produced by `tool/assets/build_game_assets.dart`; the atlas test checks
/// that every name listed here has a frame.
library;

/// Checker colour.
enum CheckerTone { light, dark }

/// Checker sprite: [normal] and [selected] discs, the [shadow] drawn
/// beneath, and the on-edge [vertical] sliver for the bear-off tray.
enum CheckerFrame { normal, selected, shadow, vertical }

abstract final class SpriteNames {
  static const _dir = 'assets/images/game';

  /// Board sets with art. Every set shares the board template (one
  /// `BoardCalibration`) and the one checker atlas (the three sets'
  /// checker PNGs are byte-identical).
  static const boardSets = [1, 2, 3];

  /// The board image of [set] (1200 px wide WebP).
  static String board(int set) =>
      '$_dir/board_set${boardSets.contains(set) ? set : 1}.webp';

  /// The table (scaffold) background, 1600 × 1000 WebP.
  static const table = '$_dir/table.webp';

  static const checkerAtlasImage = '$_dir/checkers.webp';
  static const checkerAtlasData = '$_dir/checkers.json';
  static const diceAtlasImage = '$_dir/dice.webp';
  static const diceAtlasData = '$_dir/dice.json';

  /// The checker atlas data for board [set]: one atlas for every set.
  static String checkerAtlasFor(int set) => checkerAtlasData;

  static String checker(CheckerTone tone, CheckerFrame frame) =>
      '${tone.name}_${frame.name}';

  static String die(int face) => 'die_$face';
  static String dieShadow(int face) => 'die_${face}_shadow';

  static const cubeValues = [2, 4, 8, 16, 32, 64];
  static String cube(int value) => 'cube_$value';
  static String cubeShadow(int value) => 'cube_${value}_shadow';

  /// Every frame the checker atlas must hold.
  static final List<String> checkerFrames = [
    for (final t in CheckerTone.values)
      for (final f in CheckerFrame.values) checker(t, f),
  ];

  /// Every frame the dice atlas must hold.
  static final List<String> diceFrames = [
    for (var face = 1; face <= 6; face++) ...[die(face), dieShadow(face)],
    for (final v in cubeValues) ...[cube(v), cubeShadow(v)],
  ];
}
