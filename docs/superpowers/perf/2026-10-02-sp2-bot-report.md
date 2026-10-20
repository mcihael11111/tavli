# SP2 Bot (`tavli_bot`) — Exit Report

**Date:** 2026-10-20 (plan and design dated 2026-10-02)
**Plan:** `docs/superpowers/plans/2026-10-02-sp2-bot.md` (Tasks 1–11)
**Design:** `docs/superpowers/specs/2026-10-02-sp2-bot-design.md`
**Machine:** Apple M3 Pro (6 performance + 6 efficiency cores), Dart VM. Benchmarks use JIT with asserts off. Tournaments use an AOT build of `tool/tournament.dart`.

## Summary

- **The strength gates are met** in all three families (§3). Every gate tournament ran 400 games with the **desktop-gate budgets** (7/27/100/270 ms, cascades 2×).
  - Medium beats Easy by 68.5–85.8 %.
  - Hard beats Medium by 58.8–64.8 %.
  - Expert beats Hard by 52.5 % in Portes and 54.8 % in Plakoto.
  - In Fevga, Expert passes on the alternative clause: Expert vs Hard is 50.2 % with CI [46.3 %, 54.2 %], and Expert beats Medium 68.8 %.
- **Legacy floor:** the new Easy beats the legacy app Easy **85.3 %** [81.7 %, 88.8 %] over 400 Portes games (§4).
- **Benchmarks:** all 75 rows of the asserts-off table are within the desktop gates (§2).
  - The new Medium's p95 is at most 3.6 ms on the worst fixtures. The legacy Medium took about 26 s per move (§6).
- **Worker:** the main isolate stays responsive during back-to-back Hard searches: timer-gap p99 2.07 ms and max 8.13 ms, against gates of 4 ms and 20 ms (§5).
- **Tests:** 164 `tavli_bot` tests plus 12 bench-tagged tests are green, and `tool/ci/check.sh` reports ALL GREEN.
- **What tuning changed:**
  - The running-family evaluator gained three terms.
  - The Easy and Medium profiles were made noisier.
  - The hitting and pinning evaluators are unchanged: the weight changes that helped them at 0-ply hurt at 1-ply (§3.3).

## 1. Tests

From `dart test` in `packages/tavli_bot`. The `bench` tag lives in `benchmark/`, which runs alone.

| Suite | Tests | Content |
|---|---:|---|
| `test/eval` | 26 | Features, race formula, family evaluators, antisymmetry / on-roll neutrality |
| `test/search` | 36 | 0/1/2-ply, widening, budget and predictive stop, selection, cascades, 14 labelled tactics (Expert finds all) |
| `test/cube` | 11 | Labelled double / take / pass / too-good positions |
| `test/teach` | 12 | Qualities ordered, best step has a best child, cascades, analysis depth/timedOut |
| `test/worker` | 56 | `Bot.decide` validation and fuzz; worker spawn, warm, cancel, supersede, id reuse, error, respawn, backoff, handshake timeout |
| `test/level_test.dart` | 5 | Tuned profile values; ordering (budget up, noise down, samples up) |
| `test/protocol_test.dart` | 8 | Request/reply value semantics |
| `test/purity_test.dart` | 4 | Import allowlist of `lib/` |
| `test/tournament_smoke_test.dart` | 6 | 40-game smoke (no gate), mirrored dice pairing, same seed gives the same results, CI arithmetic, seed mixing |
| **Total (default run)** | **164** | |
| `benchmark` (tag `bench`) | 12 | Budget gates (2× assert allowance), worker responsiveness |
| App `test/bench/bot_vs_legacy_test.dart` (tag `legacy-bench`, opt-in) | 1 | Legacy floor |

**Core additions (Task 1, in `tavli_core`):**
- `PlayTree.plays()` and `PlayTree.pathTo(final)`;
- `CascadeWalker` (`greedyCompletion`, `sampleCompletions` with a stop callback);
- `PlayTree.searchedStates`: a deterministic measure of the states a lazy cascade tree has expanded. The benchmarks use it to pick the costliest real-game cascade reproducibly.

