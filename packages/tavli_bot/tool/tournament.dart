/// Headless bot tournaments (plan Task 10, design spec SP2 §1.4).
///
/// One pairing:
///   dart run tool/tournament.dart --a medium --b easy --variant portes \
///       --games 400 --seed 1 --jobs 8
/// The strength gates (every pairing they need, per family):
///   dart run tool/tournament.dart --gates --variant portes,plakoto,fevga
///
/// For speed compile it first: `dart compile exe tool/tournament.dart`.
///
/// Budgets (`--budget`): `desktop` (the default) passes each level's
/// desktop gate (7/27/100/270 ms, cascades 2x) as the request budget.
/// That approximates the compute the Galaxy S has within its device
/// budgets (the desktop gate is the device target / 3), so the gates
/// measure on-device strength. `device` uses the profiles' own budgets
/// (20/80/300/800 ms), which on a desktop overstate on-device strength.
/// A number is a budget in ms for both players.
///
/// A player is a level, optionally with profile overrides:
/// `hard:noise=0,top=0,k=8,kmax=32,samples=64,twoply=1,depth=1`.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

const _desktopGates = {
  BotLevel.easy: Duration(milliseconds: 7),
  BotLevel.medium: Duration(milliseconds: 27),
  BotLevel.hard: Duration(milliseconds: 100),
  BotLevel.expert: Duration(milliseconds: 270),
};

Future<void> main(List<String> argv) async {
  final args = _parse(argv);
  final variants = (args['variant'] ?? 'portes')
      .split(',')
      .map((v) => Variant.values.byName(v.trim()))
      .toList();
  final games = int.parse(args['games'] ?? '400');
  if (games.isOdd) _usage('--games must be even (mirrored pairs)');
  final seed = int.parse(args['seed'] ?? '1');
  final jobs = int.parse(args['jobs'] ?? '8');
  final budget = args['budget'] ?? 'desktop';

  final pairings = args.containsKey('gates')
      ? const [('medium', 'easy'), ('hard', 'medium'), ('expert', 'hard')]
          .followedBy(const [('expert', 'medium')]).toList()
      : [(args['a'] ?? _usage('--a'), args['b'] ?? _usage('--b'))];

  stdout.writeln('budget: $budget, games: $games, seed: $seed, '
      'jobs: $jobs');
  for (final v in variants) {
    for (final (a, b) in pairings) {
      final pa = _player(a, budget), pb = _player(b, budget);
      final watch = Stopwatch()..start();
      final s = await runPairing(v, pa, pb, games, seed, jobs);
      stdout.writeln('${v.name.padRight(8)} ${a.padRight(10)} vs '
          '${b.padRight(10)} $s  [${watch.elapsed.inSeconds} s]');
      stdout.writeln('    A ${_tally(s.tallyA)}');
      stdout.writeln('    B ${_tally(s.tallyB)}');
    }
  }
}

/// A sendable description of a player: its profile and request budget.
typedef PlayerSpec = (LevelProfile profile, Duration? budget);

/// Runs [games] games (mirrored pairs) of [a] vs [b] on [jobs] isolates.
Future<PairingSummary> runPairing(Variant v, PlayerSpec a, PlayerSpec b,
    int games, int seed, int jobs) async {
  final pairs = games ~/ 2;
  final parts = await Future.wait([
    for (var j = 0; j < jobs; j++)
      Isolate.run(() => [
            for (var p = j; p < pairs; p += jobs)
              ...playPair(
                variant: v,
                a: () => BotPlayer(a.$1, budget: a.$2),
                b: () => BotPlayer(b.$1, budget: b.$2),
                seed: seed,
                pair: p,
              ),
          ]),
  ]);
  return PairingSummary.of(parts.expand((x) => x));
}

PlayerSpec _player(String spec, String budget) {
  final parts = spec.split(':');
  final level = BotLevel.values.byName(parts.first);
  final base = LevelProfile.of(level);
  final o = <String, String>{};
  if (parts.length > 1) {
    for (final kv in parts[1].split(',')) {
      final i = kv.indexOf('=');
      if (i < 0) _usage('bad override $kv');
      o[kv.substring(0, i)] = kv.substring(i + 1);
    }
  }
  int i(String k, int d) => o.containsKey(k) ? int.parse(o[k]!) : d;
  double d(String k, double d) => o.containsKey(k) ? double.parse(o[k]!) : d;
  final profile = LevelProfile(
    depth: i('depth', base.depth),
    expertTwoPly: i('twoply', base.expertTwoPly ? 1 : 0) == 1,
    k: i('k', base.k),
    kMax: i('kmax', base.kMax),
    noise: d('noise', base.noise),
    topFraction: d('top', base.topFraction),
    cascadeSamples: i('samples', base.cascadeSamples),
    budget: base.budget,
    cascadeBudget: base.cascadeBudget,
  );
  final Duration? b = switch (budget) {
    'device' => null,
    'desktop' => _desktopGates[level],
    _ => Duration(milliseconds: int.parse(budget)),
  };
  return (profile, b);
}

String _tally(PlayerTally t) {
  final n = t.decisions == 0 ? 1 : t.decisions;
  return 'decisions ${t.decisions}, depth 0/1/2 '
      '${t.depths.join('/')}, timed out ${t.timedOut}, '
      'mean ${(t.elapsedUs / n / 1000).toStringAsFixed(1)} ms, '
      'max ${(t.maxUs / 1000).toStringAsFixed(1)} ms';
}

Map<String, String> _parse(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i < argv.length; i++) {
    final a = argv[i];
    if (!a.startsWith('--')) _usage('unexpected $a');
    final k = a.substring(2);
    if (k == 'gates') {
      out[k] = '';
    } else if (i + 1 < argv.length) {
      out[k] = argv[++i];
    } else {
      _usage('$a needs a value');
    }
  }
  return out;
}

Never _usage(String why) {
  stderr.writeln('tournament: $why\n'
      'usage: tournament (--a LEVEL[:k=v,...] --b LEVEL | --gates) '
      '[--variant portes[,plakoto,...]] [--games 400] [--seed 1] '
      '[--jobs 8] [--budget desktop|device|MS]');
  exit(64);
}
