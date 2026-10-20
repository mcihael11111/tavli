import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// Noiseless 0-ply: deterministic whatever the seed or the clock.
const _greedy = LevelProfile(
  depth: 0,
  expertTwoPly: false,
  k: 0,
  kMax: 0,
  noise: 0,
  topFraction: 0,
  cascadeSamples: 8,
  budget: Duration(seconds: 10),
  cascadeBudget: Duration(seconds: 20),
);

/// A [BotPlayer] that records the dice of each of its decisions.
final class _Recording implements TournamentPlayer {
  _Recording(LevelProfile profile, this.log, this.name)
      : _bot = BotPlayer(profile);
  final BotPlayer _bot;
  final List<(String, List<int>)> log;
  final String name;

  @override
  DecisionStats? get last => _bot.last;

  @override
  List<Step> choose(GameState s, int seed) {
    log.add((name, s.dice));
    return _bot.choose(s, seed);
  }
}

/// Large, so every search finishes and results do not depend on the
/// machine.
const _ample = Duration(seconds: 10);

List<GameOutcome> _run(int seed, int pairs, Variant v) => [
      for (var p = 0; p < pairs; p++)
        ...playPair(
          variant: v,
          a: () => BotPlayer.level(BotLevel.medium, budget: _ample),
          b: () => BotPlayer.level(BotLevel.easy, budget: _ample),
          seed: seed,
          pair: p,
        ),
    ];

void main() {
  test('smoke: 40 Portes games, Medium vs Easy (no gate)', () {
    final games = _run(1, 20, Variant.portes);
    expect(games, hasLength(40));
    for (final g in games) {
      expect(g.result, isNotNull, reason: 'pair ${g.pair} unfinished');
      expect(g.result!.points, inInclusiveRange(1, 3));
    }
    final s = PairingSummary.of(games);
    expect(s.games, 40);
    expect(s.winsA + s.winsB + s.draws + s.unfinished, 40);
    expect(s.ciLow, lessThanOrEqualTo(s.winRate));
    expect(s.ciHigh, greaterThanOrEqualTo(s.winRate));
    expect(s.tallyA.decisions, greaterThan(0));
    expect(s.tallyA.depths[1], greaterThan(0), reason: 'Medium is 1-ply');
    expect(s.tallyB.depths[0], s.tallyB.decisions, reason: 'Easy is 0-ply');
    // Printed for the curious; the gates are run by tool/tournament.dart.
    printOnFailure('$s');
  });

  test('smoke: a pinning and a running game finish legally', () {
    for (final v in [Variant.plakoto, Variant.fevga, Variant.gulBara]) {
      final games = _run(3, 1, v);
      expect(games.map((g) => g.result), everyElement(isNotNull),
          reason: v.name);
    }
  });

  test('mirrored pairs: each seat sees the same dice in both games', () {
    // Equal deterministic players: the two games of a pair are then
    // move-for-move the same, A and B having swapped seats. So seat
    // one's dice in game 1 (A) are seat one's dice in game 2 (B).
    final log = <(String, List<int>)>[];
    final games = playPair(
      variant: Variant.portes,
      a: () => _Recording(_greedy, log, 'A'),
      b: () => _Recording(_greedy, log, 'B'),
      seed: 7,
      pair: 0,
    );
    expect(games.map((g) => g.aIsOne), [true, false]);
    expect(games[0].pair, games[1].pair);
    final split = log.length ~/ 2;
    expect(log.length, 2 * split);
    final first = log.sublist(0, split), second = log.sublist(split);
    for (var i = 0; i < split; i++) {
      expect(second[i].$2, first[i].$2, reason: 'decision $i');
      expect(second[i].$1, first[i].$1 == 'A' ? 'B' : 'A',
          reason: 'decision $i: the other player has that seat');
    }
    // Same game by seat, so the scores are mirrored.
    expect(games[0].result, games[1].result);
    expect(games[0].scoreA + games[1].scoreA, 1);
    expect(games[0].pointsA, -games[1].pointsA);
  });

  test('the same seed gives the same results; another seed differs', () {
    String key(List<GameOutcome> gs) => [
          for (final g in gs)
            '${g.pair}${g.aIsOne} ${g.result?.winner} ${g.result?.kind} '
                '${g.turns}',
        ].join('|');
    final a = key(_run(11, 3, Variant.portes));
    expect(key(_run(11, 3, Variant.portes)), a);
    expect(key(_run(12, 3, Variant.portes)), isNot(a));
  });

  test('summary: win rate, points and the pair-based 95 % CI', () {
    GameOutcome g(int pair, bool aIsOne, Side? winner, int points) =>
        GameOutcome(
          pair: pair,
          aIsOne: aIsOne,
          result: GameResult(
              winner: winner,
              kind: winner == null
                  ? ResultKind.draw
                  : (points == 2 ? ResultKind.gammon : ResultKind.single),
              points: winner == null ? 0 : points,
              cubeValue: 1),
          turns: 10,
          tallyA: PlayerTally(),
          tallyB: PlayerTally(),
        );
    // Pair 0: A wins both (one a gammon). Pair 1: split. Pair 2: A loses
    // one, draws one.
    final s = PairingSummary.of([
      g(0, true, Side.one, 2),
      g(0, false, Side.two, 1),
      g(1, true, Side.two, 1),
      g(1, false, Side.two, 1),
      g(2, true, Side.two, 1),
      g(2, false, null, 0),
    ]);
    expect((s.games, s.winsA, s.winsB, s.draws), (6, 3, 2, 1));
    expect((s.pointsA, s.pointsB), (4, 2));
    expect(s.winRate, closeTo(3.5 / 6, 1e-12));
    // Pair scores 1, 0.5, 0.25: mean 7/12, sd² = 0.145833…
    const half = 1.96 * 0.2204792759220492; // sqrt(0.1458333 / 3)
    expect(s.ciLow, closeTo(3.5 / 6 - half, 1e-9));
    expect(s.ciHigh, closeTo(3.5 / 6 + half, 1e-9));
  });

  test('mixSeed is stable and spreads nearby inputs', () {
    expect(mixSeed(1, 0), mixSeed(1, 0));
    expect({for (var p = 0; p < 100; p++) mixSeed(1, p)}, hasLength(100));
    expect(mixSeed(1, 0), isNot(mixSeed(2, 0)));
    expect(mixSeed(123456789, 987654321), inInclusiveRange(0, 0x7FFFFFFF));
  });
}