## 2. Benchmarks (asserts off, after tuning)

Command: `cd packages/tavli_bot && dart run --no-enable-asserts benchmark/run_benchmarks.dart`. The p95 values are in ms. The gate is the desktop gate (design §1), passed as the request budget.

**`choosePlay`, worst play fixtures (p95, ms):**

| Variant, dice | Easy (≤ 7) | Medium (≤ 27) | Hard (≤ 100) | Expert (≤ 270) |
|---|---:|---:|---:|---:|
| portes 1-2 | 0.34 | 0.86 | 2.42 | 239.19 |
| portes 2-2-2-2 | 1.93 | 2.96 | 3.46 | 221.69 |
| plakoto 1-4 | 0.23 | 3.36 | 9.30 | 256.90 |
| plakoto 2-2-2-2 | 3.96 | 3.27 | 4.49 | 7.35 |
| fevga 1-3 | 0.29 | 1.38 | 3.38 | 256.83 |
| fevga 1-1-1-1 | 1.36 | 2.26 | 4.76 | 218.59 |
| mahbusa 1-2 | 0.22 | 2.34 | 8.47 | 256.71 |
| mahbusa 1-1-1-1 | 2.30 | 3.43 | 4.93 | 256.90 |
| longNard 1-2 | 0.13 | 0.86 | 1.65 | 196.47 |
| longNard 1-1-1-1 | 0.91 | 3.62 | 6.98 | 256.82 |
| gulBara 1-2 | 0.20 | 0.70 | 1.40 | 256.58 |

Expert runs until its budget by design: it uses the time left for 2-ply. Plakoto 2-2-2-2 is an exception: with 982 plays its 2-ply does not fit, so it stops after 1-ply.

**Other rows (p95, ms):**

| Benchmark | p95 | Gate |
|---|---:|---:|
| Gul Bara sampled cascades, `choosePlay` Easy / Medium / Hard / Expert | 2.18 / 5.34 / 13.07 / 24.64 | 14 / 54 / 200 / 540 |
| Gul Bara sampled cascades, `analyze` Medium | 9.21 | 54 |
| Predictive stop, 2 ms budget, Plakoto 2-2-2-2, Easy / Medium / Hard / Expert | 2.12 / 2.02 / 2.81 / 3.86 | 4.25 / 4.12 / 4.51 / 4.25 (budget + tree build and `.plays()` p95) |
| `offerDouble` / `takeDouble` Medium (11 positions) | 0.00 / 0.00 | 27 |
| `analyze` Medium, worst (Plakoto 1-4) | 12.79 | 27 |
| SP1 `worstCascade`: Medium / Expert / `analyze` | 89 / 577 / 244 | 4000 (regression cap) |
| SP1 `worstFailingCascade`: Medium / Expert / `analyze` | 297 / 320 / 341 | 4000 (cap) |
| Slowest real full 1-1 cascade: Medium / Expert / `analyze` | 1026 / 1402 / 1488 | 4000 (cap) |

**Changes after tuning.** Against the pre-tuning run (Task 9), the numbers are within run-to-run noise:
- the running evaluator's three new terms add one loop over 23 pips: Fevga Medium p95 is 1.38 ms against 1.44 ms before;
- the profile changes do not change the work per decision, except Medium starting its widening at K = 2.

## 3. Strength gates

**Setup:**
- Tournament rules:
  - single games with the cube off;
  - 200 mirrored pairs per pairing, where each pair plays the same seat-wise dice sequence twice with the bots' seats swapped;
  - base seed 1.
- Tool: `dart compile exe tool/tournament.dart`, then `tournament --gates --variant portes,plakoto,fevga --games 400 --seed 1 --jobs 6`.
- **Budgets:** the desktop-gate budgets (Easy 7 ms, Medium 27 ms, Hard 100 ms, Expert 270 ms; cascades 2×) are passed as request budgets. They approximate the Galaxy S's compute within its device budgets. This was decided at the Task 10 review, is binding, and is recorded in plan Task 10.
- Six jobs keep the bots on the six performance cores.
- **Win rate:** wins plus half the draws, over the 400 games.
- **95 % CI:** computed over the 200 pair scores, as `mean ± 1.96·sd/√200`.
- **Points:** gammons count 2, the mother 2 or 3, etc.

