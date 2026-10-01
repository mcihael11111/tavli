import '../play/step.dart';

/// Per-turn state read by the step validators (design spec §4.2).
///
/// Immutable, with value equality, so the play generator can share the
/// continuation of equal (position, context) pairs. Advance it only through
/// `StepValidators.next`, which knows which fields the variant uses.
final class TurnContext {
  /// Checkers that have left the head (pip 24) this turn (D18).
  final int headDepartures;

  /// Whether this is the moving side's first turn of the game (D18).
  final bool firstTurn;

  /// Bit p set => I hit an opposing checker on my home pip p (1..6) this
  /// turn (D4). Only recorded for variants with the D4 rule.
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

  /// A copy with [diceOfTurn] replaced.
  TurnContext withDice(List<int> dice) => TurnContext(
        headDepartures: headDepartures,
        firstTurn: firstTurn,
        homeHitMask: homeHitMask,
        diceOfTurn: dice,
      );

  /// Engine-internal: callers advance the context with
  /// `StepValidators.next`, the only entry point that knows the variant.
  ///
  /// The context after [a]. [fromHead] says whether the step was a head
  /// departure under the variant's head rule (D18); [homeHit] whether it
  /// hit under the D4 rule, which records the hit when [a] landed on a home
  /// pip (1..6). Returns `this` when nothing changes.
  TurnContext afterStep(
    AppliedStep a, {
    required bool fromHead,
    required bool homeHit,
  }) {
    final to = a.step.to;
    final hitMask = homeHit && to >= 1 && to <= 6 ? 1 << to : 0;
    if (!fromHead && homeHitMask & hitMask == hitMask) return this;
    return TurnContext(
      headDepartures: headDepartures + (fromHead ? 1 : 0),
      firstTurn: firstTurn,
      homeHitMask: homeHitMask | hitMask,
      diceOfTurn: diceOfTurn,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TurnContext ||
        other.headDepartures != headDepartures ||
        other.firstTurn != firstTurn ||
        other.homeHitMask != homeHitMask ||
        other.diceOfTurn.length != diceOfTurn.length) {
      return false;
    }
    for (var i = 0; i < diceOfTurn.length; i++) {
      if (other.diceOfTurn[i] != diceOfTurn[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        headDepartures,
        firstTurn,
        homeHitMask,
        Object.hashAll(diceOfTurn),
      );

  @override
  String toString() => 'TurnContext(head: $headDepartures, first: $firstTurn, '
      'homeHits: 0x${homeHitMask.toRadixString(16)}, dice: $diceOfTurn)';
}
