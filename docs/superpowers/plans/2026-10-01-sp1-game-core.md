# SP1 Game Core (`tavli_core`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `packages/tavli_core`, a pure-Dart rules engine for all 13 variants. It covers:
- play-tree generation (one call per roll)
- a deterministic reducer, plus the match layer and serialization

It is verified by:
- rule-ID scenario tests and differential testing against a naive oracle
- fuzzed games, benchmarks with budgets, and a differential test against the legacy Portes generator

**Architecture:** see `docs/superpowers/specs/2026-10-01-sp1-game-core-design.md`. The rules source is `docs/superpowers/specs/2026-10-01-sp1-variant-rules-matrix.md`, which was APPROVED with every §6 recommendation (**R**) binding.
- The engine works in player-relative pips: 0 = borne off, 25 = bar, home = 1–6.
- Every per-variant difference is data in one catalog, plus a small set of named hooks.

**Tech Stack:** Dart 3.11 (pure), `package:test`, and `tavli_testkit` (`measure`, `withinBudget`, `findForbiddenImports`).

**How this plan specifies work.** This is an algorithmic engine, so the plan gives each task:
- the exact public API (names and signatures are binding);
- the file layout;
- **concrete test cases** with positions, dice and expected results, cited to rule IDs;
- notes for the non-obvious semantics.

Implementers write the tests first, exactly as listed (more are welcome), then implement. If a listed expectation seems to contradict the matrix, **stop and report it**. Never change an expectation to match the code.

**Conventions:**
- **Working directory:** `/Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli` (git root). Branch `rewrite/gameplay`. Never push.
- **PATH:** prefix commands with `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" &&`.
- **Package checks:** `cd packages/tavli_core && dart test`, plus root `dart analyze --fatal-infos` and `dart format --set-exit-if-changed packages`.
- **Imports:** `tavli_core` may only import `dart:core`, `async`, `collection`, `convert`, `math`, `typed_data` and itself (SP0 purity test). No `package:meta`, no `package:collection`.
- **File size:** one responsibility per file, ≤ about 300 lines. Split by responsibility if one grows.
- **Commits:** one per task (or per sub-step where noted), with the message given. Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Stage files explicitly.
- **Rule IDs:** test names start with the rule ID, e.g. `test('G6 bear off from highest pip when die exceeds it', ...)`.
- **Board access** (added after the Task 1–3 review):
  - Read-only rule code takes the public **`BoardView`** interface, which both `Position` and `MutablePosition` implement. This applies to validators that only read, play filters, `checkGameEnd`, and the SP2 evaluators.
  - Only make/unmake code takes `MutablePosition`.
  - The reducer and tests build start positions with **`Position.forRules(rules)`**.
  - `freeze()` validates invariants in debug builds.
  - `Position.fromJson` throws only `FormatException`.

### Test notation used below

`pos(one: {24: 2, 13: 5, 8: 3, 6: 5}, two: {...}, offOne: 0, offTwo: 0, barOne: 0, barTwo: 0, pinnedOne: {}, pinnedTwo: {})` builds a `Position` from **player-relative** pip maps, with any omitted checkers implied borne off. It is the `Position.fromPips` factory in Task 3.

`S.one` and `S.two` are `Side.one` and `Side.two`.

"Finals" means the set of legal final positions returned by `PlayTree.finals`.

---

## File structure

```
packages/tavli_core/
  dart_test.yaml
  lib/tavli_core.dart                          barrel
  lib/src/board/side.dart                      Side
  lib/src/board/geometry.dart                  Geometry (pip mapping per Direction)
  lib/src/board/position.dart                  Position (immutable), Position.fromPips, JSON
  lib/src/board/mutable_position.dart          MutablePosition (make/unmake), freeze()
  lib/src/variant/variant.dart                 Variant enum (+ .rules)
  lib/src/variant/variant_rules.dart           VariantRules + nested rule classes + enums
  lib/src/variant/catalog.dart                 const catalog for all 13
  lib/src/play/step.dart                       Step, AppliedStep
  lib/src/rules/turn_context.dart              TurnContext
  lib/src/rules/step_rules.dart                single-step legality + apply/undo
  lib/src/rules/step_validators.dart           head, advancement, six-block trap, Tavla hit-and-run
  lib/src/rules/play_filters.dart              Tavla no-waste, Fevga/Moultezim primes, leave-a-move
  lib/src/rules/game_end.dart                  bear-off win, mother rule, scoring
  lib/src/play/play_tree.dart                  PlayTree, PlayNode
  lib/src/play/play_generator.dart             generatePlays (fast)
  lib/src/play/reference_generator.dart        referencePlays (oracle)
  lib/src/game/game_action.dart                sealed GameAction + JSON
  lib/src/game/game_event.dart                 sealed GameEvent
  lib/src/game/game_result.dart                GameResult, ResultKind
  lib/src/game/rule_violation.dart             RuleViolation, ViolationCode
  lib/src/game/cube.dart                       CubeState
  lib/src/game/game_state.dart                 GameState, GamePhase
  lib/src/game/reducer.dart                    reduce()
  lib/src/game/dice.dart                       DiceRoll helper (random(Random))
  lib/src/match/match.dart                     MatchConfig, MatchState, MatchAction, reduceMatch
  lib/src/serial/game_log.dart                 GameLog, replay, JSON helpers
  test/...                                     mirrors lib/src
  test/support/positions.dart                  `pos(...)` builder + random reachable positions
  benchmark/play_generation_bench_test.dart    tag bench
  test/fuzz/fuzz_games_test.dart               tag fuzz
```

---

### Task 1: Package scaffolding: test config and `Side`

**Files:**
- Create: `packages/tavli_core/dart_test.yaml`
- Create: `lib/src/board/side.dart`
- Modify: `lib/tavli_core.dart`
- Test: `test/board/side_test.dart`

- [ ] `dart_test.yaml`:

```yaml
tags:
  fuzz:
    timeout: 20x
  bench:
    timeout: 5x
```

- [ ] Test first:
  - `Side.one.opponent == Side.two`, and the reverse
  - `Side.values.length == 2`
  - JSON round-trip with `Side.fromJson('one')`
- [ ] Implement:

```dart
enum Side {
  one,
  two;

  Side get opponent => this == one ? two : one;
  String toJson() => name;
  static Side fromJson(String s) => Side.values.byName(s);
}
```

- [ ] The barrel `lib/tavli_core.dart` keeps `tavliCoreSchemaVersion` and adds `export 'src/board/side.dart';`. Later tasks add their exports to the barrel.
- [ ] Verify, then commit `"tavli_core: test tags and Side"`.

---

### Task 2: Variant rules model and catalog

**Files:** `lib/src/variant/{variant.dart, variant_rules.dart, catalog.dart}`; test `test/variant/catalog_test.dart`

**API (binding):**