### 3.1 Final results (tuned; commits `49c9d15`, `abcc962`)

| Family | Pairing | Win % | 95 % CI | W–L (draws) | Points | Gate | Result |
|---|---|---:|---|---|---|---|:-:|
| Portes | Medium vs Easy | 82.5 | [78.9, 86.1] | 330–70 | 532–86 | ≥ 60 | pass |
| Portes | Hard vs Medium | 58.8 | [54.3, 63.2] | 235–165 | 288–180 | ≥ 55 | pass |
| Portes | Expert vs Hard | 52.5 | [48.2, 56.8] | 210–190 | 251–225 | ≥ 52 | pass |
| Portes | Expert vs Medium | 63.0 | [58.5, 67.5] | 252–148 | 322–165 | (alt. ≥ 60) | (also met) |
| Plakoto | Medium vs Easy | 85.8 | [82.3, 89.2] | 342–56 (2) | 599–79 | ≥ 60 | pass |
| Plakoto | Hard vs Medium | 64.8 | [59.9, 69.6] | 259–141 | 380–172 | ≥ 55 | pass |
| Plakoto | Expert vs Hard | 54.8 | [49.7, 59.8] | 219–181 | 291–242 | ≥ 52 | pass |
| Plakoto | Expert vs Medium | 70.5 | [66.4, 74.6] | 282–118 | 422–160 | (alt. ≥ 60) | (also met) |
| Fevga | Medium vs Easy | 68.5 | [64.0, 73.0] | 274–126 | 309–132 | ≥ 60 | pass |
| Fevga | Hard vs Medium | 63.7 | [59.1, 68.4] | 255–145 | 286–152 | ≥ 55 | pass |
| Fevga | Expert vs Hard | 50.2 | [46.3, 54.2] | 201–199 | 233–219 | ≥ 52, or CI ∋ ≥ 50 % and Expert vs Medium ≥ 60 | pass (alt.) |
| Fevga | Expert vs Medium | 68.8 | [64.7, 72.8] | 275–125 | 322–135 | ≥ 60 (alt.) | pass |

**Reading the Expert gate:** "Expert ≥ Hard within the 95 % CI" is read as the CI's upper bound being ≥ 50 %, so Expert is not significantly worse than Hard. Fevga meets it: the upper bound is 54.2 %. The Portes result of 52.5 % meets the first clause by a narrow margin, and Portes also meets the alternative clause.

**Search depth during the gate games:**
- Expert reached 2-ply in 97 % of its decisions in Portes, 73 % in Plakoto and 51 % in Fevga. The rest timed out after 1-ply.
- Medium fell back to 0-ply in 0.5 % of its Fevga decisions (81 of 16,217).

### 3.2 Baseline (initial profiles and evaluators, desktop budgets)

Labelled run 0. Runs 0b and 0c are partly under concurrent load, from the tuning experiments.

| Family | Medium vs Easy | Hard vs Medium | Expert vs Hard | Expert vs Medium |
|---|---:|---:|---:|---:|
| Portes | 77.0 | **49.3** ✗ | 55.3 | 54.5 |
| Plakoto | 80.8 | **53.5** ✗ | 52.0 | **49.4** |
| Fevga | 65.8 | 56.3 | **51.5** | not recorded (the run was cut off by a session interruption) |

Hard vs Medium failed in Portes and Plakoto. Plakoto's Expert result met the first clause only by its point estimate (52.0 %), and Fevga's would have needed the alternative clause, which failed in Plakoto (Expert vs Medium 49.4 %).

### 3.3 Tuning log

Each row is 400 games (or 800–1000 for fast 0-ply runs), A vs B, with A's win %. "d0" is noiseless 0-ply, and "d1" is noiseless 1-ply with K from 6 to 16. Both run with large budgets, so their results do not depend on timing. The harness was a scratch copy of the evaluators with tunable weights (not committed).

