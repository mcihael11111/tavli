import '../variant/variant_rules.dart';

/// Maps a side's pip to the opponent's pip for the same physical point
/// (matrix §1). Only pips 1..24 map; 0 (off) and 25 (bar) have no point.
class Geometry {
  final Direction direction;
  const Geometry(this.direction);

  static const opposing = Geometry(Direction.opposing);
  static const same = Geometry(Direction.same);

  static Geometry of(Direction d) => d == Direction.opposing ? opposing : same;

  /// Opponent's pip for the physical point at my [pip] (1..24).
  int toOpponent(int pip) {
    assert(pip >= 1 && pip <= 24, 'pip $pip has no physical point');
    if (direction == Direction.opposing) return 25 - pip;
    return pip > 12 ? pip - 12 : pip + 12;
  }
}
