# SP1 Game Core (`tavli_core`) — Exit Report

**Date:** 2026-10-02
**Plan:** `docs/superpowers/plans/2026-10-01-sp1-game-core.md` (Tasks 1–18)
**Rules source:** `docs/superpowers/specs/2026-10-01-sp1-variant-rules-matrix.md` (approved; addenda A1–A9)
**Machine:** Apple Silicon Mac, Dart VM JIT (same machine as the legacy baseline)

## Summary

- All 13 variants are implemented in the pure-Dart `packages/tavli_core`: play-tree generation, reducer, match layer, serialization and replay.
- **424 package tests pass**, plus the app-level Portes legacy differential.
- **Oracle differential:** clean. **Portes legacy differential:** clean, with 0 known legacy bugs.
- **Fuzz:** 2,000 games per variant (26,000 games, 6.9 M actions) with zero failures.
- **100k run: IN PROGRESS.** It was started 2026-10-02 00:29 AEST and should take about 1.5 h. Its output goes to a local run log (not committed); the command is `cd packages/tavli_core && TAVLI_FUZZ_GAMES=100000 dart test --tags fuzz --reporter expanded`.
- **Benchmarks:** every budget is met with asserts off.
  - Worst generation fixture p95: 1.72 ms (budget 2 ms).
  - Reducer `StepAction` p95: 0.5 µs (budget 50 µs).
  - Sampled Gul Bara failing cascades p95: 0.20 ms (budget 50 ms).
  - The worst single cascades exceed the 50 ms budget and are held only to loose regression caps (see below).
- **Against the legacy generator:** on the legacy baseline positions, core generation p95 is 4.0× faster on all rolls and 4.7× on doubles (§6, reproducible), even though it builds a full step-order play tree.

## 1. Tests per suite

From `dart test` in `packages/tavli_core`. The default run includes the 40-game fuzz and the bench suite.

| Suite | Tests | Content |
|---|---:|---|
| `test/board` | 65 | Geometry, Position invariants, JSON, MutablePosition and the Zobrist hash |
| `test/variant` | 35 | Catalog: one decision test per D-number, plus a per-variant row check |
| `test/rules` | 92 | Rule-ID scenario tests: steps, validators, filters, game end |
| `test/play` | 50 | Generator, cascades, lazy-vs-brute, oracle differential |
| `test/game` | 89 | Reducer phases, every `ViolationCode`, cube, Gul Bara, SubmitPlay, actor, reduce fuzz, full games |
| `test/match` | 27 | Rotation, starters, Crawford, Tawla 31, events, forfeit |
| `test/serial` | 21 | Round-trips, replay, state validation, JSON mutation fuzz |
| `test/fuzz` (tag `fuzz`) | 13 | One test per variant (Task 16) |
| `test/purity_test.dart` | 4 | Import purity of `lib/` |
| `benchmark` (tag `bench`) | 28 | Budgets (Task 17) |
| **Total** | **424** | |
| App `test/differential` | 3 | Portes legacy differential, plus 2 tests of the known-legacy-bug mechanism (Task 18) |

**Rule-ID coverage.** `grep -ho "test('[A-Z][0-9]*" -r test` (plus group names) finds:
- G1–G9;
- D1–D22 (D20 sits in multi-line test names);
- A2, A4, A6 and A9.

Two addenda are covered by tests named for their rule:
- **A5:** `test/rules/play_filters_test.dart` covers it with `D12a every play completes it: all survive`, the `D12b` tests (with the opponent head occupied and empty) and the two `D14 Moultezim` tests.
- **A8:** `D5 most checkers borne off first` in the same file pins the "most borne off" stage. With dice 6-3, Portes keeps both finals and Tavla keeps only the all-off final.

A1, A3 and A7 have no test because no reachable position triggers them. For A7, `play_generator_test` has a comment arguing why.

## 2. Benchmarks (asserts off)

Command: `dart run --no-enable-asserts benchmark/run_benchmarks.dart`.

