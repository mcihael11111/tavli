/// Benchmark fixtures (plan Task 9), found by
/// `dart run --no-enable-asserts benchmark/run_benchmarks.dart --scan`,
/// which prints this file (regenerate it, never hand-edit it).
/// See `scanFixtures` in `bench_suite.dart`.
library;

import 'package:tavli_core/tavli_core.dart';

import 'bench_suite.dart' show PlayFixture;

const playFixtures = [
  PlayFixture(
      Variant.portes,
      '{"direction":"opposing","one":[0,0,0,3,0,0,0,0,2,0,2,0,1,0,0,1,0,1,1,0,1,2,1,0,0,0],"two":[0,11,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.one,
      [1, 2],
      86),
  PlayFixture(
      Variant.portes,
      '{"direction":"opposing","one":[0,0,0,3,0,0,0,0,2,0,2,0,1,0,0,1,0,1,1,0,1,2,1,0,0,0],"two":[0,11,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.one,
      [2, 2, 2, 2],
      610),
  PlayFixture(
      Variant.plakoto,
      '{"direction":"opposing","one":[0,0,1,1,0,0,0,1,0,0,1,0,1,0,1,1,0,1,2,0,1,1,1,1,1,0],"two":[0,0,1,0,3,0,1,1,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,6,0],"pinnedOne":[21],"pinnedTwo":[2,7,8]}',
      Side.one,
      [1, 4],
      114),
  PlayFixture(
      Variant.plakoto,
      '{"direction":"opposing","one":[0,0,0,1,1,0,0,0,2,0,1,0,2,0,1,1,1,1,1,0,0,1,0,0,2,0],"two":[0,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,3,0,2,0,0,1,0,0,1,0],"pinnedOne":[],"pinnedTwo":[4,11,13,21]}',
      Side.one,
      [2, 2, 2, 2],
      982),
  PlayFixture(
      Variant.fevga,
      '{"direction":"same","one":[0,0,2,0,0,0,0,0,0,6,0,0,0,0,0,4,0,0,0,0,3,0,0,0,0,0],"two":[0,0,2,0,0,0,0,1,0,1,0,0,1,1,0,0,2,2,3,0,1,0,0,1,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 3],
      68),
  PlayFixture(
      Variant.fevga,
      '{"direction":"same","one":[0,0,2,0,0,0,0,0,0,6,0,0,0,0,0,4,0,0,0,0,3,0,0,0,0,0],"two":[0,0,2,0,0,0,0,1,0,1,0,0,1,1,0,0,2,2,3,0,1,0,0,1,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      377),
  PlayFixture(
      Variant.longNard,
      '{"direction":"same","one":[0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,5,0,0,0,0,0,0],"two":[0,5,1,1,0,0,1,0,1,1,0,1,0,0,0,0,0,0,1,0,1,0,0,1,1,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 2],
      60),
  PlayFixture(
      Variant.longNard,
      '{"direction":"same","one":[0,6,0,0,0,4,0,0,1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0],"two":[0,3,1,0,0,1,0,2,0,2,1,2,1,0,0,0,0,0,0,2,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 1, 1, 1],
      269),
  PlayFixture(
      Variant.gulBara,
      '{"direction":"same","one":[0,5,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0],"two":[0,0,1,1,2,1,0,0,1,1,0,1,0,0,0,0,0,0,2,0,1,0,0,0,4,0],"pinnedOne":[],"pinnedTwo":[]}',
      Side.two,
      [1, 2],
      84),
];

/// The full 1-1 cascade slowest to decide at Medium (1097206 us when scanned).
const slowestRealCascade = PlayFixture(
    Variant.gulBara,
    '{"direction":"same","one":[0,0,0,1,2,0,0,2,1,0,1,0,0,0,0,0,0,0,1,1,1,0,0,2,3,0],"two":[0,1,1,1,1,3,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,5,0],"pinnedOne":[],"pinnedTwo":[]}',
    Side.one,
    [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
    20,
    cascade: true);