```dart
enum Layout { standard2535, stackOpposing, stackDiagonal }
enum Direction { opposing, same }
enum Contact { hit, pin, block }
enum OpeningProcedure { playOpeningDice, winnerRerolls }
enum NextGameStarter { openingRoll, previousWinner }
enum DoublesMode { four, cascade }
enum CascadeFailure { forfeit, opponentPlaysRemainder }
enum ScoringModel { multiplier, checkersRemaining }
enum TripleCondition { barOrWinnerHome, winnerHome }

class HeadRule {
  final int maxPerTurn;
  final Set<int> firstTurnDoubles;
  final int maxOnException;
  const HeadRule({...});
}

class Advancement {
  /// The runner must reach pip <= releasePip before other checkers may leave pip 24.
  final int releasePip;
  const Advancement(this.releasePip);
}

class PrimeRules {
  final bool noSixOwnStartQuarter;            // all of own pips 19..24 held
  final bool noSixBeforeOccupiedOppHead;      // all of own pips 6..11 held while opp head (my 12) occupied
  final int? maxPointsInOppStartQuarter;      // own pips 7..12
  final bool noPrimeTrappingAll;              // Long Nard D19, checked every step
  final bool mustLeaveOpponentAMove;          // Fevga D13
  const PrimeRules({...all default false/null});
  static const none = PrimeRules();
}

class PinRules {
  final bool motherRule;
  final int motherPoints;          // 2
  final int bothPinnedPoints;      // 0 (Plakoto/Mahbusa) or 1 (Tapa), awarded to EACH side
  final bool noBearOffWhilePinned; // D11
  const PinRules({...});
}

class HitRules {
  final bool noHitAndRunInHome;  // D4
  final bool bearOffNoWaste;     // D5
  const HitRules({...});
}

class Cascade {
  final int normalRolls;
  final CascadeFailure onFailure;
  const Cascade({...});
}

class Scoring {
  final ScoringModel model;
  final int? triple;
  final TripleCondition? tripleCondition;
  const Scoring({...});
}

class CubeRules {
  final bool available;
  final bool enabledByDefault;
  final bool crawford;
  const CubeRules({...});
  static const none = CubeRules(available: false, enabledByDefault: false, crawford: false);
}

class MatchDefaults {
  final int? fixedTarget;
  final List<int> targets;
  const MatchDefaults({...});
}

class VariantRules {
  final Layout layout;
  final Direction direction;
  final Contact contact;
  final OpeningProcedure opening;
  final NextGameStarter nextGame;
  final HeadRule? head;
  final Advancement? advancement;
  final PrimeRules primes;
  final PinRules? pin;
  final HitRules? hit;
  final DoublesMode doubles;
  final Cascade? cascade;
  final Scoring scoring;
  final CubeRules cube;
  final MatchDefaults match;
  const VariantRules({...});
}

enum Variant {
  portes, plakoto, fevga, tavla, tapa, moultezim, gulBara,
  longNard, shortNard, sheshBesh, mahbusa, mahbusaArab, tawla31;

  VariantRules get rules => variantCatalog[this]!;
}
```

`const Map<Variant, VariantRules> variantCatalog` lives in `catalog.dart`.

**Catalog values (binding; from design spec §3.3 and matrix §6):**

| Variant | Layout | Dir | Contact | Opening | NextGame | head | advancement | primes | pin | hit | doubles / cascade | scoring | cube | match |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| portes | standard2535 | opposing | hit | playOpeningDice | previousWinner | — | — | none | — | — | four | multiplier, triple null | none | targets [3,5,7] |
| plakoto | stackOpposing | opposing | pin | playOpeningDice | previousWinner | — | — | none | mother, 2, both 0, noBearOff | — | four | multiplier | none | [3,5,7] |
| fevga | stackDiagonal | same | block | playOpeningDice | previousWinner | — | releasePip 11 | ownStart, beforeOppHead, leaveMove | — | — | four | multiplier | none | [3,5,7] |
| tavla | standard2535 | opposing | hit | winnerRerolls | openingRoll | — | — | none | — | noHitAndRun, noWaste | four | multiplier | none | [3,5,7] |
| tapa | stackOpposing | opposing | pin | winnerRerolls | openingRoll | — | — | none | mother, 2, both 1, noBearOff | — | four | multiplier | none | [3,5,7] |
| moultezim | stackDiagonal | same | block | winnerRerolls | openingRoll | — | 11 | ownStart, maxOppStart 4 | — | — | four | multiplier | none | [3,5,7] |
| gulBara | stackDiagonal | same | block | winnerRerolls | openingRoll | — | — | none | — | — | cascade(3, opponentPlaysRemainder) | multiplier | none | [3,5,7] |
| longNard | stackDiagonal | same | block | playOpeningDice | openingRoll | max 1; first-turn {3,4,6} → 2 | — | trappingAll | — | — | four | multiplier | available, off by default, crawford | [3,5,7] |
| shortNard | standard2535 | opposing | hit | playOpeningDice | openingRoll | — | — | none | — | — | four | multiplier, triple 3, barOrWinnerHome | available, on, crawford | [3,5,7] |
| sheshBesh | standard2535 | opposing | hit | playOpeningDice | openingRoll | — | — | none | — | — | four | multiplier, triple 3, winnerHome | available, off, crawford | [3,5,7] |
| mahbusa | stackOpposing | opposing | pin | playOpeningDice | openingRoll | — | — | none | mother, 2, both 0, noBearOff | — | four | multiplier | none | [3,5,7] |
| mahbusaArab | as mahbusa | | | | | | | | | | | | | |
| tawla31 | stackDiagonal | same | block | playOpeningDice | openingRoll | — | 18 | none | — | — | four | checkersRemaining | none | fixedTarget 31 |

**Steps:**
- [ ] **Tests first:** one test per row. Name each with its decision ID where one applies, for example:
  - `D1 portes plays opening dice`
  - `D1 tavla winner rerolls`
  - `D20 tawla31 is a running game with checkersRemaining scoring and target 31`
  - `D9 tapa both-pinned scores 1 each`
  - `D7 shortNard cube on with crawford`
  - `D6 portes has no triple`
  - `D14 moultezim max 4 points in opp start quarter`
  - `D19 longNard trap check`
  - `D18 longNard head exception {3,4,6}`
  - `D17 gulBara has no advancement or prime limits`
  - `D10 mahbusa and mahbusaArab rules are equal`

  Also assert `variantCatalog.length == 13`.
- [ ] Implement, verify, commit `"tavli_core: variant rules model and catalog (13 variants)"`.

---

### Task 3: Geometry and `Position`

**Files:** `lib/src/board/{geometry.dart, position.dart, mutable_position.dart}`; tests `test/board/{geometry_test,position_test}.dart`; `test/support/positions.dart`

**API:**

