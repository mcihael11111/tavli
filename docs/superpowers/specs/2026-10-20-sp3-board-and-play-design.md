# SP3 — Board & Play Design

**Date:** 2026-10-20
**Status:** Draft. Written under the user's instruction "start phase 3" (2026-10-20) and the standing instruction to build the approved program end to end.

**Parents:**
- `2026-10-01-gameplay-rewrite-program-design.md`: §3.3 budgets, §4.5 session, §4.6 board, §6 SP3 row and the carried gates
- SP1 `tavli_core`
- SP2 `tavli_bot`

The current-screen inventory (2026-10-20) is summarised in §8.

**Deliverable:** a new `lib/gameplay/` game experience (session layer, Flame board, input, animation, chrome, audio and haptics) for **vs-bot and pass & play** in all 13 variants, built on `tavli_core` and `tavli_bot`. It ships alongside the legacy screens behind a developer flag until the exit gates pass.

---

## 1. Goals and exit criteria

1. **The interaction budgets (spec §3.3) pass on the Galaxy S** in profile/release:
   - tap → visual response the next frame;
   - drag tracks the finger every frame;
   - ≥ 99 % of frames within budget during play;
   - game screen interactive ≤ 400 ms;
   - GPU image memory ≤ 30 MB.
2. **No game logic or bot search on the UI isolate:**
   - bot decisions run in the `BotWorker` (SP2);
   - Gul Bara cascade rolls never stall the UI (carried gate (d), §5.4).
3. **Visual parity with today's board,** plus the fixes from §8: pins drawn, bear-off slivers at the correct aspect, cube sprite, design-token-compliant chrome.
4. **Controls.** All are on by default, and each can be switched off in settings:
   - drag-and-drop;
   - tap-select then tap-destination;
   - double-tap to move by the active die;
   - tap the dice to swap the active die;
   - undo;
   - auto-play forced moves;
   - auto-pass;
   - auto-commit (honours `moveConfirmation`);
   - an animation speed setting, with reduced motion meaning instant.
5. **Every legacy bug in §8 is fixed** in the new path.
6. **Full games pass in integration tests** for all 13 variants vs bot, plus pass & play.
7. **The user signs off a manual QA checklist** on the Galaxy S.
8. **Legacy vs-bot and pass & play are deleted.** This is gated on carried gate (b), the legacy device baseline, being captured first:
   - `features/game/presentation/{game_screen,pass_play_screen}.dart`
   - `providers/game_provider.dart`
   - `move_quality_cache.dart` and their tests

   **`lib/flame_game/` stays until SP4**, because the online screen still uses it.

**Out of scope:** the online screen (SP4); replay, spectate, marathon wiring and the results pipeline beyond victory recording (SP5); new art.

---

## 2. Architecture

```
lib/gameplay/
  session/   MatchSetup, MatchController (Riverpod Notifier), seats, autoplay, pacing, BotClient
  board/     BoardGame (FlameGame), BoardLayout (pure geometry), components, input, animation queue
  screens/   GameScreen (vs bot), PassPlayScreen, chrome widgets, overlays
  services/  GameAudio (pooled SFX), GameHaptics, gameplay settings adapter
  adapters/  GameVariant ↔ core Variant, core GameResult → app GameResult, DifficultyLevel → BotLevel
```

**Boundary rules:**
- New code imports only `tavli_core`, `tavli_bot`, design tokens, settings, copy, l10n, personalities, dialogue, pacing and the allowed carve-outs.
- `test/architecture/gameplay_boundaries_test.dart` flips to `allowMissing: false`.

**Data flow (one direction):**

```
input intents ─► MatchController.dispatch(action) ─► reduceMatch (core) ─► new MatchState + MatchEvents
                                                                         │
             BoardGame ◄── BoardCommand stream ◄── controller (events + selection/highlight changes)
             chrome   ◄── ref.watch(controller.select(...))
```

- The board never reads state in `build()`.
- The controller is the single source of truth. The board holds only presentation state (component positions, animation queue, drag).

---

## 3. Session layer