**Diagnosis**

| # | Config | Result | Finding |
|---|---|---|---|
| 1 | Portes Hard vs Medium (noise 0, top 0) | 50.5 % [49.1, 51.9] | Widening K from 6 to 16 adds nothing |
| 2 | Portes Hard vs Medium (noise 0.08, top 0.3) | 49.5 % | With K ≤ 6, top 0.2–0.3 keeps 2 candidates, so Medium's noise barely matters |
| 3 | Portes Hard vs Medium (k 2→3) | 50.0 % | — |
| 4 | Portes Hard (noise 0, top 0) vs Medium | 49.3 % | — |
| 5 | Portes d1 vs d0 | 54.8 % | 1-ply adds little over 0-ply in Portes |
| 6 | Fevga d1 vs d0 / Plakoto d1 vs d0 | 61.8 % / 64.6 % | — |
| 7 | Easy vs d0: Portes / Plakoto / Fevga | 31.5 % / 28.4 % / **54.3 %** | Fevga's evaluator ranked plays worse than noise |

**Evaluator sweeps at 0-ply (tuned vs current)**

| # | Config | Result | Finding |
|---|---|---|---|
| 8 | Portes blots ×5 (blot 0.1, direct 0.2, indirect 0.075) | 39.5 % | The review hint (blots 5–8× under-weighted) does not hold at 0-ply |
| 9 | Portes blots ×8 | 37.3 % | — |
| 10 | Portes direct 0.2 | 47.1 % | — |
| 11 | Portes coordinate sweep, each weight ×0.5 and ×2 (24 runs, 1000 games each) | best: prime ×2 51.8 %, lead ×0.5 51.8 %; worst: bar ×2 45.8 %, lead ×2 46.9 % | Near a local optimum |
| 12 | Portes prime 0.08, lead 4, direct 0.06 | 54.5 % at d0 | — |
| 13 | … the same at **d1** | **48.0 %** | Rejected: hurts at 1-ply |
| 14 | Plakoto coordinate sweep (25 runs) | best: direct ×2 54.9 % | — |
| 15 | Plakoto direct 0.06, indirect 0.02 | 56.1 % at d0 | — |
| 16 | … the same at **d1** | **46.5 %** | Rejected: hurts at 1-ply |
| 17 | Fevga block², head, released, lead (×0.5 / ×2) | 49.0–51.1 % | The existing Fevga terms barely rank plays |
| 18 | Fevga + points held 0.05 / home checkers 0.05 / stacking 0.05 | 59.2 % / 62.2 % / 57.6 % | New terms |
| 19 | Fevga points 0.05, home 0.1, stack 0.05 (beyond 3) | **71.2 %** at d0 | — |
| 20 | Hill-climb around #19: home, points and head ±, stackFrom 2 or 4, outer, block², lead (14 runs) | 46.0–53.2 % | Kept #19 |
| 21 | #19 at **d1** | **61.0 %** | Accepted (commit `49c9d15`) |
| 22 | #19 with borne-off checkers counted as home (otherwise bearing off is penalised) | Fevga 49.9 % / 50.3 % (neutral); Long Nard 60.7 %, Gul Bara 55.5 %, Moultezim 70.5 % vs the old evaluator | Kept, because it is logically correct |

**Profile grid (old Easy unless noted)**

