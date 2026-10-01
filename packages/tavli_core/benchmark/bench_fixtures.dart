/// Worst-case fixtures for the benchmarks (plan Task 17), found by
/// scanning reachable positions with
/// `dart run --no-enable-asserts benchmark/run_benchmarks.dart --scan`,
/// which prints this list (regenerate it, never hand-edit it):
/// - [generationFixtures]: per variant, the position x roll x side with
///   the most legal finals over 300 positions from random games;
/// - [worstCascade] / [worstFailingCascade]: the slowest Gul Bara
///   cascades (build + walk to a complete node) that reach / cannot reach
///   the end of their queue, over 1500 positions x 2 sides x 6 queues.
library;

import 'package:tavli_core/tavli_core.dart';

import 'bench_suite.dart' show GenerationFixture;

const generationFixtures = [
  GenerationFixture(
      Variant.portes,
      '{"direction":"opposing","one":[0,0,0,3,0,0,0,0,2,0,2,0,1,0,0,1,0,1,1,0,1,2,1,0,0,0],"two":[0,11,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.one,
      [2, 2, 2, 2],
      610),
  GenerationFixture(
      Variant.plakoto,
      '{"direction":"opposing","one":[0,0,0,1,1,0,0,0,2,0,1,0,2,0,1,1,1,1,1,0,0,1,0,0,2,0],"two":[0,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,3,0,2,0,0,1,0,0,1,0],"pinnedOne":[],"pinnedTwo":[4,11,13,21]}',
      Side.one,
      [2, 2, 2, 2],
      982),
  GenerationFixture(
      Variant.fevga,
      '{"direction":"same","one":[0,0,2,0,0,0,0,0,0,6,0,0,0,0,0,4,0,0,0,0,3,0,0,0,0,0],"two":[0,0,2,0,0,0,0,1,0,1,0,0,1,1,0,0,2,2,3,0,1,0,0,1,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      377),
  GenerationFixture(
      Variant.tavla,
      '{"direction":"opposing","one":[0,9,0,0,0,0,1,0,0,1,0,0,3,1,0,0,0,0,0,0,0,0,0,0,0,0],"two":[0,3,1,1,0,1,0,1,1,0,0,1,0,0,0,2,0,1,0,0,1,1,1,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      675),
  GenerationFixture(
      Variant.tapa,
      '{"direction":"opposing","one":[0,1,0,1,2,2,0,0,1,1,1,0,0,0,1,1,1,1,0,0,0,1,0,0,1,0],"two":[0,0,2,1,1,0,0,4,0,0,0,1,2,1,0,0,0,0,0,0,1,1,0,0,1,0],"pinnedOne":[21],"pinnedTwo":[11,20,21,24]}',
      Side.one,
      [2, 2, 2, 2],
      479),
  GenerationFixture(
      Variant.moultezim,
      '{"direction":"same","one":[0,1,2,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0],"two":[0,0,0,1,0,1,1,0,0,1,0,1,0,0,0,0,0,0,3,0,3,2,1,0,1,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [2, 2, 2, 2],
      444),
  GenerationFixture(
      Variant.gulBara,
      '{"direction":"same","one":[0,5,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0],"two":[0,0,1,1,2,1,0,0,1,1,0,1,0,0,0,0,0,0,2,0,1,0,0,0,4,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      603),
  GenerationFixture(
      Variant.longNard,
      '{"direction":"same","one":[0,6,0,0,0,4,0,0,1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0],"two":[0,3,1,0,0,1,0,2,0,2,1,2,1,0,0,0,0,0,0,2,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      269),
  GenerationFixture(
      Variant.shortNard,
      '{"direction":"opposing","one":[0,0,0,1,0,0,3,0,0,0,0,0,0,5,0,1,0,0,0,0,0,0,1,1,3,0],"two":[0,0,0,0,1,2,0,1,2,1,0,0,0,3,0,0,0,1,1,0,0,1,0,1,1,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [2, 2, 2, 2],
      574),
  GenerationFixture(
      Variant.sheshBesh,
      '{"direction":"opposing","one":[0,2,4,0,4,0,0,0,0,1,0,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0],"two":[0,0,2,2,0,2,1,0,1,1,2,0,0,0,0,0,0,0,1,0,2,0,1,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      459),
  GenerationFixture(
      Variant.mahbusa,
      '{"direction":"opposing","one":[0,0,1,0,1,0,0,1,0,1,0,1,1,0,1,0,0,0,1,0,1,0,0,0,6,0],"two":[0,0,0,1,0,2,0,0,1,0,0,0,2,0,1,0,0,1,0,0,3,1,0,1,2,0],"pinnedOne":[2,4,11,20],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      749),
  GenerationFixture(
      Variant.mahbusaArab,
      '{"direction":"opposing","one":[0,0,1,2,2,1,0,1,0,0,0,0,2,1,1,0,0,0,0,0,3,1,0,0,0,0],"two":[0,0,1,0,1,0,0,1,1,1,2,1,1,0,1,1,1,1,0,1,0,0,0,1,0,0],"pinnedOne":[13,14,21],"pinnedTwo":[23]}',
      Side.two,
      [1, 1, 1, 1],
      727),
  GenerationFixture(
      Variant.tawla31,
      '{"direction":"same","one":[0,1,1,0,2,1,0,0,0,0,0,0,0,7,0,0,0,0,3,0,0,0,0,0,0,0],"two":[0,0,0,2,1,2,0,2,0,1,0,0,1,0,0,1,0,0,0,0,1,1,1,2,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      349),
];

/// The slowest succeeding cascade found (48573 us when scanned).
const worstCascade = GenerationFixture(
    Variant.gulBara,
    '{"direction":"same","one":[0,3,0,1,3,0,1,0,0,0,1,1,1,0,0,0,0,0,0,0,2,0,0,0,2,0],"two":[0,5,1,1,3,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
    Side.one,
    [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
    24,
    cascade: true);

/// The slowest failing cascade found (263335 us when scanned).
const worstFailingCascade = GenerationFixture(
    Variant.gulBara,
    '{"direction":"same","one":[0,2,1,1,1,2,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0],"two":[0,3,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,5,0],"pinnedOne":[],"pinnedTwo":[]}',
    Side.one,
    [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
    21,
    cascade: true);