```dart
class Geometry {
  final Direction direction;
  const Geometry(this.direction);

  /// Opponent's pip for the physical point at my [pip] (1..24).
  int toOpponent(int pip);  // opposing: 25 - pip; same: pip > 12 ? pip - 12 : pip + 12
}

class Position {
  // Per side: counts by own pip 0..25 (0 = off, 25 = bar); pinned bitmask over pips 1..24.
  factory Position.fromPips({
    required Map<int, int> one, required Map<int, int> two,
    int barOne = 0, int barTwo = 0,
    Set<int> pinnedOne = const {}, Set<int> pinnedTwo = const {},
    required Direction direction,
  }); // offOne/offTwo derived: 15 - (sum + bar). Throws ArgumentError if >15 or invalid.
  factory Position.start(Layout layout, Direction direction);
  final Direction direction;
  int count(Side s, int pip);        // pip 0..25
  bool isPinned(Side s, int pip);
  int borneOff(Side s);              // == count(s, 0)
  int onBar(Side s);                 // == count(s, 25)
  int pipCount(Side s);              // sum pip*count over 1..25 (bar counts 25)
  bool allHome(Side s);              // no checker on pips 7..25
  int checkersOnBoard(Side s);       // 15 - borneOff
  Side? controller(Side me, int myPip); // who holds the physical point; pinned pair => pinner
  MutablePosition toMutable();
  Map<String, Object?> toJson(); static Position fromJson(Map<String, Object?> j);
  // == and hashCode: structural; hash cached; web-safe (keep intermediate values < 2^30)
}
```

**Start positions:**

| Layout | Each side |
|---|---|
| `standard2535` | {24:2, 13:5, 8:3, 6:5} |
| `stackOpposing` | {24:15} |
| `stackDiagonal` | {24:15} |

Geometry distinguishes the two stack layouts.

**Steps:**
- [ ] **Tests first:**
  - **Geometry:**
    - opposing `toOpponent(1) == 24` and `toOpponent(24) == 1`;
    - same `toOpponent(24) == 12`, `toOpponent(12) == 24`, `toOpponent(13) == 1`, `toOpponent(1) == 13`;
    - `toOpponent` is an involution for all 1..24 in both directions.
  - **Start positions:**
    - standard start: `pipCount(one) == 167` and `pipCount(two) == 167`;
    - stack starts: `pipCount == 360`;
    - `borneOff == 0`.
  - **`fromPips` validation:** rejects 16 checkers; derives `borneOff` (e.g. `one: {1: 5}` gives `borneOff(one) == 10`).
  - **Equality and hash:** two separately built equal positions are `==` with equal `hashCode`; positions differing only in a pinned bit are `!=`.
  - **`controller`:**
    - opposing; one has 2 on pip 6, so the physical point is two's pip 19: `controller(two, 19) == Side.one`;
    - pinned pair: one has 1 on pip 1 pinned by two (two has 1 on its pip 24) gives `controller(one, 1) == Side.two`.
  - **JSON:** round-trip for each layout's start plus one pinned position.
  - **`MutablePosition`:** a mutate-then-freeze round-trip equals a `fromPips`-built position.
- [ ] `test/support/positions.dart` exports `pos(...)` (a thin wrapper defaulting `direction: Direction.opposing`) and `posSame(...)` (`Direction.same`).
- [ ] Implement, verify, commit `"tavli_core: geometry and Position"`.

---

### Task 4: Single-step legality, apply and undo

**Files:** `lib/src/play/step.dart`, `lib/src/rules/turn_context.dart`, `lib/src/rules/step_rules.dart`; test `test/rules/step_rules_test.dart`

**API:**

```dart
class Step {
  final int from, to, die;
  const Step(this.from, this.to, this.die);
  // == / hashCode / toJson / fromJson
}

class AppliedStep {
  final Step step;
  final bool hit, pinned, unpinned, bearOff;
}

class TurnContext {
  final int headDepartures;
  final bool firstTurn;
  final int homeHitMask;   // bit p set => I hit an opposing checker on my home pip p this turn (D4)
  final List<int> diceOfTurn;
  const TurnContext({...});
  TurnContext afterStep(AppliedStep a, {required bool fromHead}); // returns updated copy
}

class StepRules {
  StepRules(this.rules);
  final VariantRules rules;

  /// Basic legality only (G2, G5, G6, D11, contact, bar-first). No turn validators.
  Iterable<Step> basicSteps(MutablePosition p, Side s, int die);
  AppliedStep apply(MutablePosition p, Side s, Step step);  // mutates
  void undo(MutablePosition p, Side s, AppliedStep a);      // exact inverse
}
```

**Semantics:**
- **Target:** `to = from - die`. If `to <= 0` it is a bear-off attempt (`to` becomes 0).
- **Bar first:** if `onBar(s) > 0`, the only legal steps are `from == 25` (hitting games only; pinning and blocking games never have a bar).
- **Pinned checker:** a checker of mine pinned on pip *p* never moves.
- **Landing on `to` in 1..24:** look at the physical point through `Geometry`; *o* = the opponent's count there.

| Contact | Open when | Effect |
|---|---|---|
| `hit` | o ≤ 1 | o = 1: hit; the opponent's checker goes to the opponent's bar |
| `pin` | o == 0, or o == 1 and that opponent checker is not itself pinning one of mine (i.e. my pinned bit at `to` is clear) | o == 1: set the opponent's pinned bit at its pip |
| `block` | o == 0 | — |

  For `pin`, landing where my own checker is pinned is never allowed: that point is controlled by the opponent.
- **Leaving a pin:** when I leave pip *p* and no checker of mine remains on *p*, any opponent checker pinned under it is unpinned.
- **Bear-off (G5, G6, D11):** requires `allHome(s)`, and for pin rules with `noBearOffWhilePinned`, no own pinned checker anywhere. Then:
  - `from == die` is allowed;
  - `die > from` is allowed only if no own checker sits on pips `from+1..6`.