**`MatchSetup`:**
- `mode`: vsBot or passAndPlay
- `variant` (core)
- `level` (`BotLevel`, plus a teaching flag for `easyWithHelp`)
- `personality`
- `cubeEnabled` (from the variant's defaults)
- `seed` (optional, for tests)
- `marathon` (forwarded but unused until SP5)

**`MatchController`** is an auto-disposed `NotifierProvider.family`. Its state:
- `MatchState` (core)
- `UiSelection`: selected source, active die index, highlights (destinations with die and hit flags, and quality in teaching mode)
- `busy`: the bot is thinking or acting
- `pendingDouble`
- `lastAnalysis`

**Seats:**
- `HumanSeat`
- `BotSeat`: drives a `BotClient`, which wraps `BotWorker`
- `PassPlayHumanSeat`: like `HumanSeat`, plus the pass interstitial

*Implementation note (SP3 Task 4–5):* the seats are not separate types. The bot seat, teaching and match flow are part-file extensions of `MatchController` (`bot_seat.dart`, `teaching.dart`, `match_flow.dart`), and the pass & play seat is the `handoff`/`viewer` state. SP4 will extract a `Seat` interface for the online seat.

*SP5 note (persistence):* a restored game can leave the bot part-way through its turn (steps taken). The bot submits whole plays from the turn start, so the restore must undo those steps first (or the controller must do it before `choosePlay`); today the bot loop gives up after 3 rejected submits with a `BotErrorNotice`.

**Dice:**
- Local dice come from `Random.secure()` (a seeded `Random` in tests) in the controller, never from the UI.
- `RollOpening` and `RollDice` are dispatched by the controller.

### Human turn
- **Intents:**
  - `selectSource(from)`
  - `stepTo(to)`, with die disambiguation in §4.3
  - `quickMove(from)`, the active die
  - `swapDice`
  - `undo`
  - `commit`
  - `offerDouble`
  - `take`, `drop`
  - `resignGame`, `leaveMatch`
- Each maps to core `StepAction`, `UndoStep`, `CommitPlay` and so on.
- **Resign (decision, SP3 review):** `resignGame` is `GameMove(Resign(side))`: A9 scoring, and a longer match goes on. `leaveMatch` is `ForfeitMatch(side)`. `MatchView.isMultiGame` (the match has a target) tells the chrome to offer "Resign game" and "Leave match"; a single-game match shows one "Resign", which is `leaveMatch`. In pass & play the resigning side is the viewer, who holds the device, even while a handoff is pending. A match left between games, after a game the other side won, records a single at cube 1.
- **Legal destinations** come from `GameState.node.nextSteps` filtered by `from`.

### Autoplay
Each item is a setting, default on, read through the gameplay settings adapter:

| Setting | Behaviour |
|---|---|
| Forced moves | `tree.isForced` → play the single play's steps automatically, animated |
| Auto-pass | A `TurnPassed` event shows a toast and moves on with no input |
| Auto-commit | When `node.isComplete` and no continuation exists → `CommitPlay`, unless `moveConfirmation` is on, in which case a Confirm button appears |
| Auto-roll | **Default off.** Many players like to roll; this is the only autoplay default that differs from the program spec, chosen for feel. When on, it rolls at turn start if no cube decision is possible |

### Bot turn
1. Pacing beat (`TurnPacing`).
2. Cube decision (`BotRequest(offerDouble)`) if allowed.
3. The controller rolls.
4. `BotRequest(choosePlay)`, built by `BotRequestBuilder.fromState`. This is an SP3 input from the SP2 review; core gets a public `GameState.turnStartContext`.
5. `SubmitPlay(steps)` is reduced, and its `CheckerMoved` events are animated **one by one** with `interMoveSettle`.
6. Commit.

**Pause:** the pause menu suspends the bot loop at its awaits.

### Teaching (`easyWithHelp`)
- `BotRequest(analyze)` on each selection change and after each step. Requests supersede the previous one.
- Highlight quality comes from `nextStepQuality`.
- The end-of-turn toast comes from `playEquityLoss`.
- Thresholds stay as today's: > 0.04 mistake, > 0.015 inaccuracy.

### Game end
On `MatchEnded`, or `GameEnded` for a single game:
- record via the existing services (progression, match history, achievements, coins) **only for vs-bot**;
- navigate to `/victory` with `{result (app GameResult via adapter), difficulty, variant, mode}`;
- pass & play shows the victory screen with no stats.

**Persistence:** out of scope (SP5); the log can be added later.

---

## 4. Board (Flame)

### 4.1 Geometry
`BoardLayout` is pure Dart, ported from the legacy baked-mode calibration fractions (§8) and covered by unit tests ported from `board_layout_test.dart`. It provides:

| Area | Behaviour |
|---|---|
| Fit | Contain-fit of the 0.8854 aspect board image |
| Points | Point anchors in **core player-relative pips via a `ViewTransform`**: side-to-view mapping for the local viewer, and the pass & play flip |
| Stacks | Compress above 7 checkers |
| Bar | Pile around `barCenterY` |
| Tray | Slivers at the vertical sprite's real cropped aspect |
| Dice | Area at 75 % width / mid-height |
| Cube | Spot on the bar centre-line |

**Declared deviations from legacy geometry:**
- **Orientation.** For every variant the local viewer's home (pips 1–6) is bottom-right, their pip 24 top-right, and their bar pile and tray at the bottom. That is the legacy hitting layout; the legacy pinning and running layouts (player 1 home top-right) are drawn rotated 180°. Intended.
- **Stack compression.** Above 7 checkers a pile keeps the span of a 7-pile (step × 6 / (n − 1)); the legacy step × 7 / n still grew to 15. Bar piles compress the same way above 7.
- **Bar hit band.** Widened about the bar centre to at least a checker diameter, and to 48 px where that leaves the inner columns' stack centres to the columns (capped on phone widths); tested before the columns.
- **Slivers.** Sized from the atlas's cropped vertical sprite (about 47 × 172), not the legacy 77/202 that squashed the whole 400 px square.

### 4.2 Components
- **Retained.** Every component is created once per match; checkers are pooled, 30 per match. Nothing is created per frame or per rebuild.
- **No collision detection.** No `HasCollisionDetection`, no hitboxes.
- **Static layer.** The table and board image form a static layer: a Flutter `Image` behind a transparent `GameWidget`, decoded at screen size with `ResizeImage`.
- **Pre-allocated drawing objects.** `Paint` and `TextPainter` objects are created up front, never per frame. There is no blur in the per-frame path; the highlight glow is a pre-rendered sprite or a solid alpha fill.

| Component | Behaviour |
|---|---|
| `CheckerSprite` | Sprite plus stack-faded shadow, selected sprite, **pin marker** (a pinned checker drawn under its pinner with a small offset and a subtle ring) |
| `DiceSprite` | Two dice, plus 3rd/4th die pips for doubles. Remaining dice are shown; used dice are greyscale at 50 %. The active die gets a ring. Tapping swaps the active die. Rattle plays on a new roll |
| `CascadeIndicator` | Gul Bara: the current number in the queue and how many remain |
| `HighlightLayer` | Pulsing green/red destination triangles with die badges and quality borders; bear-off zone outline |
| `CubeSprite` | Uses the existing unused `doubling_cube_N` assets |
| `DiceCueRing` | As today |

### 4.3 Input
Hit-testing is done at game level, by **point column region** (the whole triangle column, generous margins) plus the bar, tray and dice regions. It returns a logical pip.

| Gesture | Behaviour |
|---|---|
| Pointer-down on an own column | Select that column's top playable checker; highlights appear in the same frame |
| Tap on a highlighted destination | Step |
| Drag | The checker follows the finger every frame, with zero logic in the move handler. Drop on a highlighted column steps; anywhere else springs back (animated) |
| Double-tap a checker | `quickMove`: the active die's step from that source if legal, else the other die |
| Tap on dice | Swap the active die |
| Tap on empty or illegal | Clear the selection |

**Bear-off die disambiguation** (several dice reach the same `to`):
1. Prefer the die whose child node has the most continuations.
2. On a tie, prefer the exact die.
3. Otherwise prefer the smaller overshooting die.

### 4.4 Animation
- **One queue** of interruptible tweens: a move takes 130 ms `easeOutCubic` and a restack 200 ms.
- **Interruptible.** A new intent fast-forwards the queue to its end state; input is never locked behind animation.
- **Speed setting:** slow 200 / normal 130 / fast 80 / instant 0 ms. Reduced motion → instant.
- **Parallel bear-off cascade** for multi-step bear-offs.

---

## 5. Chrome, audio, haptics, performance

### 5.1 Chrome
Reproduces today's layout, corrected to the design system (`00_TOKENS.md` / `02_COMPONENTS.md`):
- **Top bar:** avatar, name, turn pill, cube indicator.
- **Bottom bar:** player, pips (only if `showPipCount`), double button, pause.
- **Action area:** fixed height, holding ROLL, Undo and Confirm.
- **Overlays:** opening-roll and double-offer.
- **Pause sheet:** Resume / Customize (the correct `/customize` route, with the sets reloaded on return) / Resign / New game / Exit, with destructive confirms.
- **Token corrections:**
  - filled buttons use `primary`/`light`;
  - spacing and type sizes are tokens only (no 22, no 6);
  - sheets use `background`;
  - hard-coded English strings move to `TavliCopy`/l10n.

**Bot dialogue.** It stays hidden, as today, per the existing test decision. Triggers are still fired so the victory screen keeps its line.

**Pass & play:** the same screen with two `HumanSeat`s, the pass interstitial and the flip. It uses the board, checker and dice sets from settings.

### 5.2 Audio
`GameAudio` is a singleton initialised at app start:
- one preloaded `AudioPlayer` per SFX type, or a small pool for checker sounds, so overlapping sounds don't cut each other off;
- it honours `sfxVolume`;
- existing assets are used plus the procedural fallbacks from `sound_generator.dart`.

### 5.3 Haptics
`GameHaptics` fires **exactly one** haptic per event (the legacy code double-fires). A setting toggle is added, default on.

### 5.4 Gul Bara cascades (carried gate (d))
**Cause:** the reducer builds the cascade tree synchronously when the roll is reduced. Typical builds take ≤ 2 ms; worst cases take 0.3–1.3 s on desktop and can cause GC hitches.

**Approach, in order:**
- **(a) Core pruning bound** for failing cascades in `_maxFrom`. It must be sound (it only cuts subtrees that can't beat the best found) and fuzz-verified against an unpruned search. Measure.
- **(b) Off-isolate fallback,** if (a) doesn't bring the worst case under about 50 ms desktop: run the controller's cascade-roll reduction through `Isolate.run`, returning a `MatchState` built from JSON on the main isolate. The human then gets steps through a **cascade intent channel** that queries the worker-built tree; the exact mechanism is decided in the plan with measurements.

The plan task starts with (a).

### 5.5 Assets
- **Boards:** resized to 1200 px wide as WebP (about 6 MB GPU each instead of 19).
- **Table:** 1600×1000 WebP.
- **Checkers and dice:** cropped to their visible content and packed into atlases at about 192 px, with the vertical sprite cropped to its real aspect.
- **Unused images removed:**
  - `*_board_plain.png`
  - `set2_board_bearoff_side.png`
  - duplicate checker sets 2 and 3, since they're byte-identical; keep the set indirection, mapped to one atlas
- **Flame image cache** cleared on set switch.
- **Calibration** fractions stay valid because they're relative.

### 5.6 Performance harness
`integration_test/perf/new_game_perf_test.dart` is the same scripted scenario as the legacy one, but driven through **real board taps and drags** via `tester.timedDrag` on computed coordinates, as well as controller intents. Its timeline summaries are asserted against spec §3.3 when run on the Galaxy S.

---

## 6. Migration
- **Developer flag:** `kNewGameplay`, defaulting to **true in debug and profile builds and false in release** until exit. Routes `/game` and `/pass-play` choose between the new and legacy screens.
- **Fixes on both paths** (they're tiny and shared):
  - the victory "Play again" route bug;
  - pass & play recording stats;
  - marathon extras forwarded.
- **At exit**, after gate (b) is captured: set the flag to true everywhere, delete the legacy vs-bot and pass & play code and its tests, and keep `flame_game/` for online until SP4.

---

## 7. Testing

| Layer | Tests |
|---|---|
| Geometry | Ported calibration assertions; `ViewTransform` round-trips for flip, both sides and every direction; tray and bar positions; stack compression |
| Session | Controller unit tests with fake dice and a fake `BotClient`: every intent; autoplay rules; teaching flow; cube flows; pause; game end and recording (vs-bot records, pass & play doesn't); a 13-variant scripted full game each |
| Board | `flame_test`: retained components (no creation after load during a game, counted); highlight/selection on pointer-down in the same frame; drag follows the pointer; drop/spring-back; animation fast-forward on new input; pins and cube rendered. Golden images per board set (CI-tolerant) |
| Widgets | Chrome per phase; token compliance check (no raw hex, sizes from the theme); accessibility labels; pass interstitial |
| Integration (emulator / desktop) | Full game vs Easy and Medium in Portes, Plakoto and Fevga through real gestures; pass & play to the end |
| Device (Galaxy S, profile) | `new_game_perf_test` against §3.3 budgets; screen-open time; GPU memory; Gul Bara cascade hitch probe |
| Manual QA | A checklist document, signed off by the user |

---

## 8. Legacy facts carried over (from the 2026-10-20 inventory)

**Geometry (`board_layout.dart`, baked mode):**
- **Image calibration:**
  - board image 2102×2374;
  - board region y 213–2161, trays y 43–180 and 2202–2339;
  - triangle bases at y 268 and 2103, triangle height 675/2374.
- **Point layout:**
  - leftmost and rightmost point centres at 161.5 and 1974.5 /2102;
  - point spacing 154 (left half) and 158 (right half) /2102.
- **Checker and dice sizing:**
  - `checkerRadius = pointWidth × 0.46`;
  - visible-content ratios: checkers 0.555, dice 0.34;
  - stack step `2r × 0.75`, compressing above 7.

**Legacy bugs the new path must fix:**
- silent SFX (`AudioService` never initialised) and double haptics;
- the "Play again" crash and the broken `/customization` route;
- pass & play recording stats as an Easy bot game;
- marathon extras dropped;
- squashed bear-off slivers;
- unrendered pins;
- ignored settings (`showPipCount`, `moveConfirmation`, volumes, reduced motion);
- missing `totalOnPoint` on rebuild.