**Fixtures.** The fixtures are in `benchmark/bench_fixtures.dart` and are regenerated with `--scan`:
- **Generation:** for each variant, the position × roll × side with the most legal finals, over 300 reachable positions × 21 rolls × 2 sides.
- **Cascades:** the slowest succeeding and the slowest failing Gul Bara cascades, each measured as build plus a walk to a complete node. They were found over 1,500 positions × 2 sides × 6 queues.

**How CI checks budgets.** `dart test` runs the same benchmarks with asserts on. There, each budget is multiplied by 2 (the assert allowance) and by `TAVLI_BENCH_SCALE`. `tool/ci/check.sh` runs them alone (`--tags bench --concurrency=1`).

| Benchmark | n | p50 (µs) | p95 (µs) | max (µs) | Budget | OK |
|---|---:|---:|---:|---:|---:|:-:|
| generate portes 2-2-2-2 (610 finals) | 200 | 766.8 | 790.8 | 1224.4 | 2000 | yes |
| generate plakoto 2-2-2-2 (982 finals) | 200 | 1302.3 | 1687.6 | 2072.1 | 2000 | yes |
| generate fevga 1-1-1-1 (377 finals) | 200 | 595.2 | 725.2 | 1061.7 | 2000 | yes |
| generate tavla 1-1-1-1 (675 finals) | 200 | 937.0 | 958.8 | 1362.6 | 2000 | yes |
| generate tapa 2-2-2-2 (479 finals) | 200 | 505.0 | 518.8 | 846.7 | 2000 | yes |
| generate moultezim 2-2-2-2 (444 finals) | 200 | 620.4 | 640.6 | 1011.9 | 2000 | yes |
| generate gulBara 1-1-1-1 (603 finals) | 200 | 788.8 | 811.3 | 1256.3 | 2000 | yes |
| generate longNard 1-1-1-1 (269 finals) | 200 | 409.4 | 441.1 | 688.2 | 2000 | yes |
| generate shortNard 2-2-2-2 (574 finals) | 200 | 790.6 | 811.5 | 1109.2 | 2000 | yes |
| generate sheshBesh 1-1-1-1 (459 finals) | 200 | 599.9 | 653.8 | 909.6 | 2000 | yes |
| generate mahbusa 1-1-1-1 (749 finals) | 200 | 1014.3 | 1062.8 | 1464.2 | 2000 | yes |
| generate mahbusaArab 1-1-1-1 (727 finals) | 200 | 1099.4 | 1722.6 | 2851.8 | 2000 | yes |
| generate tawla31 1-1-1-1 (349 finals) | 200 | 469.1 | 478.5 | 763.5 | 2000 | yes |
| gulBara worst succeeding cascade 1×24 | 50 | 64926.0 | 77139.0 | 79296.3 | cap 1000000 | yes |
| gulBara worst failing cascade 1×24 (fails at 21) | 20 | 353900.8 | 381237.2 | 389159.3 | cap 2000000 | yes |
| gulBara sampled cascades (18,000; p99 0.67 ms) | 18000 | 26.2 | 156.4 | 314990.2 | 50000 | yes |
| gulBara sampled failing cascades (3,077; p99 2.64 ms) | 3077 | 4.0 | 204.7 | 314990.2 | 50000 | yes |
| reduce StepAction (all 13 variants, mid-game) | 2000 each | 0.4–0.5 | 0.5 | 1.6–55.2 | 50 | yes |

**Incremental Zobrist hash (design §9).** This was implemented for the failing-cascade target. It is maintained in O(1) by `MutablePosition` add/remove/setPinned:
- it is 30-bit and web-safe, with identical values on the VM and under dart2js (checked with node);
- `Position.hashCode` is now this hash;
- the eager search memo and the cascade's max-depth memo key on (hash, context, progress) and confirm a hit with `sameBoardAs`, so a lookup never freezes the board.

All oracle and lazy-vs-brute tests stayed green. Measurements before → after (asserts off):

