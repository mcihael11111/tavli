# SP1 — Game Core (`tavli_core`) Design

**Date:** 2026-10-01
**Status:** Draft. Written under the user's standing instruction to build the approved program end to end.
**Parents:**
- `2026-10-01-gameplay-rewrite-program-design.md` §4.3 and §6 (SP1 row)
- `2026-10-01-sp1-variant-rules-matrix.md`: **normative rules**, APPROVED with all D1–D22 recommendations

**Deliverable:** `packages/tavli_core`, a pure-Dart rules engine and game model for all 13 variants. It has:
- no Flutter
- no I/O
- no randomness inside the reducer
- an allowlist import guard (from SP0)

---

## 1. Goals and exit criteria

1. **Correct rules for all 13 variants.** Every rule in matrix §3–§4 (as resolved by §6) is implemented, and each one has at least one test that cites its rule ID (G1–G9, D1–D22, or `§4.x/<topic>`).
2. **One play-generation call per roll.** It returns a play tree that answers every UI and bot question in O(1)–O(k):
   - Which steps are legal next?
   - Is this prefix a complete play?
   - Is the move forced?
3. **A deterministic reducer.** `reduce(state, action)` returns a new state plus events, or a `RuleViolation`. Replaying an action log always reproduces the same state.
4. **Match layer:** single games, matches to N with Crawford, Tavli/Tavla-style marathons, and Tawla 31 to 31 points.
5. **Performance:** legal-play generation ≤ 2 ms p95 for every variant, including doubles and Gul Bara cascades (desktop JIT, `TAVLI_BENCH_SCALE` applies).
6. **Verification:**
   - rulebook scenario tests;
   - a naive **reference oracle** generator, differentially fuzzed against the fast generator;
   - **≥ 100,000 random games per variant**, with invariants checked, recorded once at SP1 exit (CI runs a scaled-down count);
   - a Portes differential against the legacy generator.

**Out of scope:**
- the bot and evaluation (SP2)
- adapters to the app's `BoardState`, `GameVariant` and `GameResult` (SP3, under `lib/gameplay/`)
- the online server (SP4)
- Tawla 'Ada (a later stage, per D20-B)

---

## 2. Package layout

```
packages/tavli_core/lib/
  tavli_core.dart                 public barrel (exports only the API below)
  src/variant/                    Variant enum, VariantRules model, catalog (13 configs)
  src/board/                      Side, geometry, Position (immutable) + MutablePosition
  src/rules/                      step legality, turn context, step validators, play filters, scoring, mother rule
  src/play/                       Step, Play, PlayTree, PlayGenerator, ReferenceGenerator (oracle)
  src/game/                       GameState, GameAction, GameEvent, RuleViolation, GameResult, reduce()
  src/match/                      MatchConfig, MatchState, match reducer
  src/serial/                     JSON codecs, GameLog, replay
packages/tavli_core/test/         mirrors src/; scenario tests are named by rule ID
packages/tavli_core/benchmark/    budgeted benchmarks (tagged `bench`)
packages/tavli_core/dart_test.yaml   tags: fuzz (extended timeout), bench
```

Files stay focused on one responsibility each, and should be ≤ about 300 lines. If a file grows past that, split it by responsibility.

---

## 3. Data model

### 3.1 Coordinates

Coordinates are **player-relative pips**, per matrix §1:
- Each side counts its own points 24 → 1; **0 = borne off** and **25 = bar**. A move goes `p → p − die`, and the home board is pips 1–6.
- `Geometry` converts my pip to the opponent's pip for the same physical point:
  - **opposing direction:** `25 − p`;
  - **same direction:** `p > 12 ? p − 12 : p + 12`.
- Only pips 1–24 map; 0 and 25 have no physical point.

### 3.2 `Position`

