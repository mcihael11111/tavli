# SP2 — Bot (`tavli_bot`) Design

**Date:** 2026-10-02
**Status:** Draft. Written under the user's standing instruction to build the approved program end to end.

**Parents:**
- `2026-10-01-gameplay-rewrite-program-design.md`: §3.3 budgets, §4.4 bot, §6 SP2 row, and the "SP2 inputs from the SP1 review"
- `2026-10-01-sp1-game-core-design.md`, which defines the core API this bot consumes

**Deliverable:** `packages/tavli_core` gains a small play-enumeration API. `packages/tavli_bot` becomes a pure-Dart bot with these parts:
- an evaluator per game family
- a time-budgeted search
- a difficulty model
- cube decisions
- teaching analysis
- a long-lived worker isolate

The SP2 scope ends at a tested worker API. The app starts calling it in SP3.

---

## 1. Goals and exit criteria

1. **The UI isolate never searches.** Every bot decision runs in a long-lived worker isolate. The app only sends requests and awaits replies.
2. **Budgets (p95, asserts off).** SP2 exits on the desktop numbers; the device gate below is still required before SP3.

| Level | Galaxy S target (spec §3.3) | Desktop gate (SP2 exit) |
|---|---|---|
| Easy | ≤ 20 ms | ≤ 7 ms |
| Medium | ≤ 80 ms | ≤ 27 ms |
| Hard | ≤ 300 ms | ≤ 100 ms |
| Expert (Pappous) | ≤ 800 ms | ≤ 270 ms |

   - The desktop gate is the device target ÷ 3, the assumed desktop→phone slowdown.
   - The Galaxy S AOT run joins carried gate (c) and must pass before SP3.
   - Gul Bara **cascade** turns have their own budget: ≤ 2× the level's budget. They are measured separately, because one cascade root can take up to about 0.4 s in the worst case (SP1 report).
3. **Plays legally and correctly in every variant.** It uses the core play tree for every variant's rules, which fixes the legacy bot playing Plakoto and Fevga with Portes rules.
4. **Strength ordering is verified by headless tournaments.** Fixed seeds, 400 games per pairing per family (hitting = Portes, pinning = Plakoto, running = Fevga). The gates:
   - Medium beats Easy ≥ 60 %.
   - Hard beats Medium ≥ 55 %.
   - Expert beats Hard ≥ 52 %, or Expert ≥ Hard within the 95 % CI and Expert beats Medium ≥ 60 %.
   - New Easy beats the legacy app bot at Easy ≥ 50 %. This is a regression floor and is app-level.
5. **Cube decisions** are sane: test suites cover clear doubles, clear takes, clear passes and too-good positions.
6. **Teaching analysis** answers "how good is each next step / this play" within the Medium budget.

**Out of scope:**
- neural-network evaluation
- personalities beyond difficulty (pacing and dialogue stay in the app, SP3)
- the online bot backfill (SP4)
- tuning the evaluator beyond passing the strength gates

---

## 2. Core additions (in `tavli_core`)

The SP1 review found one gap: bots choose *final positions* but must submit `SubmitPlay(steps)`.

- **`PlayTree.plays()`** returns `List<Play>`, one per legal final. Each `Play` holds `Position final` and `List<Step> steps`, the steps being one canonical path (first found). It is eager trees only; lazy cascade trees throw `StateError`.
- **`PlayTree.pathTo(Position final)`** returns `List<Step>?`. It works on lazy cascade trees too, using a DFS over `nextSteps` with memo.
- **`CascadeWalker`**, for lazy trees, gives:
  - `sampleCompletions(int n, Random rng)`, which returns up to *n* distinct complete plays with their steps;
  - `greedyCompletion(score)`, which picks each next step by the best score of the child position.

  It never enumerates finals.

---

## 3. Package layout (`tavli_bot`)

```
lib/tavli_bot.dart                 barrel
lib/src/eval/evaluator.dart        Evaluator interface + EvalResult
lib/src/eval/features.dart         shared feature extraction over BoardView
lib/src/eval/hitting_eval.dart     Portes/Tavla/Short Nard/Shesh Besh
lib/src/eval/pinning_eval.dart     Plakoto/Tapa/Mahbusa
lib/src/eval/running_eval.dart     Fevga/Moultezim/Gul Bara/Long Nard/Tawla 31
lib/src/eval/race_eval.dart        no-contact race (all families)
lib/src/search/search.dart         chooseFinal (0-ply, 1-ply top-K, widening, budget)
lib/src/search/cascade_search.dart cascade decisions (sample/greedy)
lib/src/level/bot_level.dart       BotLevel + LevelProfile (K, depth, noise, top-fraction)
lib/src/cube/cube_policy.dart      offer/take decisions
lib/src/teach/analysis.dart        step and play quality
lib/src/worker/protocol.dart       BotRequest / BotReply (plain data, sendable)
lib/src/worker/bot_worker.dart     long-lived isolate host + client
test/...  benchmark/...  tool/tournament.dart (headless tournaments)
```