| | Before | After |
|---|---:|---:|
| Plakoto worst fixture (before: fastest of 30 runs; after: p50 of 200, so the drop is understated) | 2.15 ms | 1.30 ms |
| Portes worst fixture (same measures) | 1.26 ms | 0.77 ms |
| Sampled failing cascades p95 | 0.40 ms | 0.20 ms |
| Sampled failing cascades p99 | 5.4 ms | 2.6 ms |
| Worst single cascade | 401 ms | 315 ms |

**Regression caps, not budgets (deviation).** Two kinds of single cascade are outliers that exceed the 50 ms budget. They are held only to loose regression caps (`worstCascadeCap`, `worstFailingCascadeCap`), so that only a big regression fails: 1 s for the worst succeeding cascade and 2 s for the worst failing one. Like every budget, `dart test` multiplies these by 2 for asserts and by `TAVLI_BENCH_SCALE`.
- **Failing cascades.** A failing 24-entry cascade (1-1 at roll ≥ 4) must visit every reachable state to prove that the queue's end cannot be reached. The worst found takes about 0.35 s.
- **Succeeding cascades.** A succeeding cascade can still search deep before it finds a full path. The worst found takes about 65 ms.

Both are under 0.1 % of sampled cascades. A sound pruning bound (or move ordering for the succeeding case) is the next step if SP2 bots hit them.

## 3. Fuzz (Task 16)

**What each game does** (`test/fuzz/fuzz_games_test.dart`, tag `fuzz`, games per variant = `TAVLI_FUZZ_GAMES`, default 40):
- It is seeded per game and plays random legal moves to the natural end.
- Turns alternate between step-by-step play (with an occasional undo and redo) and `SubmitPlay`.
- In the cube variants, a random offer happens with probability 0.05 and is always taken.

**What is checked:**
- After every action: board and phase invariants.
- Every 25th action and at game end: the state round-trips through JSON.
- About 1 in 40 moving phases: the tree is checked against the oracle. Cascades with more than 400 finals are skipped.
- Every 50th game: a `GameLog` JSON replay.
- At the end of each game: the result agrees with the board.

**2,000 games per variant:** 26,000 games, 6,948,086 actions, 52,922 oracle checks, 520 replays and 277,916 JSON round-trips, with **0 failures**. Wall time was 1 min 41 s. The default run of 40 per variant takes about 3 s.

| Variant | Actions | Outcomes |
|---|---:|---|
| portes | 575,272 | gammon 1221, single 779 |
| plakoto | 459,890 | mother 918, draw 447, single 444, gammon 191 |
| fevga | 601,818 | single 1607, gammon 393 |
| tavla | 570,287 | gammon 1233, single 767 |
| tapa | 458,216 | mother 956, draw 443, single 436, gammon 165 |
| moultezim | 604,422 | single 1616, gammon 384 |
| gulBara | 373,754 | gammon 1366, single 634 (2,101 remainders handed over; 162 oracle samples skipped) |
| longNard | 620,819 | single 1673, gammon 327 (5,804 cube takes, cube up to 64) |
| shortNard | 580,896 | single 792, gammon 737, triple 471 (5,506 cube takes) |
| sheshBesh | 586,233 | single 795, gammon 728, triple 477 (5,551 cube takes) |
| mahbusa | 456,706 | mother 952, single 466, draw 428, gammon 154 |
| mahbusaArab | 456,851 | mother 935, single 450, draw 454, gammon 161 |
| tawla31 | 602,922 | checkersRemaining 2000 |

**100k run: IN PROGRESS.** Output goes to a local run log (not committed).
- Command: `cd packages/tavli_core && TAVLI_FUZZ_GAMES=100000 dart test --tags fuzz --reporter expanded`, started 2026-10-02 00:29 AEST.
- Estimate: about 1.5 h (Portes did 10k games in 41 s), so about 1.3 M games.
- When it finishes, record its totals here and tick the exit-checklist item.

## 4. Oracle comparisons

