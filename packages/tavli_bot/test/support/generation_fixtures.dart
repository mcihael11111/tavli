/// The per-variant worst generation fixtures of
/// `packages/tavli_core/benchmark/bench_fixtures.dart` (`generationFixtures`,
/// copied: a package must not import another's benchmark dir): the
/// position x roll x side with the most legal finals per variant.
library;

import 'dart:convert';

import 'package:tavli_core/tavli_core.dart';

/// A worst normal-roll fixture.
typedef GenerationFixture = ({
  Variant variant,
  Position position,
  Side side,
  List<int> dice,
  int finals,
});

GenerationFixture _f(Variant v, String json, Side s, List<int> d, int n) => (
      variant: v,
      position: Position.fromJson(jsonDecode(json) as Map<String, Object?>),
      side: s,
      dice: d,
      finals: n,
    );

final generationFixtures = [
  _f(
      Variant.portes,
      '{"direction":"opposing","one":[0,0,0,3,0,0,0,0,2,0,2,0,1,0,0,1,0,1,1,0,1,2,1,0,0,0],"two":[0,11,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.one,
      [2, 2, 2, 2],
      610),
  _f(
      Variant.plakoto,
      '{"direction":"opposing","one":[0,0,0,1,1,0,0,0,2,0,1,0,2,0,1,1,1,1,1,0,0,1,0,0,2,0],"two":[0,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,3,0,2,0,0,1,0,0,1,0],"pinnedOne":[],"pinnedTwo":[4,11,13,21]}',
      Side.one,
      [2, 2, 2, 2],
      982),
  _f(
      Variant.fevga,
      '{"direction":"same","one":[0,0,2,0,0,0,0,0,0,6,0,0,0,0,0,4,0,0,0,0,3,0,0,0,0,0],"two":[0,0,2,0,0,0,0,1,0,1,0,0,1,1,0,0,2,2,3,0,1,0,0,1,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      377),
  _f(
      Variant.tavla,
      '{"direction":"opposing","one":[0,9,0,0,0,0,1,0,0,1,0,0,3,1,0,0,0,0,0,0,0,0,0,0,0,0],"two":[0,3,1,1,0,1,0,1,1,0,0,1,0,0,0,2,0,1,0,0,1,1,1,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      675),
  _f(
      Variant.tapa,
      '{"direction":"opposing","one":[0,1,0,1,2,2,0,0,1,1,1,0,0,0,1,1,1,1,0,0,0,1,0,0,1,0],"two":[0,0,2,1,1,0,0,4,0,0,0,1,2,1,0,0,0,0,0,0,1,1,0,0,1,0],"pinnedOne":[21],"pinnedTwo":[11,20,21,24]}',
      Side.one,
      [2, 2, 2, 2],
      479),
  _f(
      Variant.moultezim,
      '{"direction":"same","one":[0,1,2,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0],"two":[0,0,0,1,0,1,1,0,0,1,0,1,0,0,0,0,0,0,3,0,3,2,1,0,1,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [2, 2, 2, 2],
      444),
  _f(
      Variant.gulBara,
      '{"direction":"same","one":[0,5,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0],"two":[0,0,1,1,2,1,0,0,1,1,0,1,0,0,0,0,0,0,2,0,1,0,0,0,4,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      603),
  _f(
      Variant.longNard,
      '{"direction":"same","one":[0,6,0,0,0,4,0,0,1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0],"two":[0,3,1,0,0,1,0,2,0,2,1,2,1,0,0,0,0,0,0,2,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      269),
  _f(
      Variant.shortNard,
      '{"direction":"opposing","one":[0,0,0,1,0,0,3,0,0,0,0,0,0,5,0,1,0,0,0,0,0,0,1,1,3,0],"two":[0,0,0,0,1,2,0,1,2,1,0,0,0,3,0,0,0,1,1,0,0,1,0,1,1,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [2, 2, 2, 2],
      574),
  _f(
      Variant.sheshBesh,
      '{"direction":"opposing","one":[0,2,4,0,4,0,0,0,0,1,0,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0],"two":[0,0,2,2,0,2,1,0,1,1,2,0,0,0,0,0,0,0,1,0,2,0,1,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      459),
  _f(
      Variant.mahbusa,
      '{"direction":"opposing","one":[0,0,1,0,1,0,0,1,0,1,0,1,1,0,1,0,0,0,1,0,1,0,0,0,6,0],"two":[0,0,0,1,0,2,0,0,1,0,0,0,2,0,1,0,0,1,0,0,3,1,0,1,2,0],"pinnedOne":[2,4,11,20],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      749),
  _f(
      Variant.mahbusaArab,
      '{"direction":"opposing","one":[0,0,1,2,2,1,0,1,0,0,0,0,2,1,1,0,0,0,0,0,3,1,0,0,0,0],"two":[0,0,1,0,1,0,0,1,1,1,2,1,1,0,1,1,1,1,0,1,0,0,0,1,0,0],"pinnedOne":[13,14,21],"pinnedTwo":[23]}',
      Side.two,
      [1, 1, 1, 1],
      727),
  _f(
      Variant.tawla31,
      '{"direction":"same","one":[0,1,1,0,2,1,0,0,0,0,0,0,0,7,0,0,0,0,3,0,0,0,0,0,0,0],"two":[0,0,0,2,1,2,0,2,0,1,0,0,1,0,0,1,0,0,0,0,1,1,1,2,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      349),
];