**Purity allowlist** (extended deliberately, per SP0 note): `dart:core/async/collection/math/typed_data/isolate` + `package:tavli_core/` + itself.

---

## 4. Evaluation

**`Evaluator`:** `EvalResult evaluate(BoardView p, Side me, VariantRules r)`. `EvalResult` holds:
- `winProb` (0..1) for `me`
- `gammonProb` (0..1), the probability `me` wins a gammon or more
- `lossGammonProb` (0..1)
- `equity`, computed as `(2·winProb − 1) + (gammonProb − lossGammonProb)`; positive is good for `me`

**Dispatch:** a no-contact race goes to `race_eval`; otherwise the variant's family evaluator decides.

**Features:** these are ported from the legacy `board_evaluator.dart`, `plakoto_evaluator.dart` and `fevga_evaluator.dart`, then **re-derived over player-relative pips**:
- pip difference
- borne off
- bar
- home-board points
- blots weighted by direct and indirect shot count
- made points
- prime length
- anchors

**Family-specific terms:**

| Family | Terms |
|---|---|
| pinning | pinned checkers (own/opponent), mother safety, pin value by location |
| running | blockade length in front of the opponent, head escape (Long Nard), runner progress (sole-runner variants), primes the rules forbid scored as 0 |

**`race_eval`:** a pip-count race formula (Keith-style effective pip count with a wastage adjustment), mapped to `winProb` through a logistic on the effective lead. Gammon chances are estimated from the pips needed to bear in.

**Mapping scores to probabilities:** feature scores map to probabilities through a logistic with per-family constants, tuned only enough to pass the strength gates. Tuning harness: `tool/tournament.dart`.

---

## 5. Search

