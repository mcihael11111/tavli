import '../variant/variant_rules.dart';
import 'geometry.dart';
import 'side.dart';

/// Read-only board queries shared by [Position] and [MutablePosition], so
/// rules code can be written once against either.
///
/// Pips are player-relative: 0 = borne off, 25 = bar, home = 1..6.
abstract interface class BoardView {
  Direction get direction;
  Geometry get geometry;

  /// Checkers of [s] on its own [pip] (0..25). Throws [RangeError] otherwise.
  int count(Side s, int pip);

  /// Whether the checker of [s] on its own [pip] is pinned.
  bool isPinned(Side s, int pip);

  /// Bit p set => the checker of [s] on its pip p is pinned (p in 1..24).
  int pinnedMask(Side s);

  int onBar(Side s);
  int borneOff(Side s);

  /// Sum of pip * count over pips 1..25 (the bar counts 25).
  int pipCount(Side s);

  /// G5: no checker of [s] on pips 7..25 (pinned checkers count as home).
  bool allHome(Side s);

  /// Checkers not yet borne off (board + bar).
  int checkersOnBoard(Side s);

  /// The side holding the physical point at [me]'s [myPip] (1..24), or null
  /// if empty. For a pinned pair this is the pinner. Throws [RangeError]
  /// outside 1..24.
  Side? controller(Side me, int myPip);
}
