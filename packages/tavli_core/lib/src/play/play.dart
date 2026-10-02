/// A complete legal play: where it ends and one way to get there.
library;

import '../board/position.dart';
import '../util/list_eq.dart';
import 'step.dart';

/// One legal play of a roll: its [finalPosition] and one canonical legal
/// step sequence reaching it (the first found by the tree's DFS).
///
/// Bots choose finals; submitting a play needs its steps.
final class Play {
  /// The position after the play.
  final Position finalPosition;

  /// One legal path from the tree's start to [finalPosition]. Unmodifiable
  /// when built by `PlayTree.plays` or `CascadeWalker`.
  final List<Step> steps;

  const Play(this.finalPosition, this.steps);

  @override
  bool operator ==(Object other) =>
      other is Play &&
      other.finalPosition == finalPosition &&
      listEq(other.steps, steps);

  @override
  int get hashCode => Object.hash(finalPosition, Object.hashAll(steps));

  @override
  String toString() => 'Play($steps)';
}