**`chooseFinal(state inputs, LevelProfile, budget, rng)`:**
1. `plays = tree.plays()`. If there is only one, return it immediately.
2. **0-ply:** score every play with the evaluator (opponent to move: use `−equity` of the opponent's view, or evaluate from `me` with the opponent on roll).
3. If `profile.depth == 0`, go to selection.
4. **1-ply on the top-K by 0-ply:** for each candidate final, the expectation over the 21 rolls (weights 1/36, 2/36) of the opponent's best reply, chosen greedily by the opponent's own 0-ply evaluation. The value is `−equity` from the opponent's perspective after their reply.
   - Opponent replies use the core generator. Cascade replies use `CascadeWalker.greedyCompletion`.
5. **Iterative widening:** K starts at `profile.k`. While budget remains, K doubles up to `profile.kMax`.
6. **Expert only:** 2-ply on the top 2 1-ply candidates if budget remains, using the opponent's top-3 replies per roll. Otherwise keep the 1-ply result.
7. **Selection:**
   - add Gaussian-free noise: uniform ± `profile.noise` on equity;
   - keep the top `profile.topFraction`;
   - pick deterministically from the seeded rng.

**Budget enforcement:** checked between candidates and rolls. The best answer so far is always available. The budget clock is a `Stopwatch` inside the worker.

**Cascade turns:**
- `sampleCompletions(n)` with *n* from the profile (Easy 8, Medium 24, Hard 64, Expert 128), scored at 0-ply, plus one `greedyCompletion`.
- Best by 0-ply.
- No 1-ply.

**Level profiles** (initial values, tuned against the strength gates):

| Level | depth | k → kMax | noise | topFraction |
|---|---|---|---|---|
| easy | 0 | — | 0.12 | 0.5 |
| medium | 1 | 3 → 6 | 0.04 | 0.2 |
| hard | 1 | 6 → 16 | 0.01 | 0.05 |
| expert | 1 + 2-ply top-2 | 8 → 32 | 0 | 0 (best) |

The app's `easyWithHelp` maps to `easy` plus teaching analysis.

---

## 6. Cube policy

These apply only where the variant's cube is available and enabled. The cube is not allowed in the Crawford game; core enforces that.

| Decision | Rule |
|---|---|
| **Offer** (before rolling) | Take the 0-ply EvalResult and, for Hard/Expert, a 1-ply average over the 21 rolls. Offer when `winProb ≥ offerThreshold`, unless the position is *too good*: `gammonProb` high enough that playing on for a gammon is worth more. Market-window style thresholds: offer at winProb ≥ 0.68; too good at winProb ≥ 0.85 with gammonProb ≥ 0.35 |
| **Take** | Take iff the taker's `winProb ≥ 0.25`, adjusted for gammon risk: `winProb + 0.5·lossGammonProb_adj ≥ 0.25` |
| **Easy** | Never offers. Takes iff `winProb ≥ 0.20` |

Tested by labelled positions: clear double, clear no-double, too good, clear take, clear pass.

---

## 7. Teaching analysis

`analyzeTurn(start position, side, dice, ctx, steps so far)` returns:

**Per next step:**
- `bestEquityAfter`: the best final reachable through that step, by 0-ply, or 1-ply when within budget
- quality relative to the best step:

| Quality | Equity gap |
|---|---|
| best | ≤ 0.01 |
| good | ≤ 0.03 |
| acceptable | ≤ 0.08 |
| poor | > 0.08 |

**Per complete play:** `equityLoss` against the best play.

**Budget:** Medium. Cascade turns use the sampled completions.

---

## 8. Worker

**Protocol:**
- **`BotRequest`** is plain sendable data (no `GameState`, no trees). Fields:
  - `id`, `kind`, `variant`, `position`, `side`, `dice`, `cascade`, `context`, `cube`, `level`, `seed`, `budgetMs`, `steps` (teaching)
  - `kind` is one of `choosePlay`, `offerDouble`, `takeDouble`, `analyze`
- **`BotReply`** holds:
  - `id`
  - `steps`, or a bool decision, or an analysis
  - `stats`: `{evaluated, depthReached, elapsedUs, timedOut}`

**`BotWorker`:**
- `spawn()` once, then a `warm()` request (JIT/AOT warm-up of the evaluator on a dummy position).
- `request(BotRequest) → Future<BotReply>`.
- **Supersede:** `cancel(id)`, or a newer request with `supersedes: id`, drops a stale request. The worker checks a cancel flag between candidates.
- `dispose()`.
- **Fault handling:** errors come back as `BotError` replies and never kill the isolate. If the isolate does die, the client respawns it once and fails the pending requests.

**Direct use:** the same `Bot.decide(BotRequest) → BotReply` pure function runs in-process for tests, tournaments and the SP4 server. The worker is just a host for it.

---

## 9. Testing

| Suite | Content |
|---|---|
| Core additions | `plays()`/`pathTo` round-trip: applying `steps` from the start reproduces `final`, for every play in sampled positions × 21 rolls in all variants; cascade sample/greedy return complete legal plays |
| Evaluator | Symmetry: mirrored positions give opposite equity. Monotonicity sanity: more borne off or a better race scores better. Race formula against known race positions. Per-family feature unit tests |
| Search | Single-play shortcut; budget respected (a stub evaluator with sleeps gives `timedOut` and a returned answer); determinism with a fixed seed; Expert picks the known-best play in a set of labelled tactical positions per family (hits, primes, pins, safe bear-off) |
| Cube | Labelled positions per decision type |
| Teaching | Qualities ordered; best step has a best-quality child |
| Worker | Spawn/warm/request/reply; cancellation; supersede; error reply; respawn after crash; no UI-isolate work (the request returns while the main isolate stays responsive: measure event-loop latency ≤ 4 ms during a Hard search) |
| Purity | Allowlist |
| Benchmarks | Per level × family p95 within the desktop gate (asserts off runner, plus a `dart test` allowance as in SP1); cascade budget |
| Tournaments | `tool/tournament.dart` headless runner (seeded, parallel isolates). Gate results recorded in the SP2 report. CI runs a 40-game smoke (no gate); the full run is the SP2 exit |
| Legacy floor | App-level opt-in test: new Easy vs legacy Easy, 400 Portes games, ≥ 50 % |

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| Hand-tuned evaluator too weak to separate the levels | Levels also differ by depth/K/noise, so separation comes mostly from search. If a gate fails, tune the constants against the tournament tool. Gates allow CI-based acceptance for Expert vs Hard |
| 1-ply cost on a phone | Iterative widening guarantees an answer at the deadline. Desktop gates are ÷ 3 of the device budget. The device run is gate (c) |
| Cascade cost | Separate budget; sampled, never enumerated. The worst-case root build is already bounded by core caps |
| Isolate message cost | Lean `BotRequest` (about 100 bytes), never `GameState` |
