/// Tournament results: win rate, points and a 95 % confidence interval
/// over mirrored pairs (plan Task 10).
library;

import 'dart:math';

import 'match_runner.dart';

/// The summary of a pairing's games, from player A's point of view.
///
/// The confidence interval is computed over **pairs**: the two games of
/// a mirrored pair share their dice, so they are not independent. Each
/// pair scores `(scoreA₁ + scoreA₂) / 2` in {0, ¼, ½, ¾, 1}; the interval
/// is `mean ± 1.96 · sd / √pairs` (normal approximation; sd with n − 1).
/// Draws and unfinished games score ½.
final class PairingSummary {
  PairingSummary._(
      this.games,
      this.winsA,
      this.winsB,
      this.draws,
      this.unfinished,
      this.pointsA,
      this.pointsB,
      this.winRate,
      this.ciLow,
      this.ciHigh,
      this.tallyA,
      this.tallyB);

  factory PairingSummary.of(Iterable<GameOutcome> outcomes) {
    var games = 0, winsA = 0, winsB = 0, draws = 0, unfinished = 0;
    var pointsA = 0, pointsB = 0;
    var score = 0.0;
    final tallyA = PlayerTally(), tallyB = PlayerTally();
    final byPair = <int, List<double>>{};
    for (final o in outcomes) {
      games++;
      score += o.scoreA;
      final pts = o.pointsA;
      if (pts > 0) pointsA += pts;
      if (pts < 0) pointsB -= pts;
      if (o.result == null) {
        unfinished++;
      } else if (o.scoreA == 1) {
        winsA++;
      } else if (o.scoreA == 0) {
        winsB++;
      } else {
        draws++;
      }
      tallyA.add(o.tallyA);
      tallyB.add(o.tallyB);
      (byPair[o.pair] ??= []).add(o.scoreA);
    }
    final pairScores = [
      for (final s in byPair.values) s.reduce((a, b) => a + b) / s.length,
    ];
    final rate = games == 0 ? double.nan : score / games;
    final half = _halfWidth(pairScores);
    return PairingSummary._(games, winsA, winsB, draws, unfinished, pointsA,
        pointsB, rate, rate - half, rate + half, tallyA, tallyB);
  }

  final int games, winsA, winsB, draws, unfinished;

  /// Points won by A and by B (gammons 2, etc.).
  final int pointsA, pointsB;

  /// A's score per game: wins plus half the draws and unfinished games.
  final double winRate;

  /// The 95 % confidence interval of [winRate] (over pairs).
  final double ciLow, ciHigh;

  final PlayerTally tallyA, tallyB;

  /// A's net points per game.
  double get netPointsPerGame => games == 0 ? 0 : (pointsA - pointsB) / games;

  @override
  String toString() => 'A ${_pct(winRate)} '
      '[${_pct(ciLow)}, ${_pct(ciHigh)}] '
      '($winsA-$winsB${draws > 0 ? ', $draws draws' : ''}'
      '${unfinished > 0 ? ', $unfinished unfinished' : ''} of $games), '
      'points $pointsA-$pointsB';
}

/// 1.96 · sd / √n over [xs]; 0.5 (uninformative) with fewer than two.
double _halfWidth(List<double> xs) {
  final n = xs.length;
  if (n < 2) return 0.5;
  final mean = xs.reduce((a, b) => a + b) / n;
  var ss = 0.0;
  for (final x in xs) {
    ss += (x - mean) * (x - mean);
  }
  return 1.96 * sqrt(ss / (n - 1) / n);
}

String _pct(double x) => '${(100 * x).toStringAsFixed(1)} %';
