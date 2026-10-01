/// Test builders for positions in player-relative pips (plan "Test notation").
library;

import 'package:tavli_core/tavli_core.dart';

/// Builds an opposing-direction [Position]; omitted checkers are borne off.
///
/// [offOne] / [offTwo], when given, must match the derived borne-off count.
Position pos({
  required Map<int, int> one,
  required Map<int, int> two,
  int? offOne,
  int? offTwo,
  int barOne = 0,
  int barTwo = 0,
  Set<int> pinnedOne = const {},
  Set<int> pinnedTwo = const {},
  Direction direction = Direction.opposing,
}) {
  final p = Position.fromPips(
    one: one,
    two: two,
    barOne: barOne,
    barTwo: barTwo,
    pinnedOne: pinnedOne,
    pinnedTwo: pinnedTwo,
    direction: direction,
  );
  if (offOne != null && p.borneOff(Side.one) != offOne) {
    throw ArgumentError.value(
        offOne, 'offOne', 'derived ${p.borneOff(Side.one)}');
  }
  if (offTwo != null && p.borneOff(Side.two) != offTwo) {
    throw ArgumentError.value(
        offTwo, 'offTwo', 'derived ${p.borneOff(Side.two)}');
  }
  return p;
}

/// As [pos], with [Direction.same] (running games).
Position posSame({
  required Map<int, int> one,
  required Map<int, int> two,
  int? offOne,
  int? offTwo,
  Set<int> pinnedOne = const {},
  Set<int> pinnedTwo = const {},
}) =>
    pos(
      one: one,
      two: two,
      offOne: offOne,
      offTwo: offTwo,
      pinnedOne: pinnedOne,
      pinnedTwo: pinnedTwo,
      direction: Direction.same,
    );