| # | Medium | Pairing (family) | Result |
|---|---|---|---|
| 23 | noise 0.1, top 0.5 | Hard vs Medium (Portes) | 55.3 % |
| 24 | noise 0.1, top 0.5 | Medium vs Easy (Portes) | 71.8 % |
| 25 | noise 0.15, top 0.5 | Hard vs Medium / Medium vs Easy (Portes) | 55.8 % / 69.8 % |
| 26 | noise 0.1, top 1 | Hard vs Medium / Medium vs Easy (Portes) | 58.5 % / 70.8 % |
| 27 | noise 0.2, top 1 | Hard vs Medium / Medium vs Easy (Portes) | 62.0 % / 63.7 % |
| 28 | noise 0.1, top 1 | Hard vs Medium / Medium vs Easy (Plakoto) | 65.8 % / 73.4 % |
| 29 | noise 0.1, top 1 | Hard vs Medium / Medium vs Easy (Fevga, old evaluator) | 60.0 % / 62.3 % |
| 30 | noise 0.15, top 1 | Hard vs Medium / Medium vs Easy (Fevga, old evaluator) | 64.0 % / 55.0 % |
| 31 | noise 0.1, top 1, k 2 | Hard vs Medium / Medium vs Easy (Fevga, old evaluator) | 62.0 % / 59.5 % |
| 32 | noise 0.1, top 0.5, k 2, kMax 12 | Hard vs Medium / Medium vs Easy (Fevga, old evaluator) | 57.3 % / 60.3 % |
| 33 | initial | Medium vs Easy (Fevga, new evaluator) | 66.8 % |
| 34 | noise 0.1, top 1 | Medium vs Easy / Hard vs Medium (Fevga, new evaluator) | 55.8 % / 64.0 % |
| 35 | noise 0.1, top 0.5 | Medium vs Easy / Hard vs Medium (Portes) | 71.8 % / 55.0 % |
| 36 | noise 0.1, top 0.5 | Medium vs Easy / Hard vs Medium (Plakoto) | 78.4 % / 61.0 % |
| 37 | noise 0.1, top 0.5 | Medium vs Easy / Hard vs Medium (Fevga) | 62.3 % / 60.0 % |
| 38 | noise 0.1, top 0.5, k 2 | Medium vs Easy / Hard vs Medium (Portes) | 71.8 % / 54.8 % |
| 39 | noise 0.1, top 0.5, k 2 | Medium vs Easy / Hard vs Medium (Plakoto) | 79.0 % / 60.8 % |
| 40 | noise 0.1, top 0.5, k 2 | Medium vs Easy / Hard vs Medium (Fevga) | 65.5 % / 59.0 % |
| 41 | noise 0.1, top 1, k 2 | vs Easy noise 0.12 / 0.2 / 0.3 (Fevga) | 54.5 % / 62.5 % / **67.8 %** |
| 42 | noise 0.1, top 1, k 2 | Hard vs Medium (Fevga / Portes / Plakoto) | 64.8 % / 58.8 % / 64.5 % |
| 43 | noise 0.1, top 1, k 2 | vs Easy noise 0.3 (Portes / Plakoto) | 82.5 % / 87.0 % |

**Accepted** (commit `abcc962`): Easy noise 0.12 → 0.3, and Medium K 3 → 2 (kMax 6), noise 0.04 → 0.1, top fraction 0.2 → 1.0. Hard and Expert are unchanged. Gate run 1 (§3.1) confirms the change.