| Where | What | Result |
|---|---|---|
| `test/play/oracle_differential_test.dart` (default run) | 13 variants × 30 reachable positions × 21 rolls (8,190 trees) | clean |
| Same file | Every start position × both sides × 21 rolls, first turn (546) | clean |
| Same file | Gul Bara cascades: 60 positions × 6 dice × (full queue, random tail), only those with ≤ 400 finals (≥ 100 asserted) | clean |
| `test/play/cascade_lazy_test.dart` | Lazy cascade vs a brute-force level expansion | clean |
| Fuzz (2,000/variant) | 52,922 sampled moving phases (live reducer trees, including first turns and remainders) | clean |

## 5. Portes legacy differential (Task 18)

`test/differential/portes_legacy_differential_test.dart` (app level, default run):
- **Positions:** 40 positions from the seeded legacy easy-vs-easy self-play (dice `Random(42)`, AI `Random(7)`, as in the baseline). Every third ply is kept, games restart when one ends, and both sides are to move.
- **Rolls:** all 21.
- **Comparison:** the set of legacy final boards from `MoveGenerator.generateAllLegalTurns` + `applyMoves`, mapped by matrix §1, against core `generatePlays(...).finals`.

| Pairs compared | Core finals | Positions with a checker on the bar | Positions bearing off | Mismatches | Known legacy bugs |
|---:|---:|---:|---:|---:|---:|
| 840 | 14,909 | 7 | 7 | **0** | 0 |

The legacy Portes generator agrees with core on G2, G4 (max dice and higher die), G5, G6 and bar entry for every sampled case.

**Known legacy bugs.** `knownLegacyBugs` (in `test/differential/portes_legacy.dart`) maps a matrix rule ID to a `KnownLegacyBug(why, cases)`. Only mismatches that no entry lists fail the test. It is empty. Two tests check the mechanism with a fake `G6` entry:
- the listed mismatch is suppressed;
- unlisted cases still fail.

`toCore`, the self-play and the baseline positions live in the same helper, which the legacy benchmark also uses (§6).

**Legacy discrepancies that do not change final sets.** A7 and A4 cannot show up as different final sets in Portes:
- **A7:** legacy keeps lower-die orderings that reach the same board.
- **A4:** legacy drops a one-step game-ending line only when a two-step line reaches the same "all off" board.

## 6. Comparison with the legacy baseline

**What is measured.** Core `generatePlays` and the legacy `MoveGenerator` run on the legacy baseline's own 12 positions (player 2 to move), with the same roll sweep and sample counts:
- positions come from `baselinePositions()`, which was checked to equal the baseline's inline sampling;
- boards are mapped with the differential's `toCore`;
- the harness is `test/bench/legacy_engine_bench_test.dart`, test `core generatePlays vs legacy MoveGenerator (baseline positions)`, tag `legacy-bench` (opt-in).

**How to reproduce:**

    flutter test --run-skipped --tags legacy-bench test/bench --plain-name 'core generatePlays vs legacy'

It writes `build/bench/core_vs_legacy.json` (not committed).

**Asserts.** Like the original baseline, this runs under `flutter test`, which has asserts on (JIT). The asserts apply equally to both engines, so the ratio is fair. Core's asserts-off numbers are in §2.

| | Legacy `MoveGenerator` p95 | Core `generatePlays` p95 | Speed-up (p95) |
|---|---:|---:|---:|
| All 21 rolls (500 samples) | 474.4 µs (baseline 472.6) | 118.8 µs | 4.0× |
| Doubles (300 samples) | 1010.1 µs (baseline 1012.3) | 216.0 µs | 4.7× |

p50 values: legacy 20.3 / 153.0 µs, core 18.1 / 53.7 µs.

The core result is richer: a step-order play tree with filters, not a flat move list.

**What this means for SP2's medium bot.** The legacy medium bot took 26 s p50 per move, mainly because its search regenerates moves. Generation is now about 4× faster per call. The worst-case p95 across all 13 variants is under 2 ms with asserts off, and the reducer step is sub-microsecond. The 80 ms medium-bot target is SP2's to meet.

