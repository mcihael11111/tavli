/// A single checker step and the record of its effects.
library;

/// One checker moving one die: own pip [from] (25 = bar) to own pip [to]
/// (0 = borne off), using [die].
///
/// The die is part of a step's identity, so overshoot bear-offs with
/// different dice stay distinct.
final class Step {
  final int from, to, die;
  const Step(this.from, this.to, this.die)
      : assert(
            to == (from - die < 0 ? 0 : from - die), 'to = max(0, from - die)');

  /// `{"from": int, "to": int, "die": int}`.
  Map<String, Object?> toJson() => {'from': from, 'to': to, 'die': die};

  /// Parses [toJson] output. Throws only [FormatException]: the die must be
  /// 1..6, [from] 1..25, and [to] must equal `max(0, from - die)`.
  static Step fromJson(Map<String, Object?> j) {
    final from = j['from'], to = j['to'], die = j['die'];
    if (from is! int || to is! int || die is! int) {
      throw FormatException('Step: from, to, die must be ints', j);
    }
    if (die < 1 || die > 6 || from < 1 || from > 25) {
      throw FormatException('Step: die or from out of range', j);
    }
    final target = from - die;
    if (to != (target < 0 ? 0 : target)) {
      throw FormatException('Step: to must be max(0, from - die)', j);
    }
    return Step(from, to, die);
  }

  @override
  bool operator ==(Object other) =>
      other is Step && other.from == from && other.to == to && other.die == die;

  @override
  int get hashCode => (from << 8) | (to << 3) | die;

  @override
  String toString() => 'Step($from->$to/$die)';
}

/// A step as applied to a position, with what it did, so `StepRules.undo`
/// can reverse it exactly.
final class AppliedStep {
  final Step step;

  /// A lone opposing checker on [Step.to] was sent to its bar.
  final bool hit;

  /// A lone opposing checker on [Step.to] became pinned.
  final bool pinned;

  /// The last checker left [Step.from], releasing the opposing checker
  /// pinned under it.
  final bool unpinned;

  /// The step bore the checker off ([Step.to] == 0).
  final bool bearOff;

  const AppliedStep(
    this.step, {
    this.hit = false,
    this.pinned = false,
    this.unpinned = false,
    this.bearOff = false,
  });

  @override
  String toString() => 'AppliedStep($step'
      '${hit ? ' hit' : ''}${pinned ? ' pinned' : ''}'
      '${unpinned ? ' unpinned' : ''}${bearOff ? ' off' : ''})';
}
