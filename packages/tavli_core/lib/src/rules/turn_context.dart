import '../play/step.dart';

/// Per-turn state read by the step validators (design spec §4.2).
///
/// Immutable, with value equality, so the play generator can share the
/// continuation of equal (position, context) pairs. Advance it only through
/// `StepValidators.next`, which knows which fields the variant uses.
///
/// The constructor is not `const`: [hashCode] is computed once there, as
/// the generator's memo hashes a context at every node.
final class TurnContext {
  /// Checkers that have left the head (pip 24) this turn (D18).
  final int headDepartures;

  /// Whether this is the moving side's first turn of the game (D18).
  final bool firstTurn;

  /// Bit p set => I hit an opposing checker on my home pip p (1..6) this
  /// turn (D4). Only recorded for variants with the D4 rule.
  final int homeHitMask;

  /// The dice of this turn (unmodifiable): as rolled for a normal roll,
  /// e.g. `[5, 3]`, `[6, 6]` or `[6, 6, 6, 6]`; for a Gul Bara cascade,
  /// the queue being played (`generateCascade` writes it here), e.g.
  /// `[4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6]` or a remainder `[5, 6, 6, 6, 6]`.
  final List<int> diceOfTurn;

  @override
  final int hashCode;

  TurnContext({
    int headDepartures = 0,
    bool firstTurn = false,
    int homeHitMask = 0,
    List<int> diceOfTurn = const [],
  }) : this._(
          headDepartures,
          firstTurn,
          homeHitMask,
          List.unmodifiable(diceOfTurn),
          Object.hashAll(diceOfTurn),
        );

  TurnContext._(
    this.headDepartures,
    this.firstTurn,
    this.homeHitMask,
    this.diceOfTurn,
    this._diceHash,
  ) : hashCode = Object.hash(headDepartures, firstTurn, homeHitMask, _diceHash);

  /// Hash of [diceOfTurn], kept so [afterStep] need not rehash the dice.
  final int _diceHash;

  /// Whether the first two entries of [diceOfTurn] are equal: a double
  /// roll (D18). For a cascade queue this reads the queue's head, so it is
  /// only meaningful for normal rolls; no variant combines a head rule
  /// with cascades.
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
    return TurnContext._(
      headDepartures + (fromHead ? 1 : 0),
      firstTurn,
      homeHitMask | hitMask,
      diceOfTurn,
      _diceHash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TurnContext ||
        other.hashCode != hashCode ||
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
  String toString() => 'TurnContext(head: $headDepartures, first: $firstTurn, '
      'homeHits: 0x${homeHitMask.toRadixString(16)}, dice: $diceOfTurn)';
}
