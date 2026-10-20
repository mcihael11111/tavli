/// Difficulty levels and their search profiles (design spec SP2 §5).
library;

/// The bot's difficulty. The app's `easyWithHelp` maps to [easy] plus
/// teaching analysis.
enum BotLevel { easy, medium, hard, expert }

/// How a level searches: depth, candidate widening, selection noise and
/// time budgets. Initial values from the design table, tuned against the
/// strength gates (plan Task 10; the tuning log is in the SP2 report):
/// Easy noise 0.12 -> 0.3; Medium K 3 -> 2, noise 0.04 -> 0.1, top
/// fraction 0.2 -> 1.0.
final class LevelProfile {
  /// 0 = score the plays only; 1 = expectation over the opponent's rolls.
  final int depth;

  /// Expert: 2-ply on the top two 1-ply candidates when budget remains.
  final bool expertTwoPly;

  /// 1-ply candidates: starts at [k] and doubles up to [kMax] while budget
  /// remains (iterative widening). Both 0 when [depth] is 0.
  final int k, kMax;

  /// Uniform noise added to each candidate's equity: ± [noise].
  final double noise;

  /// The share of the best candidates the pick is drawn from; 0 = always
  /// the best.
  final double topFraction;

  /// Sampled completions per cascade decision.
  final int cascadeSamples;

  /// Per-decision time budget, and the separate budget for a cascade turn
  /// (2x). These are the device targets (Galaxy S, program spec §3.3,
  /// design §1), the budgets the app runs with. The desktop gates are a
  /// third of them (7/27/100/270 ms): the benchmarks pass those as
  /// explicit request budgets and gate against them.
  final Duration budget, cascadeBudget;

  const LevelProfile({
    required this.depth,
    required this.expertTwoPly,
    required this.k,
    required this.kMax,
    required this.noise,
    required this.topFraction,
    required this.cascadeSamples,
    required this.budget,
    required this.cascadeBudget,
  });

  static const _easy = LevelProfile(
    depth: 0,
    expertTwoPly: false,
    k: 0,
    kMax: 0,
    noise: 0.3,
    topFraction: 0.5,
    cascadeSamples: 8,
    budget: Duration(milliseconds: 20),
    cascadeBudget: Duration(milliseconds: 40),
  );

  static const _medium = LevelProfile(
    depth: 1,
    expertTwoPly: false,
    k: 2,
    kMax: 6,
    noise: 0.1,
    topFraction: 1.0,
    cascadeSamples: 24,
    budget: Duration(milliseconds: 80),
    cascadeBudget: Duration(milliseconds: 160),
  );

  static const _hard = LevelProfile(
    depth: 1,
    expertTwoPly: false,
    k: 6,
    kMax: 16,
    noise: 0.01,
    topFraction: 0.05,
    cascadeSamples: 64,
    budget: Duration(milliseconds: 300),
    cascadeBudget: Duration(milliseconds: 600),
  );

  static const _expert = LevelProfile(
    depth: 1,
    expertTwoPly: true,
    k: 8,
    kMax: 32,
    noise: 0,
    topFraction: 0,
    cascadeSamples: 128,
    budget: Duration(milliseconds: 800),
    cascadeBudget: Duration(milliseconds: 1600),
  );

  /// The profile of [l].
  static LevelProfile of(BotLevel l) => switch (l) {
        BotLevel.easy => _easy,
        BotLevel.medium => _medium,
        BotLevel.hard => _hard,
        BotLevel.expert => _expert,
      };

  @override
  String toString() => 'LevelProfile(depth: $depth, 2-ply: $expertTwoPly, '
      'k: $k->$kMax, noise: $noise, top: $topFraction, '
      'samples: $cascadeSamples, budget: $budget/$cascadeBudget)';
}