## 7. Deviations from the plan

1. **Fixture location.** The fixtures live in `benchmark/bench_fixtures.dart`, not inside the test file. It is shared by the bench test and `run_benchmarks.dart`, and generated by `--scan`.
2. **Worst cascades under caps only.** The worst single Gul Bara cascades (succeeding and failing) are held only to loose regression caps of 1 s and 2 s, not the 50 ms budget (§2). The 50 ms budget applies to the p95 of sampled cascades, all and failing.
3. **CI benchmark run.** `tool/ci/check.sh` runs package tests with `--exclude-tags bench`, then the benchmarks alone with `--concurrency=1`. In a plain `dart test` the `bench` tag has `retry: 2`, to absorb timing noise from parallel suites.
4. **Fuzz cube answers.** Fuzz cube offers are always taken, never dropped, so that every game ends naturally. Drops are fuzzed in `reduce_fuzz_test`.
5. **Fuzz timeout.** Each variant's fuzz test gets 60 s + 20 ms per game, so a 100k run is not cut off by the tag's 20× timeout.
6. **New violation code.** `SubmitPlay` after steps were taken now returns the new `ViolationCode.stepsAlreadyTaken`, not `wrongPhase`. The plan text was updated.
7. **Differential sampling.** The differential samples every third ply of continuous self-play, so both sides and bear-offs are included. The baseline's player-2-only opening plies would not include them.

## 8. Open questions for the user

**A8 — D5 forces a bear-off (Tavla).** As approved, D5-A first keeps the plays that bear off the most checkers, then applies least-waste. This forces a bear-off whenever one is possible, which goes beyond G6 ("not obliged to bear off") and the bkgm wording ("don't waste pips").
- Example: Tavla, `one {2:1, 6:14}`, dice 2-1. Only "2/off + a 1" survives. Portes would also allow 6/4, 6/5.
- **Question:** keep it, or drop the "most borne off" stage (least-waste only)?

**A9 — forfeit scores the threatened result.** A resign or clock timeout scores what the board threatens, × cube:
- Tawla 31: the loser's checkers on the board.
- Mother rule: mother points if the loser's mother is pinned.
- Otherwise: triple, gammon or single, by the triple condition and borne-off count.

Consequence: resigning at move 1 concedes, because nothing is borne off yet (checked on every variant):
- a gammon (2 points) in most variants;
- 3 points (koks / Turkish mars) in Short Nard and Shesh Besh;
- 15 points in Tawla 31.

`ForfeitMatch` uses the same scoring.
- **Question:** keep it, or score a flat 1 × cube (which lets a player escape a threatened gammon)? A later "resign at a level" UI is possible either way.

**Interpretations to confirm** (matrix §9; each can be flipped):

| # | Reading chosen |
|---|---|
| A1 | Sole runner with ≥ 2 checkers already off an unreleased head (unreachable in normal play): the head stays locked; checkers already off it may move |
| A2 | Tavla D4 during bear-off: after a hit on home pip h, nothing bears off from h for the rest of the turn |
| A3 | D19 with pinned checkers (only matters if D19 is ever enabled for a pinning game): pinned points are not held, and a pinned opposing checker is not "in front". Untested, because it is unreachable |
| A4 | A game-ending step (15th checker off, immediate mother, both mothers pinned) ends the sequence and counts as using all its dice. A game-ending cascade has no remainder |
| A5 | D12-A (a)+(b) and D14-B's two parts are each one filter. If every play breaks some part, all plays survive |
| A6 | A Gul Bara cascade with no playable step: the whole queue is the remainder, played by the opponent (D16-B) |
| A7 | G4 higher die: when only one die can be played, lower-die sequences are dropped even if they reach the same final position |

## 9. SP1 exit checklist status

All items are ticked except the 100,000-game fuzz, which is in progress (see §3).