An immutable value type holding, for each side:
- a `Uint8List(26)` of checker counts by own pip (index 0 = off, 25 = bar);
- a `pinned` bitmask (bit *p* set ⇒ this side's checker on its pip *p* is pinned under an opposing checker).

Invariants:
- 15 checkers per side;
- at most one pinned checker per point;
- a point never holds checkers of both sides except a pinned-plus-pinner pair.

Equality is structural. `hashCode` is computed once, cached, and **web-safe** (30-bit mixing). Dedup uses `HashSet<Position>` with full equality, which replaces the program spec's 64-bit Zobrist idea so that core stays correct on every Dart platform.

`MutablePosition` gives make/unmake for the generator, and `freeze()` produces a `Position`.

**Who controls a point** (contact helpers):
- `controller(me, myPip)` is the side on top. For a pinned pair, that is the pinner.
- `isOpenFor(side, pip, contact)`:
  - **hit:** open if the opponent has ≤ 1 checker there;
  - **pin:** open if the opponent has ≤ 1 checker there, and that checker is not itself pinning one of mine;
  - **block:** open if the opponent has 0 checkers there.
- A pinned checker of mine sitting under the opponent closes that point to me (matrix §4.2 "Blocked point").

**Counting helpers:** `pipCount(side)`, `allHome(side)`, `borneOff(side)`, `checkersOnBoard(side)`.
- A pinned checker counts toward its owner's totals and pips.
- `allHome` treats pinned checkers inside home as home, but the bear-off gate (D11) is separate.

### 3.3 Variant rules

`VariantRules` follows matrix §7 exactly. The fields are:
- **Basics:** `Layout`, `Direction`, `Contact`, `OpeningProcedure`, `NextGameStarter`
- **Optional rule blocks:** `HeadRule?`, `Advancement?`, `PinRules?`, `HitRules?`, `Cascade?`
- **Always present:** `PrimeRules`, `DoublesMode`, `Scoring`, `CubeRules`, `MatchDefaults`

The `Variant` enum has the 13 app variants. `Variant.rules` reads the const catalog. **The catalog is the only place per-variant behaviour is decided.** The engine branches on rule fields, never on variant names.

Catalog values, from matrix §2/§4 with the §6 resolutions:

| Variant | Layout / Dir / Contact | Opening | Next game | Special | Doubles | Scoring | Cube |
|---|---|---|---|---|---|---|---|
| portes | std / opp / hit | play opening dice | previous winner | — | four | 1/2, triple counts as 2 | none |
| plakoto | stack / opp / pin | play | previous winner (draw → opening roll) | mother 2pt, deferred exception, both pinned = draw 0–0; no bear-off while pinned | four | 1/2 | none |
| fevga | diag / same / block | play | previous winner | runner to pip ≤ 11; primes D12-A (end of turn); leave-a-move D13-A | four | 1/2 | none |
| tavla | std / opp / hit | winner re-rolls | opening roll | no hit-and-run in home (D4); no-waste bear-off (D5) | four | 1/2 | none |
| tapa | stack / opp / pin | re-roll | opening roll | as plakoto; both pinned = 1 point each | four | 1/2 | none |
| moultezim | diag / same / block | re-roll | opening roll | runner to pip ≤ 11; ≤ 4 own points in opp start quarter (pips 7–12); can't close all of own pips 19–24 | four | 1/2 | none |
| gulBara | diag / same / block | re-roll | opening roll | — | cascade after first 3 rolls of the game; failure → opponent plays remainder | 1/2 | none |
| longNard | diag / same / block | play | opening roll | head 1/turn; first-turn 3-3/4-4/6-6 → 2; per-step no six-block trapping all 15 | four | 1/2 | off (tournament option later) |
| shortNard | std / opp / hit | play | opening roll | — | four | 1/2, koks 3 | on, Crawford; Jacoby/beaver/auto off |
| sheshBesh | std / opp / hit | play | opening roll | — | four | 1/2, Turkish mars 3 | optional, off by default |
| mahbusa, mahbusaArab | stack / opp / pin | play | opening roll | as plakoto (mother "misk" 2, draw 0) | four | 1/2 | none |
| tawla31 | diag / same / block | play | opening roll | runner to pip ≤ 18; no prime limits | four | checkers remaining | none; match fixed to 31 |

---

## 4. Play generation

### 4.1 Steps and plays
- **`Step`** = `(from, to, die)`, plus derived flags `hit`, `pin` and `bearOff`. The die is part of a step's identity, so overshoot bear-offs with different dice stay distinct.
- **`Play`** = an ordered list of steps.

### 4.2 `TurnContext`

Per-turn state that the hooks read:
- head departures this turn
- whether this is the side's first turn
- home-board points where a hit happened this turn (Tavla D4)
- the active runner (Advancement)
- the cascade queue

### 4.3 `StepValidator`s

These are pure predicates, compiled from the rules:
- **bar-first entry:** while I have checkers on the bar, every step must enter from the bar (25)
- **bear-off gate:** G5, plus D11 (no bear-off while one of my checkers is pinned)
- **G6 overshoot rule**
- **head rule** (D18)
- **advancement / sole runner:** until the runner passes its threshold, only that checker may move. Under EOPT a die the runner cannot use is lost; this falls out of max-dice over the constrained tree.
- **per-step six-block** for Long Nard (D19-A)
- **Tavla no hit-and-run** in home (D4): no checker may leave a home point where I hit this turn

### 4.4 `PlayGenerator.generate(position, side, dice, ctx)`
1. **Search.** Depth-first search with make/unmake over each distinct die order (both orders for non-doubles, one for doubles). For cascades, it uses the fixed ordered queue.
2. **Collect** every complete sequence (a node with no legal continuation, or with all dice used) together with its final position.
3. **G4 max-dice.** Keep only sequences using the maximum number of dice. If that maximum is 1 for a non-double roll and either die alone is playable, keep only plays of the higher die.
4. **Play filters.** Each removes plays only while at least one play survives:
   - **Tavla no-waste** (D5): most checkers borne off, then least wasted pips;
   - **Fevga/Moultezim end-of-turn prime rules** (D12-A, D14-B);
   - **Fevga leave-a-move** (D13-A).

   For leave-a-move, the opponent has a move for *some* roll if and only if some die value 1–6 gives them a legal first step. That is ≤ 6 single-step checks per candidate, with early exit.
5. **Legal finals and the tree.** The legal final positions are the deduplicated set of finals that survive. The **`PlayTree`** is the prefix trie of *every* surviving sequence whose final is in that set. This lets the UI enter a play in any valid step order. The trie nodes expose:
   - `nextSteps`
   - `child(step)`
   - `isComplete`
   - `finalPosition`
   - `isForced`, true when exactly one legal final exists

An empty tree means no legal play: the turn passes (G9).

**Cascade (Gul Bara).** The generator plays the ordered queue (*d* ×4, *d*+1 ×4, … 6 ×4). Within each number it plays as many as possible. At the first number that can't be played in full, it stops and reports the `remainder` dice (D16-B).

**Cascade trees are lazy** (decided 2026-10-01 after measurement). Early-game cascades reach 10⁵–10⁶ distinct finals and take 0.3–100 s to enumerate. So for cascades:
- A memoized search `maxPlayable(position, ctx, queueIndex)` stops early once the full queue is reachable. It gives `diceUsed` and `remainder` up front.
- Each node computes `nextSteps` on demand: the steps whose continuation still reaches `diceUsed`.
- `finals` is not materialized for cascades; `isForced` is computed lazily or reported as false.

This is sound because Gul Bara has no play filters (D17), so G4 is the only play-level rule. Normal rolls keep the eager tree, which the D5/D12/D13/D14 filters need.

**Game-ending steps** (matrix addendum A4) terminate a sequence and count as using all dice.

**SP2 note:** the bot cannot enumerate cascade finals, so it must sample or play greedily on cascades.

### 4.5 `ReferenceGenerator` (test oracle)

A deliberately naive implementation:
- It copies the immutable position at every step (no make/unmake).
- It enumerates all permutations of the dice multiset.
- It filters in a different code path.

It shares only the single-step legality predicates. Differential fuzzing on random reachable positions asserts that both generators produce identical **legal-final sets** for every roll. This catches search, dedup, max-dice and filter bugs that a single implementation would hide.

---

## 5. Game model and reducer

### 5.1 `GameState` (immutable)

- `variant`
- `position`
- `sideToMove`
- `phase`: one of `opening`, `awaitingRoll`, `cubeOffered`, `moving`, `gameOver`
- the current roll
- `rollIndex` (the game roll counter, used for the Gul Bara cascade start)
- per-side first-turn flags
- `TurnContext`
- the current `PlayTree` node plus the steps taken so far (for undo)
- `cube` (value, owner, offered by)
- `pendingRemainder` (Gul Bara)
- `result`

The mother rule (D8) needs no stored trigger. It is evaluated statelessly from the position after every step:
- **Both mothers pinned:** draw.
- **One mother pinned and the pinner's start empty:** the pinner wins.

That covers the immediate case (a), the deferred case (b) and the draw.

### 5.2 Actions

`GameAction` is a sealed class:
- **Rolls:** `RollOpening(dieA, dieB)`, `RollDice(d1, d2)`
- **Moving:** `Step(from, to, die)`, `UndoStep`, `CommitPlay`
- **Cube:** `OfferDouble`, `Take`, `Drop`
- **Ending:** `Resign(side)`, `Timeout(side)`

Dice always arrive as data. Core has a `DiceRoll.random(Random)` helper (`dart:math`), but the reducer never calls it.

### 5.3 `reduce(state, action)`

`reduce` returns `GameUpdate(state, List<GameEvent>)` or a `RuleViolation(code, message)`. It never throws on bad input.

**Opening:**
- `RollOpening` with equal dice re-rolls (G7).
- With D1-A, the winner moves with the dice `{dieA, dieB}`.
- With D1-B, the winner moves next to `awaitingRoll`.

**Rolling:**
- `RollDice` is accepted only in `awaitingRoll`.
- It builds the tree: an empty tree means `TurnPassed`; otherwise the phase becomes `moving`.

**Steps and committing:**
- `Step` must be in `node.nextSteps`. Applying it emits `CheckerMoved` (with hit, pin or bear-off).
- **After every step, the reducer runs the game-end checks:**
  - all 15 borne off;
  - mother rule D8: immediate end, a deferred trigger, or a draw.
- `UndoStep` pops a step.
- `CommitPlay` requires `node.isComplete`. The turn then passes. With Gul Bara, a non-empty `pendingRemainder` gives the opponent a `moving` phase over the remainder before their own `awaitingRoll`.

**Cube:**
- `OfferDouble` is valid only in `awaitingRoll`, when the variant allows a cube, the Crawford game is not in progress, the side may double, and the value is < 64.
- `Take` doubles the value and gives the taker ownership.
- `Drop` ends the game at the current value.

**Ending:** `Resign` ends the game at the single-game value. Per-variant resign levels can come later.

### 5.4 Scoring (`GameResult`)

`GameResult` holds the winner (or null for a draw), a `kind`, and `points`:

| Kind | Points | When |
|---|---|---|
| `single` | 1 | default |
| `gammon` | 2 | loser has borne off none |
| `backgammon` / koks / Turkish mars | 3 | only where `Scoring.backgammon` is set. Short Nard: the loser has a checker on the bar or in the winner's home. Shesh Besh: the loser still has checkers in the winner's home. Portes and Tavla cap at 2 |
| `mother` | 2 | mother rule |
| `draw` | 0 each, Tapa 1 each | both mothers pinned |
| `checkersRemaining` | 1–15 | Tawla 31 |

Points are multiplied by the cube value where a cube applies.

### 5.5 Events

`GameEvent` is a sealed class:
- `OpeningRolled`, `DiceRolled`
- `CheckerMoved`, `StepUndone`
- `PlayCommitted`, `TurnPassed`, `RemainderPassed`
- `CubeOffered`, `CubeTaken`, `CubeDropped`
- `GameEnded(result)`

These are the only things SP3's board animates.

---

## 6. Match layer

**`MatchConfig`** holds:
- the variant sequence: a single variant, or a marathon cycle such as `[portes, plakoto, fevga]`;
- the target (`null` for a single game);
- the Crawford flag;
- the next-game starter, taken from the variant rules.

**`MatchState`** holds the scores, the game index, the current `GameState`, the history and the Crawford state.

`reduceMatch(match, MatchAction)` handles two kinds of action:
- **`MatchAction.game(GameAction)`** is passed to the current game. On `GameEnded`, it adds the points and checks the target.
- **`NextGame`** starts the next variant in the cycle:
  - the previous winner starts if the rules say so (D2);
  - otherwise the next game opens with a roll;
  - a Plakoto draw always goes to an opening roll.

Tawla 31 adds `checkersRemaining` points and has its target fixed at 31.

---

## 7. Serialization

Versioned JSON with `schemaVersion = tavliCoreSchemaVersion`:
- `GameAction` and `MatchAction` ⇄ JSON
- `GameState` and `MatchState` ⇄ JSON (play trees are rebuilt, never serialized)
- `GameLog`: header (schema, config, starting state) plus the action list

`replay(log)` folds `reduceMatch` over the actions. Determinism is a tested property:

`replay(log(state)) == state` for fuzzed games.

Readers reject unknown schema versions.

---

## 8. Testing

| Suite | Content | Where / tag |
|---|---|---|
| Model | Geometry round-trips; Position invariants, equality/hash, JSON; catalog asserts each variant's decided values (one test per D-number) | default |
| Rule scenarios | One `group` per variant. Hand-built positions for every rule in matrix §3–§4. Test names start with the rule ID, e.g. `D19 six-block trapping all 15 is illegal mid-turn` | default |
| Generator | Play counts on known positions. Max-dice/higher-die. Dedup. Tree queries. Cascade remainder | default |
| Oracle differential | Random reachable positions × all 21 rolls; fast vs reference legal-final sets | default (small N) + `fuzz` |
| Reducer | Full phase machine; every `RuleViolation` code; events; undo; pass; mother timing; cube; resign | default |
| Match | Starter rules, marathon rotation, Crawford, Tawla 31 to 31 | default |
| Fuzz | Random legal games per variant with invariants after every action: 15 checkers each, no illegal overlap, pip counts consistent, terminates within a cap, result valid, replay determinism. N = `TAVLI_FUZZ_GAMES` (CI 300; SP1 exit run 100,000 per variant, recorded in the SP1 report) | `fuzz` |
| Portes differential | App-level test: on the legacy initial-layout positions, legacy `MoveGenerator` final-position sets equal core's (index mapping per matrix §1) | app `test/differential/`, default |
| Benchmarks | Generation p95 ≤ 2 ms per variant (worst-case doubles and cascade fixtures). Reducer `Step` ≤ 50 µs p95 | `bench`, run by CI with scale |

**TDD discipline:** every task writes failing tests first. Where a test cites a source rule, its expected value comes from the matrix, never from running the code.

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| Hooks interact in ways the matrix doesn't spell out (e.g. sole runner plus G4 in Fevga) | The oracle shares predicates but not search. Ambiguities found while coding are written up as matrix addenda and flagged to the user, never silently chosen |
| Leave-a-move cost | ≤ 6 single-step checks per candidate with early exit; covered by a benchmark |
| Gul Bara remainder chains | A cap: a remainder can't itself spawn a further remainder beyond the opponent's first failure (D16-B). A fuzz invariant checks termination |
| Web-safety | No 64-bit hashing; ints stay in safe range; core compiles for all platforms (CI analyze) |
| Dedup allocation pressure (every leaf is frozen before dedup) | If Task 17 benchmarks show pressure, add a web-safe incremental 30-bit XOR-Zobrist hash maintained in `MutablePosition` add/remove/setPinned, so duplicates are rejected before freezing |