**Why this shape:**
- Hard and Medium differ only in noise and top fraction in practice, because widening K beyond 6 adds nothing (#1).
- Medium's noise spreads over all its 1-ply candidates; Portes needs this for a ≥ 55 % margin (#26 vs #23).
- A noisier Easy restores the Fevga margin (#41). Fevga's equity gaps between plays are small, so noise costs more there.
- The legacy floor has room for a noisier Easy: 89.0 % with the old Easy, 85.3 % with the tuned one.
- The 14 labelled tactics still pass at Expert, and the evaluators stay exactly antisymmetric (`test/eval/symmetry_test.dart`).

**Not changed:**
- The hitting and pinning evaluators (#13, #16).
- Hard and Expert profiles. Expert's kMax 32 spends time on 1-ply widening that buys nothing (#1); a smaller kMax would let 2-ply finish more often in Plakoto and Fevga. This is an open lever, and the gates did not need it.

## 4. Legacy floor

`flutter test --run-skipped --tags legacy-bench test/bench/bot_vs_legacy_test.dart`:
- new Easy (7 ms budget) vs legacy `AiPlayer` Easy, seeded per decision;
- 400 Portes games in 200 mirrored pairs, cube off;
- positions are mapped with `toLegacy` / `toCore` in `test/differential/portes_legacy.dart`, and the legacy final is turned into core steps with `PlayTree.pathTo`.

| | Win % | 95 % CI | W–L | Points | Gate |
|---|---:|---|---|---|:-:|
| Tuned Easy (noise 0.3) | **85.3** | [81.7, 88.8] | 341–59 | 540–67 | ≥ 50 ✓ |
| Initial Easy (noise 0.12), before tuning | 89.0 | [86.0, 92.0] | 356–44 | 579–52 | ≥ 50 ✓ |

The legacy Easy is weak because its noise (±0.15) is large against its evaluator's scale (about 0.004 per pip), so it plays close to randomly within its top half.

## 5. Worker responsiveness and the I1 probe (design §10)

`benchmark/worker_bench_test.dart`, asserts off: main-isolate 1 ms timer gaps while the worker decides.

| Load | Requests | Gaps | p50 | p99 | Max | Gaps > 4 ms | Gate |
|---|---:|---:|---:|---:|---:|---:|---|
| Hard, back-to-back searches | 229 | 988 | 1.27 ms | 2.07 ms | 8.13 ms | 2 | p99 ≤ 4, max ≤ 20 ✓ |
| Slowest real-game cascade, Medium (I1 probe, report only) | 3 | 2920 | 1.27 ms | 8.10 ms | 13.46 ms | 45 (1.5 %) | — |

These match the Task 9 figures (Hard p99 about 1.8 ms; cascade p99 6–7.5 ms, max 11–15 ms). The cascade gaps come from GC pauses shared through the isolate group's heap (carried gate (d) below).

## 6. Legacy comparison

| | Legacy (`docs/superpowers/perf/2026-10-01-legacy-baseline.md`) | New |
|---|---|---|
| Medium, time per move | 26.1 s p50, 31.3 s max (UI thread, frozen app) | worst-fixture p95 **3.6 ms** (Long Nard 1-1-1-1), worker isolate; mean 3.5–8.1 ms in the gate games |
| Variants | Plakoto and Fevga played with Portes rules | every variant on the core play tree |

## 7. Carried gates and open items

**Carried gates:**
- **(c), extended.** A device AOT run of the bot benchmarks on the Galaxy S is required before SP3:
  - the `choosePlay` p95 per level × family against the device targets (20/80/300/800 ms);
  - sampled cascades against 2× those targets;
  - the worker gap probe.
  The tournaments assume the desktop gates approximate the device (÷ 3). If the device is slower than that, Expert reaches 2-ply less often, and its margin over Hard (thin in Portes, alternative clause in Fevga) should be re-checked with budgets scaled to the measured ratio.
- **(d) Cascade GC and latency risk.** The worst real-game 1-1 cascades take 1.0–1.5 s on desktop. That time goes to the non-interruptible core tree build and walks, so it may be several seconds on a phone. They also cause main-isolate gap spikes (p99 8.1 ms, max 13.5 ms). The levers are a core-side pruning bound for cascades and less allocation in the cascade walks. SP3 must plan for slow Gul Bara bot turns (pacing, "thinking" UI, nothing urgent queued behind a cascade).

**Open items:**
- The Expert gate margin is thin. Fevga passes only on the alternative clause, and Portes passes the first clause at 52.5 %. Levers, untried:
  - a smaller Expert kMax, to leave more time for 2-ply;
  - a wider 2-ply reply set.
- The hitting and pinning evaluators are tuned for 0-ply. The weight changes that help at 0-ply hurt at 1-ply, so evaluator work should be judged at 1-ply.
- Under the 6-job tournament load, a decision's maximum time exceeded its budget by up to 2× (for example, Fevga Medium max 47 ms against 27). The asserts-off benchmarks on a quiet machine stay within the gates. This is load and E-core scheduling, not a search overrun.
- Tournament results depend on timing (budgets), so gate numbers vary by a few points between runs and machines. The smoke test pins determinism with ample budgets.