**Steps:**
- [ ] Tests first. Opposing hitting unless noted:
  1. `G2 basic move` — standard start, die 6 from 24 lands on 18 (open).
  2. `hit` — `one: {8:1}`, `two: {two-pip of my 5: 1}`, i.e. two has 1 on 20. One plays 8→5 with die 3 and hits; after apply, `onBar(two) == 1`; after undo, the position is equal to the original.
  3. `blocked` — two has 2 on the point: no step.
  4. `bar first` — `barOne: 1` plus other checkers: every legal step is from 25. Entry die 3 lands on 22 if open.
  5. `G6 exact` — `one: {3:1, 1:1}`, die 3 bears off pip 3.
  6. `G6 higher die, highest pip` — `one: {3:1, 1:1}`, die 6 bears off pip 3, not pip 1.
  7. `G6 must move when higher checker exists` — `one: {5:1, 2:1}`, die 4: pip 2 can't bear off with 4 (there is a checker on 5); 5→1 is legal.
  8. `G5 not all home` — `one: {7:1, 3:14}`: no bear-off steps.
  9. `pin` (Plakoto rules) — two has 1 on its pip 19 (= my 6); one lands 8→6 and pins it; `isPinned(two, 19)`; the pinned two checker has no legal steps; undo restores.
  10. `pin closed to owner` — one's checker pinned on my 1 under two; one cannot land on pip 1 with any die.
  11. `D11 no bear-off while pinned` — one all home except one pinned checker on my pip 20 (in the opponent's home): no bear-off step even though the other 14 are home. `allHome` is false here anyway; also cover the case where the pinned checker is inside home: `one: {5:14}` + pinned one on pip 3, die 5: no bear-off.
  12. `block` (Fevga, same direction) — two has 1 on its pip 24 (= my 12); one cannot land on my 12; one can land on my 13 if two has none on its pip 1.
  13. `unpin` — a pinner leaving releases the pinned checker; undo re-pins.
- [ ] Implement, verify, commit `"tavli_core: single-step legality, apply/undo"`.

---

### Task 5: Turn validators: head, sole runner, six-block trap, Tavla hit-and-run

**Files:** `lib/src/rules/step_validators.dart`; test `test/rules/step_validators_test.dart`

**API:**

```dart
/// Returns whether [step] is allowed for [s] given the turn context, BEFORE applying it.
/// Some validators need the post-step position. The generator calls
/// [allowsAfter] after apply and undoes when it returns false.
class StepValidators {
  StepValidators(this.rules);
  bool allowsBefore(MutablePosition p, Side s, Step step, TurnContext ctx);
  bool allowsAfter(MutablePosition p, Side s, AppliedStep a, TurnContext ctx);
}
```

**Semantics (binding):**
- **Head (D18):**
  - A step from pip 24 counts as a head departure.
  - Allowed while `ctx.headDepartures < limit`, where `limit = head.maxOnException` if `ctx.firstTurn` and the turn's dice are a double whose value is in `head.firstTurnDoubles`, else `head.maxPerTurn`.
  - A checker already off the head may keep moving.
- **Sole runner (advancement):** a side is *released* when it has any checker on pips 0..`releasePip`. Until released:
  - if `count(s, 24) == 15`, any one checker may leave pip 24 (it becomes the runner);
  - otherwise only the single checker not on pip 24 may move.

  This is stateless and computed from the position before each step. A die the runner can't use is unplayable, and G4 then applies naturally.
- **Six-block trap (D19), checked after every step (`allowsAfter`):**
  - Let *T* = the opponent pips of the physical points I hold (≥ 1 checker of mine and not pinned).
  - If *T* contains six consecutive opponent pips *k..k+5*, the block is illegal when **no** opponent checker is "in front" of it: none borne off, and none on an opponent pip < *k*.
  - Use the opponent's pips because "front" is defined along the opponent's path.
- **Tavla hit-and-run (D4):** `allowsBefore` rejects any step whose `from` pip has its bit set in `ctx.homeHitMask`. `TurnContext.afterStep` sets bit `to` when the applied step hit on my home pip (1..6).

**Steps:**
- [ ] Tests first:
  1. `D18 one head checker per turn` — Long Nard start, dice 5-3: after 24→19, a second step from 24 is rejected; 19→16 is allowed.
  2. `D18 first-turn 6-6 allows two off head` — `firstTurn: true`, dice 6-6: two departures from 24 allowed, the third rejected.
  3. `D18 first-turn 5-5 allows only one` — `firstTurn: true`, dice 5-5: only one departure.
  4. `D18 later-turn 6-6 allows only one` — `firstTurn: false`.
  5. `advancement Fevga runner` — Fevga start: any first step from 24 is allowed. After one checker sits on pip 20 (14 on 24), a step from 24 is rejected and steps of the runner are allowed. After the runner reaches pip 11, steps from 24 are allowed again.
  6. `advancement Tawla31 threshold 18` — runner on 19: others blocked; runner on 18: released.
  7. `D19 trap illegal mid-turn` — a position where one holds six consecutive points along two's path with all 15 of two behind and none borne off: the step completing the sixth point fails `allowsAfter`. Variant: with one two-checker in front, it is allowed.
  8. `D4 no hit-and-run` — Tavla, one hits on its home pip 4: a later step from pip 4 in the same turn is rejected; stacking another checker onto pip 4 is allowed.
- [ ] Implement, verify, commit `"tavli_core: turn validators (head, runner, six-block, hit-and-run)"`.

---

### Task 6: Play generator and `PlayTree` (four-dice and two-dice modes)

**Files:** `lib/src/play/{play_tree.dart, play_generator.dart}`; test `test/play/play_generator_test.dart`

**API:**

```dart
class PlayNode {
  Iterable<Step> get nextSteps;
  PlayNode? child(Step s);
  bool get isComplete;        // prefix equals a full legal play
  Position? get finalPosition; // set iff isComplete
}

class PlayTree {
  PlayNode get root;
  Set<Position> get finals;   // deduplicated legal final positions
  bool get hasPlay;           // finals nonempty AND at least one step
  bool get isForced;          // finals.length == 1
  int get diceUsed;           // max dice used by legal plays
  List<int> get remainder;    // cascade only (Task 8); empty otherwise
  PlayNode? walk(List<Step> steps);
}

PlayTree generatePlays(Position p, Side s, List<int> dice, VariantRules rules, TurnContext ctx);
```

`dice` is `[a, b]` for a normal roll and `[d, d, d, d]` for a double. Cascade queues come in Task 8.

**Algorithm:**
1. Depth-first search on one `MutablePosition`, with make/unmake through `StepRules` and `StepValidators`. Non-doubles try both orders; doubles try one.
2. Record each maximal sequence (one with no legal continuation, or with all dice used) and its frozen final.
3. G4: keep only sequences whose length equals the maximum. If that maximum is 1 and the roll is not a double, and both dice had some single legal step, keep only the higher die's sequences.
4. Apply the play filters (Task 7; in this task, a no-op hook list).
5. `finals` = the set of surviving finals. Build the trie from **all** surviving sequences whose final is in `finals`.
6. If the maximum length is 0, return an empty tree.

**Steps:**
- [ ] Tests first:
  1. `G4 standard opening 3-1 Portes` — standard start, dice [3, 1]: finals include the position after 8→5, 6→5, and `isForced` is false. Assert the number of distinct finals equals **the value produced by an independent hand count recorded in the test** (enumerate the plays by hand in a comment). If a hand count is impractical, assert set membership of 3 named plays and non-membership of 1 illegal one.
  2. `G4 must use both dice` — a position where a legal single 6 exists, but playing 6 first blocks the 2 while 2-then-6 uses both: only two-dice plays remain.
  3. `G4 higher die when only one playable` — one checker that can play either the 5 or the 3 but not both (construct it): only the 5 play remains.
  4. `G4 doubles play as many as possible` — 3 of 4 playable: `diceUsed == 3`.
  5. `G9 no legal play` — bar checker facing a closed board: `hasPlay` false, `finals` empty.
  6. `dedup` — 8→5→4 (3 then 1) and 8→7→4 (1 then 3) give one final, but the tree holds both prefixes.
  7. `tree walk` — after the first step, `nextSteps` contains only continuations of surviving plays; `isComplete` is true only at full length.
  8. `isForced` — a position with exactly one legal final.
- [ ] Implement, verify, commit `"tavli_core: play generator and play tree"`.

---

### Task 7: Play filters: Tavla no-waste, Fevga/Moultezim primes, leave-a-move

**Files:** `lib/src/rules/play_filters.dart`; wire into the generator; test `test/rules/play_filters_test.dart`

**Semantics (binding):** each filter removes plays only while at least one play survives.
- **D5 no-waste (Tavla):**
  - First keep the plays bearing off the most checkers.
  - Among those, keep the minimum total waste, where waste = Σ over bear-off steps of (`die − from`).
- **D12-A, Fevga, at end of turn, on each candidate final:**
  - (a) illegal if I hold all six of my pips 19..24 (held = ≥ 1 own checker);
  - (b) illegal if I hold all six of my pips 6..11 while the opponent has ≥ 1 checker on its pip 24 (= my 12).
- **D14-B, Moultezim, at end of turn:**
  - illegal if I hold more than 4 of my pips 7..12;
  - illegal if I hold all six of my pips 19..24.
- **D13-A, Fevga:** drop a final if the opponent would have **no** legal first step for every die value 1..6 under the opponent's own validators (sole runner and bar-first included). Opponent turn context: fresh, `firstTurn: false`.

**Steps:**
- [ ] Tests first:
  1. `D5 Tavla 5-2 with checker on 3` — `one: {3:1}` + others borne off, dice [5, 2]: the only final is "3 off using the 5"; the 2-first play (3→1, then the 5 bears off pip 1) is removed. Variant with Portes rules: both plays are legal.
  2. `D12a Fevga own start six-prime forbidden` — a constructed position where one play completes all of 19..24 and another doesn't: only the latter survives. If every play completes it, all survive.
  3. `D12b Fevga six in front of occupied opp head` — the same idea for pips 6..11 with the opponent on its 24. With the opponent's head empty, the prime is allowed.
  4. `D14 Moultezim max four in opp start quarter` — the play that would make a fifth held point in 7..12 is removed.
  5. `D13 leave a move` — a constructed position where one candidate leaves the opponent with no first step for any die and another doesn't.
- [ ] Implement, verify, commit `"tavli_core: play filters (no-waste, primes, leave-a-move)"`.

---

### Task 8: Gul Bara cascade generation

**Files:** extend `play_generator.dart`; test `test/play/cascade_test.dart`

**API addition:**

```dart
/// Ordered cascade queue for double d: [d,d,d,d, d+1 x4, ..., 6 x4].
List<int> cascadeQueue(int d);
PlayTree generateCascade(Position p, Side s, List<int> queue, VariantRules rules, TurnContext ctx);
```

`generateCascade` plays the queue **in order**. Within the current number it plays as many of the four as possible. If fewer than four of a number can be played, the play stops after them.

The tree's `remainder` = the queue entries not played. These are the same for every surviving play, because only maximum-length plays survive (G4 applied to queue order).

**Steps:**
- [ ] Tests first:
  1. `cascadeQueue(3)` = [3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6]; `cascadeQueue(6)` = four 6s.
  2. `D16 failure leaves remainder` — a constructed position where the four 3s and four 4s are playable but only two 5s: `diceUsed == 10` and `remainder == [5,5,6,6,6,6]`.
  3. `full cascade` — open board: `diceUsed == 16`, `remainder` empty.
  4. `cascade respects block contact` — a blocked point stops the chain.
- [ ] Implement, verify, commit `"tavli_core: Gul Bara cascade generation"`.

---

### Task 9: Reference oracle and differential test

**Files:** `lib/src/play/reference_generator.dart`; `test/play/oracle_differential_test.dart`; `test/support/positions.dart` (add `randomReachablePositions`)

**API:** `Set<Position> referenceFinals(Position p, Side s, List<int> dice, VariantRules rules, TurnContext ctx, {bool cascade = false})`.

The oracle is deliberately naive:
- immutable `Position` copies through a pure function that wraps `StepRules.apply` on a fresh mutable copy each time;
- every permutation of the dice multiset;
- G4 and the filters reimplemented in straightforward code;
- it shares only `StepRules.basicSteps` and `StepValidators`.

**`randomReachablePositions(Variant v, int n, Random rng)`:** play random legal games (any legal play from the tree) and sample positions every few turns.

**Steps:**
- [ ] Test, default run: for every variant, 30 sampled positions × all 21 rolls (cascade queues for Gul Bara doubles after roll 3) give `generatePlays(...).finals == referenceFinals(...)`. On mismatch, print the position JSON, dice and the symmetric difference.
- [ ] Implement, verify, commit `"tavli_core: reference oracle + differential test"`.

---

### Task 10: Game state, actions, events and the reducer phase machine

**Files:** `lib/src/game/{game_action.dart, game_event.dart, rule_violation.dart, cube.dart, game_state.dart, reducer.dart, dice.dart, game_result.dart}`; tests `test/game/reducer_phases_test.dart`

**API:**

```dart
enum GamePhase { opening, awaitingRoll, cubeOffered, moving, gameOver }

sealed class GameAction {
  Map<String, Object?> toJson();
  static GameAction fromJson(Map<String, Object?> j);
}
final class RollOpening extends GameAction { final int dieOne, dieTwo; }
final class RollDice extends GameAction { final int d1, d2; }
final class StepAction extends GameAction { final Step step; }
final class SubmitPlay extends GameAction { final List<Step> steps; } // added after Task 15: a whole play at once (program design §4.7)
final class UndoStep extends GameAction {}
final class CommitPlay extends GameAction {}
final class OfferDouble extends GameAction {}
final class Take extends GameAction {}
final class Drop extends GameAction {}
final class Resign extends GameAction { final Side side; }
final class ClockTimeout extends GameAction { final Side side; } // renamed from Timeout (clashes with package:test)

sealed class GameEvent {}
// Subclasses:
//   OpeningRolled(dieOne, dieTwo, starter?)   starter null => tie
//   DiceRolled(side, dice)
//   CheckerMoved(side, AppliedStep)
//   StepUndone(side, AppliedStep)
//   PlayCommitted(side, List<Step>)
//   TurnPassed(side, dice)
//   RemainderPassed(to, dice)
//   CubeOffered(by, value)
//   CubeTaken(by, newValue)
//   CubeDropped(by)
//   GameEnded(GameResult)

enum ViolationCode {
  wrongPhase, invalidDice, illegalStep, incompletePlay, nothingToUndo,
  cubeUnavailable, cannotDouble, gameOver,
  // added later: notYourAction (actor attribution), stepsAlreadyTaken (SubmitPlay)
}
class RuleViolation { final ViolationCode code; final String message; }

class GameUpdate { final GameState state; final List<GameEvent> events; }

class GameState {
  final Variant variant;
  final Side? sideToMove;            // null only in opening
  final GamePhase phase;
  final Position position;           // current (after steps taken)
  final Position turnStart;          // position at start of current moving phase
  final List<int> dice;              // dice of the current moving phase
  final bool cascadeMode;
  final List<Step> steps;            // steps taken this moving phase
  final TurnContext context;         // context after `steps`
  final int rollIndex;               // number of RollDice accepted this game
  final Map<Side, int> turnsTaken;
  final CubeState cube;
  final List<int> pendingRemainder;  // Gul Bara
  final bool remainderTurn;          // opponent is playing a remainder
  final GameResult? result;
  final bool crawfordGame;
  static GameState initial(Variant v, {Side? starter, bool crawfordGame = false, bool cubeEnabled});
  PlayTree get tree;                 // generated lazily from turnStart/dice/context; cached
  PlayNode get node;                 // tree.walk(steps)
}

Object /* GameUpdate | RuleViolation */ reduce(GameState s, GameAction a);
```

Prefer a small `sealed class ReduceResult` with two subclasses, `GameUpdate` and `RuleViolation`, so callers can `switch`.

**Actor attribution** (added after the Task 10 review; the SP4 online server depends on it):
- `Side? actorOf(GameState s, GameAction a)` returns who may send `a`:
  - `RollOpening` → null (system);
  - `RollDice`, `StepAction`, `SubmitPlay`, `UndoStep`, `CommitPlay`, `OfferDouble` → `sideToMove`;
  - `Take`, `Drop` → the offerer's opponent;
  - `Resign`, `ClockTimeout` → the action's own side.
- `reduce(s, a, {Side? by})` rejects with `ViolationCode.notYourAction` when `by` is given and differs from a non-null `actorOf`.

**Phase machine (binding):**

**`opening` + `RollOpening(a, b)`:**
- Dice must be 1..6, otherwise `invalidDice`.
- `a == b`: emit `OpeningRolled(starter: null)` and stay in `opening` (G7).
- Otherwise the winner is the side with the higher die.
  - **`playOpeningDice` (D1-A):** phase `moving`, `sideToMove` = winner, `dice = [hi, lo]`, `rollIndex = 1`, winner's `firstTurn` context true.
  - **`winnerRerolls`:** phase `awaitingRoll` with `sideToMove` = winner.

**`awaitingRoll` + `RollDice(d1, d2)`:**
- `rollIndex++`.
- Cascade if the variant's doubles mode is `cascade`, `d1 == d2` and `rollIndex > cascade.normalRolls`.
- Build the tree, with `firstTurn` = `turnsTaken[side] == 0`.
- If `!tree.hasPlay`: emit `TurnPassed`, `turnsTaken[side]++`, and the opponent goes to `awaitingRoll`.
- Otherwise phase `moving`.

**`moving`:**

| Action | Result |
|---|---|
| `StepAction(step)` | Must be in `node.nextSteps`, else `illegalStep`. Apply it and emit `CheckerMoved`. Then run the game-end checks (Task 11); a game end goes to `gameOver` |
| `UndoStep` | Fails with `nothingToUndo` if no steps were taken. Otherwise recompute the position from `turnStart` + `steps[..-1]` and emit `StepUndone` |
| `CommitPlay` | Requires `node.isComplete`, else `incompletePlay`. Emit `PlayCommitted` and `turnsTaken[side]++` (see below) |
| `SubmitPlay(steps)` | Only with no step taken yet (`state.steps.isEmpty`), else `stepsAlreadyTaken` (a dedicated code, added after the Task 15 review; outside `moving` it is `wrongPhase`). Applies every step as `StepAction`, then `CommitPlay`, **atomically**: an illegal step (`illegalStep`) or a result that is not a full play (`incompletePlay`) rejects the whole action and leaves the state unchanged. A game-ending step ends the game there (no commit); any step after it is `illegalStep`. Events: the same `CheckerMoved`… (+ `GameEnded`) or … + `PlayCommitted` (+ `RemainderPassed`) sequence as step-by-step play |

After `CommitPlay`:
- **With a cascade remainder** (`tree.remainder.isNotEmpty`, `onFailure == opponentPlaysRemainder`, and not already `remainderTurn`): the opponent's phase becomes `moving` over `generateCascade` of the remainder with `remainderTurn: true`, and `RemainderPassed` is emitted. If the opponent has no play, they go straight to `awaitingRoll`.
- **After a remainder turn is committed**, the remainder player goes to `awaitingRoll`. Their own remainder is discarded.
- **Otherwise** the opponent goes to `awaitingRoll`.

**Any phase:** `Resign` / `ClockTimeout` → `gameOver` with `GameResult(winner: other, kind: resign | timeout, points: 1 × cube)` (decided after Task 10). An action in `gameOver` → `gameOver` violation. Any other phase/action mismatch → `wrongPhase`.

**Steps:**
- [ ] Tests first:
  - every row of the phase machine, including each `ViolationCode`;
  - `D1` both procedures;
  - opening tie;
  - turn pass;
  - undo back to the turn start;
  - commit rejected mid-play;
  - Long Nard `firstTurn` propagates to the head exception.
- [ ] Implement, verify, commit `"tavli_core: game state, actions, events, reducer phases"`.

---

### Task 11: Game end, scoring and the mother rule

**Files:** `lib/src/rules/game_end.dart`, `lib/src/game/game_result.dart`; wire into the reducer; test `test/rules/game_end_test.dart`

**API:**

```dart
enum ResultKind { single, gammon, triple, mother, draw, checkersRemaining, resign, timeout }

class GameResult {
  final Side? winner;     // null => draw
  final ResultKind kind;
  final int points;       // to winner; for draw: points to EACH side
  final int cubeValue;
}

GameResult? checkGameEnd(Position p, VariantRules rules, {required Side justMoved, required int cubeValue});
```

**Semantics (binding):**

1. **Bear-off win:** `borneOff(justMoved) == 15`.
   - **`checkersRemaining`:** points = `checkersOnBoard(loser)`, kind `checkersRemaining`.
   - **Otherwise:**
     - `gammon` (2) if `borneOff(loser) == 0`, else `single` (1);
     - upgrade to `triple` (`scoring.triple`) when it is non-null, the loser has borne off none, and:
       - `barOrWinnerHome`: the loser has a checker on its bar or on its pips 19..24;
       - `winnerHome`: the loser has a checker on its pips 19..24.

     Multiply by the cube value.
2. **Mother rule** (`pin.motherRule`), stateless, checked after every step:
   - **Both mothers pinned** (`isPinned(one, 24) && isPinned(two, 24)`): draw, `points = pin.bothPinnedPoints` to each side.
   - **Else, if side X's mother is pinned** (`isPinned(X, 24)`) and the pinner P = X.opponent has `count(P, 24) == 0`: P wins, kind `mother`, `points = pin.motherPoints`.
   - **Else** the game is not over.

   This covers D8 (a), (b) and the draw. The pinner's start emptying later triggers on that step.

**Steps:**
- [ ] Tests first:

| Test | Setup | Expect |
|---|---|---|
| `G8 single` | loser has borne off 3 | 1 point |
| `G8 gammon` | loser has borne off 0 | 2 |
| `D6 portes triple counts as 2` | loser has a checker in the winner's home and borne off 0 | 2 (gammon) |
| `shortNard koks` | loser has a checker on the bar or in pips 19..24, borne off 0 | 3 |
| `D6 sheshBesh Turkish mars` | loser has a checker in pips 19..24, borne off 0 | 3; loser on the bar only → 2 |
| `cube multiplies` | cube 4, gammon | 8 |
| `D21 tawla31 checkersRemaining` | loser has 6 on board | 6 |
| `D8a mother immediate` | two pins one's last checker on pip 24 while `count(two, 24) == 0` | two wins 2 at that step; reducer ends mid-turn with dice unplayed |
| `D8b mother deferred` | as above, but two still has checkers on its 24 | no end. When two's last start checker leaves (a later step), two wins 2 |
| `D8 both mothers pinned` | Plakoto | draw, 0 each |
| `D9 Tapa both mothers pinned` | Tapa | draw, 1 each |
| `D10 mahbusa same as plakoto` | — | — |
- [ ] Implement and wire into the reducer (`StepAction` → `checkGameEnd` → `GameEnded`). Verify, commit `"tavli_core: game end, scoring, mother rule"`.

---

### Task 12: Gul Bara remainder turns in the reducer

**Files:** reducer; test `test/game/gul_bara_test.dart`

**Steps:**
- [ ] Tests first:
  1. `D15 cascade starts after the first 3 rolls of the game` — rolls 1–3 of the game are doubles and play four times; roll 4 cascades. The opening one-die roll isn't counted (Gul Bara re-rolls).
  2. `D16 opponent plays remainder` — a constructed failure: after commit, the opponent is `moving` with `remainderTurn: true` over the remainder queue; after their commit they are `awaitingRoll`, not the original player.
  3. `D16 remainder stops at its own first failure` — the remainder's own unplayable tail is discarded, never passed back.
- [ ] Implement, verify, commit `"tavli_core: Gul Bara remainder turns"`.

---

### Task 13: Doubling cube

**Files:** `cube.dart` + reducer; test `test/game/cube_test.dart`

**`CubeState`:** `value` (1..64), `owner` (`Side?`; null = centered), `offeredBy` (`Side?`), `enabled` (bool).

**Semantics (binding):**
- **`OfferDouble`:**
  - Only in `awaitingRoll`.
  - Requires `rules.cube.available && cube.enabled && !crawfordGame && value < 64`, and `owner == null || owner == sideToMove`. Otherwise `cubeUnavailable` / `cannotDouble`.
  - Goes to `cubeOffered` and emits `CubeOffered`.
- **`Take`:** value ×2, owner = taker, back to the offerer's `awaitingRoll`.
- **`Drop`:** `gameOver`, the offerer wins `single` × the current value (before doubling).

**Steps:**
- [ ] Tests first:
  - each rule above;
  - Portes (no cube) → `cubeUnavailable`;
  - Short Nard enabled by default;
  - Long Nard available but disabled by default (`GameState.initial(..., cubeEnabled: true)` enables it);
  - cap at 64;
  - a Crawford game refuses.
- [ ] Implement, verify, commit `"tavli_core: doubling cube"`.

---

### Task 14: Match layer

**Files:** `lib/src/match/match.dart`; test `test/match/match_test.dart`

**API:**

```dart
class MatchConfig {
  final List<Variant> cycle;     // [v] for a single variant; [portes, plakoto, fevga] for Tavli
  final int? target;             // null = single game
  final bool cubeEnabled;
  static const tavliMarathon = [Variant.portes, Variant.plakoto, Variant.fevga];
  factory MatchConfig.single(Variant v, {bool? cubeEnabled});
  factory MatchConfig.to(int target, List<Variant> cycle, {bool? cubeEnabled}); // tawla31 needs target 31, else ArgumentError (as fromJson)
}

sealed class MatchAction {}
final class GameMove extends MatchAction { final GameAction action; }
final class NextGame extends MatchAction {}
final class ForfeitMatch extends MatchAction { final Side side; } // added after Task 15

// Added after Task 15 (session and server needs):
sealed class MatchEvent {}
final class InGame extends MatchEvent { final GameEvent event; }
final class GameStarted extends MatchEvent { final int index; final Variant variant; final Side? starter; final bool crawford; }
final class MatchEnded extends MatchEvent { final Side? winner; final Map<Side, int> scores; }
class MatchUpdate { final MatchState state; final List<MatchEvent> events; } // unmodifiable; events are values
Side? matchActorOf(MatchState m, MatchAction a); // GameMove: actorOf; NextGame: null; ForfeitMatch: side

class MatchState {
  final MatchConfig config;
  final Map<Side, int> scores;
  final int gameIndex;
  final GameState game;
  final List<GameResult> history;
  final bool crawfordUsed;
  final Side? winner;       // also set for a decided single game (draw => null)
  final Side? forfeitedBy;  // the side that sent ForfeitMatch, if any
  bool get isOver;
}

Object /* MatchUpdate | RuleViolation */ reduceMatch(MatchState m, MatchAction a);
```

**Semantics (binding):**
- **`GameMove`:** passed to the game. On `GameEnded`:
  - add points (a draw adds to both);
  - check the target.
- **Crawford:** applies if the current variant's `cube.crawford` is set. When a side first reaches `target − 1`, the next game is `crawfordGame: true` and `crawfordUsed` is set.
- **`NextGame`:** only after `gameOver` and `!isOver`.
  - Variant = `cycle[(gameIndex + 1) % cycle.length]`.
  - Starter = the previous winner if that variant's rules say `previousWinner` and the last result had a winner; otherwise `opening`.
- **Tawla 31:** target 31, and `checkersRemaining` points accumulate.
- **Winner (added after Task 15):** a single game's winner is the match winner (a draw leaves it null); `isOver` is unchanged.
- **Events (added after Task 15):** a `GameMove` emits its game events as `InGame`; `NextGame` emits `GameStarted(index, variant, starter, crawford)`; a game end that decides the match emits `MatchEnded(winner, scores)` after the `InGame(GameEnded)`.
- **`ForfeitMatch(side)`** (actor = `side`; rejected with `gameOver` once the match is over): if the game is not over it is resigned by `side` (A9 `forfeitResult` scoring, emitting `InGame(GameEnded)`), then the match ends with `side.opponent` as winner whatever the scores (`forfeitedBy = side`), emitting `MatchEnded`.

**Steps:**
- [ ] Tests first:
  - Tavli marathon rotation;
  - `D2` previous winner starts in Tavli; opening roll in Tavla;
  - a Plakoto draw leads to an opening roll;
  - match ends at the target;
  - the Crawford game is flagged once;
  - Tawla 31 reaches 31 across games;
  - `NextGame` before the game is over is rejected.
- [ ] Implement, verify, commit `"tavli_core: match layer"`.

---

### Task 15: Serialization and replay

**Files:** `lib/src/serial/game_log.dart` + `toJson`/`fromJson` on states; test `test/serial/serial_test.dart`

**API:**
- `GameState.toJson/fromJson` (the tree is rebuilt from `turnStart`, `dice`, `cascadeMode`, `context` and `steps`)
- `MatchState.toJson/fromJson`
- `MatchAction.toJson/fromJson`
- `class GameLog { final MatchConfig config; final MatchState? start; final List<MatchAction> actions; }` (the JSON carries `schemaVersion`; no field, as nothing reads it). A log with `start` is trusted input only: servers never accept client-supplied logs or states; untrusted peers send actions.
- `MatchState replay(GameLog log)`

Readers throw `FormatException` on a `schemaVersion` mismatch. A future version bump needs a `migrate` step from older stored versions (not built until then).

**State validation (added after the Task 15 review):** `GameState.fromJson` (`FormatException`) and `withPosition` (`ArgumentError`) reject a board the variant cannot produce: pinned checkers unless `contact == pin`, bar checkers unless `contact == hit`. `fromJson` also requires a `cubeOffered` state's cube to be one `OfferDouble` could make (value < 64, not the Crawford game, owner null or the offerer), and cascade dice to be a whole `cascadeQueue(d)` (any non-empty tail of one in a `remainderTurn`). `test/serial/state_fuzz_test.dart` mutates valid states' JSON structurally and checks every accepted state runs under `reduce` without throwing and round-trips.

**Steps:**
- [ ] Tests first:
  - round-trip of each action type;
  - round-trip of a mid-turn state (steps taken) with an equal `node.nextSteps`;
  - replay of a scripted Plakoto game equals the live-built state;
  - an unknown schema version throws.
- [ ] Implement, verify, commit `"tavli_core: serialization and replay"`.

---

### Task 16: Fuzz suite

**Files:** `test/fuzz/fuzz_games_test.dart` (`@Tags(['fuzz'])`)

Games per variant = `int.tryParse(Platform.environment['TAVLI_FUZZ_GAMES'] ?? '') ?? 40`. Note `dart:io` is allowed in **tests**; the purity test scans `lib/` only.

**Each game:**
1. Seeded `Random(variantIndex * 1_000_003 + gameNo)`.
2. Opening rolls until there is no tie.
3. On each turn, pick a random path through the tree to a complete node, then commit.
4. In cube variants, offer and take at random with probability 0.05.
5. Stop at `gameOver` or after 3,000 actions (a cap breach is a failure).

**Invariants after every action:**
- 15 checkers per side, counting board + bar + off;
- no physical point holds both sides unless it is a pinned pair;
- pinned bits only where the owner has exactly 1 and the opponent has ≥ 1 on the same physical point;
- `pipCount` ≥ 0;
- the phase is consistent with `sideToMove`;
- at game end the result is valid (points > 0, or a draw).

**Also:**
- Every 50th game: `replay(log) == finalState` (`toJson` equality).
- On a sample of positions: `generatePlays(...).finals == referenceFinals(...)`.

**Steps:**
- [x] Run the default (40/variant) inside `dart test`. Also run `TAVLI_FUZZ_GAMES=2000 dart test --tags fuzz` locally and record the duration.
- [x] Commit `"tavli_core: fuzz suite with invariants, replay and oracle checks"`.

---

### Task 17: Benchmarks with budgets

**Files:** `benchmark/play_generation_bench_test.dart` (`@Tags(['bench'])`, run by `dart test` because `benchmark/` is listed in `dart_test.yaml` → `paths: [test, benchmark]`)

- For each variant, take a worst-case fixture: the sampled position × roll with the most finals, found once by scanning `randomReachablePositions`. Freeze it as JSON in the test file.
- Measure `generatePlays` (for Gul Bara, a cascade fixture too). Assert `stats.withinBudget(const Duration(milliseconds: 2))`.
- Also measure the reducer `StepAction` on a mid-game state, with budget ≤ 50 µs p95.
- Print all stats.

**Steps:**
- [x] Add `paths: [test, benchmark]` to `dart_test.yaml`.
- [x] **Failing-cascade budget.** A Gul Bara cascade that cannot reach the full queue must prove that by visiting every reachable state. Measured after Task 8: up to about 117k states and about 230 ms, asserts off. Target ≤ 50 ms p95 over cascades sampled from random games.
  - Implement the incremental web-safe 30-bit XOR-Zobrist hash in `MutablePosition` (design spec §9) so the memo can key on the hash plus a verified freeze only on collision.
  - Or add a sound pruning bound.
  - Add the worst failing-cascade fixture to the benchmarks.
- [x] **Budget numbers must come from runs with asserts off.** `dart test` enables asserts, and `MutablePosition.freeze()` runs full invariant validation under assert.
  - Add `benchmark/run_benchmarks.dart`, a plain `main()` that reuses the same fixtures and prints `BenchStats`, and run it with `dart run --no-enable-asserts benchmark/run_benchmarks.dart`. Use those numbers for the SP1 report.
  - The `dart test` benchmark keeps the budget assertion with a documented 2× assert allowance (`budget × 2`), so CI still catches regressions.
- [x] Implement, verify that it passes locally at scale 1, commit `"tavli_core: generation and reducer benchmarks with budgets"`.

---

### Task 18: Portes differential vs legacy, and the SP1 exit report

**Files:**
- `test/differential/portes_legacy_differential_test.dart` (app level: legacy code lives in the app)
- `docs/superpowers/perf/2026-10-01-sp1-core-report.md`

**Legacy → core mapping (matrix §1, hitting):**
- Legacy `BoardState.points[i] > 0` is player 1, which maps to core `Side.one` pip = `i + 1`.
- `points[i] < 0` is player 2, which maps to `Side.two` pip = `24 − i`.
- Bars and borne-off counts map directly.

**Steps:**
- [x] Test: for 40 positions from legacy seeded easy self-play × 21 rolls, map legacy `generateAllLegalTurns` resulting boards to core positions. They must equal the core `generatePlays(...).finals` (`Variant.portes` rules; for the legacy side to move).
  - If they differ, write the position and roll to the test output.
  - Determine which engine is right **using matrix G1–G9**.
  - If legacy is wrong, add the case to a documented `knownLegacyBugs` list with the rule ID. If core is wrong, fix core.
- [ ] Run the exit fuzz: `TAVLI_FUZZ_GAMES=100000 dart test --tags fuzz` in `packages/tavli_core`. This may take a long time; run it in the background and record the wall time. *(Started 2026-10-02 00:29 AEST, est. ~1.5 h; see the SP1 report §3.)*
- [x] Write the report:
  - test counts per suite;
  - benchmark table (p50/p95/max per variant);
  - fuzz totals (games, actions, durations, zero failures);
  - oracle comparisons run;
  - the Portes differential summary with any known legacy bugs;
  - comparison against the legacy baseline (`docs/superpowers/perf/2026-10-01-legacy-baseline.md`).
- [x] Commit `"SP1: Portes legacy differential + exit report"`.

---

## SP1 exit checklist

- [x] All 13 variants in the catalog with decision tests (Task 2).
- [x] Every matrix rule ID (G1–G9, §4 topics, D1–D22 where engine-relevant) has ≥ 1 test. Generate a list with `grep -ho "test('[A-Z][0-9]*" -r test | sort -u` and compare it with the matrix.
- [x] Oracle differential clean.
- [x] Fuzz: 100,000 games per variant with zero failures, recorded (1.3M games, 348M actions, 2026-10-02).
- [x] Benchmarks within budget.
- [x] `tool/ci/check.sh` → `ALL GREEN`.
- [x] SP1 report committed.
