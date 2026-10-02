/// Search test helpers: the SP1 worst cascades, legality checks and a slow
/// evaluator.
library;

import 'dart:convert';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// A Gul Bara cascade fixture: position, side and queue.
typedef CascadeFixture = ({Position position, Side side, List<int> queue});

CascadeFixture _fixture(String json) => (
      position: Position.fromJson(jsonDecode(json) as Map<String, Object?>),
      side: Side.one,
      queue: cascadeQueue(1),
    );

/// `worstCascade` of `packages/tavli_core/benchmark/bench_fixtures.dart`
/// (copied: a package must not import another's benchmark dir). It
/// reaches the end of its queue, and walking it is the expensive part
/// (about 1 s for `sampleCompletions(8)` without a stop).
final worstCascade = _fixture(
    '{"direction":"same","one":[0,3,0,1,3,0,1,0,0,0,1,1,1,0,0,0,0,0,0,0,2,0,0,0,2,0],"two":[0,5,1,1,3,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"pinnedOne":[],"pinnedTwo":[]}');

/// `worstFailingCascade` of the same file: building its tree is the
/// expensive part (about 0.26 s asserts off).
final worstFailingCascade = _fixture(
    '{"direction":"same","one":[0,2,1,1,1,2,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0],"two":[0,3,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,5,0],"pinnedOne":[],"pinnedTwo":[]}');

/// [play] is a complete legal play of [tree]: its steps walk the tree to a
/// complete node whose final is the play's.
void expectLegal(PlayTree tree, Play play, {String reason = ''}) {
  final node = tree.walk(play.steps);
  expect(node, isNotNull, reason: '$reason: ${play.steps} leaves the tree');
  expect(node!.isComplete, isTrue, reason: '$reason: ${play.steps} incomplete');
  expect(node.finalPosition, play.finalPosition, reason: reason);
}

/// Wraps an evaluator, busy-waiting [delay] per call.
final class SlowEvaluator implements Evaluator {
  SlowEvaluator(this.inner, this.delay);

  final Evaluator inner;
  final Duration delay;
  int calls = 0;

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    calls++;
    final w = Stopwatch()..start();
    while (w.elapsed < delay) {}
    return inner.evaluate(p, me, r);
  }
}

/// Profiles for tests: a plain 0-ply and 1-ply search without noise or
/// 2-ply, with a wide 1-ply (every play, up to 64).
const zeroPly = LevelProfile(
  depth: 0,
  expertTwoPly: false,
  k: 0,
  kMax: 0,
  noise: 0,
  topFraction: 0,
  cascadeSamples: 8,
  budget: Duration(seconds: 60),
  cascadeBudget: Duration(seconds: 60),
);
const onePly = LevelProfile(
  depth: 1,
  expertTwoPly: false,
  k: 64,
  kMax: 64,
  noise: 0,
  topFraction: 0,
  cascadeSamples: 8,
  budget: Duration(seconds: 60),
  cascadeBudget: Duration(seconds: 60),
);
