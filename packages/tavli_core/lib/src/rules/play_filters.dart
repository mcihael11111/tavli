import '../board/position.dart';
import '../board/side.dart';
import '../variant/variant_rules.dart';

/// A candidate play as the play filters see it.
abstract interface class PlayCandidate {
  /// The position after the play.
  Position get finalPosition;

  /// Pips wasted by bear-offs: the sum over bear-off steps of
  /// `die - from` (D5).
  int get waste;
}

/// Play-level rules that run after G4 (design spec §4.4 step 4). Each
/// filter removes plays only while at least one play survives.
final class PlayFilters {
  PlayFilters(this.rules);

  final VariantRules rules;

  /// The plays of [s] in [plays] that survive every filter, in order.
  List<C> apply<C extends PlayCandidate>(List<C> plays, Side s) => plays;
}
