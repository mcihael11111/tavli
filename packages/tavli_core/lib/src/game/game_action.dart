/// Player and system inputs to the reducer (design spec §5.2).
library;

import '../board/side.dart';
import '../play/step.dart';

/// An input to `reduce`. Dice always arrive as data.
///
/// JSON: an object with a `"type"` key plus the action's fields, e.g.
/// `{"type": "rollDice", "d1": 5, "d2": 3}`. Only [Resign] and
/// [ClockTimeout] carry a `"side"`; who sent an action is not part of it
/// (see `actorOf` and `reduce(..., by:)`).
sealed class GameAction {
  const GameAction();

  Map<String, Object?> toJson();

  /// Parses [toJson] output from any decoded JSON value. Throws only
  /// [FormatException] (also for a non-object). Unknown extra keys are
  /// ignored. Values are checked for type only; the reducer judges
  /// legality (e.g. dice 1..6).
  static GameAction fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('GameAction: not a JSON object', json);
    }
    final j = json;
    int die(String key) {
      final v = j[key];
      if (v is! int) throw FormatException('GameAction: $key must be int', j);
      return v;
    }

    Side side() {
      final v = j['side'];
      if (v is! String || !Side.values.any((s) => s.name == v)) {
        throw FormatException('GameAction: bad side', j);
      }
      return Side.values.byName(v);
    }

    switch (j['type']) {
      case 'rollOpening':
        return RollOpening(die('dieOne'), die('dieTwo'));
      case 'rollDice':
        return RollDice(die('d1'), die('d2'));
      case 'step':
        final s = j['step'];
        if (s is! Map<String, Object?>) {
          throw FormatException('GameAction: step must be an object', j);
        }
        return StepAction(Step.fromJson(s));
      case 'undoStep':
        return const UndoStep();
      case 'commitPlay':
        return const CommitPlay();
      case 'offerDouble':
        return const OfferDouble();
      case 'take':
        return const Take();
      case 'drop':
        return const Drop();
      case 'resign':
        return Resign(side());
      case 'clockTimeout':
        return ClockTimeout(side());
      default:
        throw FormatException('GameAction: unknown type', j);
    }
  }
}

/// The opening roll (G7): [dieOne] is side one's die, [dieTwo] side two's.
final class RollOpening extends GameAction {
  final int dieOne, dieTwo;
  const RollOpening(this.dieOne, this.dieTwo);

  @override
  Map<String, Object?> toJson() =>
      {'type': 'rollOpening', 'dieOne': dieOne, 'dieTwo': dieTwo};

  @override
  bool operator ==(Object other) =>
      other is RollOpening && other.dieOne == dieOne && other.dieTwo == dieTwo;

  @override
  int get hashCode => Object.hash('rollOpening', dieOne, dieTwo);

  @override
  String toString() => 'RollOpening($dieOne, $dieTwo)';
}

/// The side to move rolls [d1] and [d2].
final class RollDice extends GameAction {
  final int d1, d2;
  const RollDice(this.d1, this.d2);

  @override
  Map<String, Object?> toJson() => {'type': 'rollDice', 'd1': d1, 'd2': d2};

  @override
  bool operator ==(Object other) =>
      other is RollDice && other.d1 == d1 && other.d2 == d2;

  @override
  int get hashCode => Object.hash('rollDice', d1, d2);

  @override
  String toString() => 'RollDice($d1, $d2)';
}

/// The side to move plays one checker step.
final class StepAction extends GameAction {
  final Step step;
  const StepAction(this.step);

  @override
  Map<String, Object?> toJson() => {'type': 'step', 'step': step.toJson()};

  @override
  bool operator ==(Object other) => other is StepAction && other.step == step;

  @override
  int get hashCode => Object.hash('step', step);

  @override
  String toString() => 'StepAction($step)';
}

/// Takes back the last step of the current play.
final class UndoStep extends _NoFields {
  const UndoStep() : super('undoStep');
}

/// Ends the turn with the steps taken (they must form a full play).
final class CommitPlay extends _NoFields {
  const CommitPlay() : super('commitPlay');
}

/// The side to move offers a double.
final class OfferDouble extends _NoFields {
  const OfferDouble() : super('offerDouble');
}

/// The opponent of the doubling side accepts.
final class Take extends _NoFields {
  const Take() : super('take');
}

/// The opponent of the doubling side declines and loses.
final class Drop extends _NoFields {
  const Drop() : super('drop');
}

/// [side] resigns the game.
final class Resign extends _SideAction {
  const Resign(Side side) : super('resign', side);
}

/// [side] ran out of time.
final class ClockTimeout extends _SideAction {
  const ClockTimeout(Side side) : super('clockTimeout', side);
}

/// An action with no fields; equal to any instance of the same type.
sealed class _NoFields extends GameAction {
  const _NoFields(this._type);
  final String _type;

  @override
  Map<String, Object?> toJson() => {'type': _type};

  @override
  bool operator ==(Object other) => other is _NoFields && other._type == _type;

  @override
  int get hashCode => _type.hashCode;

  @override
  String toString() => '$_type()';
}

/// An action naming a [side].
sealed class _SideAction extends GameAction {
  const _SideAction(this._type, this.side);
  final String _type;
  final Side side;

  @override
  Map<String, Object?> toJson() => {'type': _type, 'side': side.toJson()};

  @override
  bool operator ==(Object other) =>
      other is _SideAction && other._type == _type && other.side == side;

  @override
  int get hashCode => Object.hash(_type, side);

  @override
  String toString() => '$_type(${side.name})';
}
