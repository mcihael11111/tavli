import '../play/step.dart';

/// Per-turn state read by the step validators (design spec §4.2).
///
/// Immutable; [afterStep] returns the context for the next step.
final class TurnContext {
  /// Checkers that have left the head (pip 24) this turn (D18).
  final int headDepartures;

  /// Whether this is the moving side's first turn of the game (D18).
  final bool firstTurn;

  /// Bit p set => I hit an opposing checker on my home pip p (1..6) this
  /// turn (D4).
  final int homeHitMask;

  /// The dice of this turn as rolled, e.g. `[5, 3]`, `[6, 6]` or
  /// `[6, 6, 6, 6]`.
  final List<int> diceOfTurn;

  const TurnContext({
    this.headDepartures = 0,
    this.firstTurn = false,
    this.homeHitMask = 0,
    this.diceOfTurn = const [],
  });

  /// Whether the turn's dice are a double (D18).
  bool get isDouble => diceOfTurn.length >= 2 && diceOfTurn[0] == diceOfTurn[1];

  /// The context after [a]. [fromHead] says whether the step was a head
  /// departure under the variant's head rule (the caller knows the rules).
  ///
  /// Returns `this` when nothing changes.
  TurnContext afterStep(AppliedStep a, {required bool fromHead}) {
    final to = a.step.to;
    final hitMask = a.hit && to >= 1 && to <= 6 ? 1 << to : 0;
    if (!fromHead && homeHitMask & hitMask == hitMask) return this;
    return TurnContext(
      headDepartures: headDepartures + (fromHead ? 1 : 0),
      firstTurn: firstTurn,
      homeHitMask: homeHitMask | hitMask,
      diceOfTurn: diceOfTurn,
    );
  }

  @override
  String toString() => 'TurnContext(head: $headDepartures, first: $firstTurn, '
      'homeHits: 0x${homeHitMask.toRadixString(16)}, dice: $diceOfTurn)';
}
