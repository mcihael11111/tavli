# SP3 Board & Play Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new `lib/gameplay/` game experience (vs-bot and pass & play, all 13 variants) on `tavli_core` and `tavli_bot`:
- instant, never-blocking input;
- retained Flame rendering;
- design-token chrome;
- working audio and haptics;
- legacy vs-bot and pass & play replaced (deletion gated on carried gate (b)).

**Architecture:** `docs/superpowers/specs/2026-10-20-sp3-board-and-play-design.md` (binding). Program spec §3.3 sets the budgets and §4.5–§4.6 the design. Core API: `packages/tavli_core/lib/tavli_core.dart`; bot API: `packages/tavli_bot/lib/tavli_bot.dart`.

**Tech stack:** Flutter 3.41.5, Flame 1.36, flutter_riverpod 2.x, just_audio, `flame_test` (add as a dev dependency), integration_test.

**Conventions:**
- **Working directory:** `/Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli`, branch `rewrite/gameplay`. Never push; the controller pushes.
- **PATH:** prefix every command with `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" &&`.
- **Verify per task:**
  - `flutter test` on the relevant dirs, plus package tests when packages change;
  - root `dart analyze --fatal-infos`;
  - `dart format --output=none --set-exit-if-changed packages lib/gameplay test/gameplay integration_test/perf`;
  - batch end: `tool/ci/check.sh` → ALL GREEN.
- **Design system (CLAUDE.md, binding):**
  - Colours: `TavliColors.*` only, no hex. Text: `Theme.of(context).textTheme.*`, no font sizes. Spacing: `TavliSpacing.*`, no raw values.
  - Component specs from `docs/design/02_COMPONENTS.md`; tokens from `docs/design/00_TOKENS.md`.
  - Copy via `TavliCopy`/l10n. No new hard-coded English except semantics fallbacks that are already l10n-backed.
- **Import boundary:** `lib/gameplay/**` must not import legacy gameplay code (the architecture test). Set `allowMissing: false` in Task 3.
- **Files and commits:**
  - ≤ about 300 lines per file, one responsibility each.
  - TDD: listed tests first.
  - One commit per task, ending with the trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Stage explicitly; never stage `flutter_02.log`.
- **Never run bot search or rules generation on the UI isolate in hot paths,** except core `reduce` for non-cascade actions (≤ 2 ms by SP1 budgets).

---

## Batch A — foundations

### Task 1: Core additions — turnStartContext, cascade pruning bound
- **`GameState.turnStartContext`:** make it public (core); add a test.
- **Cascade pruning in `_maxFrom` (play_cascade.dart):** add a sound pruning bound for failing cascades.
  - **Bound:** remaining-dice upper bound from mobility, e.g. prune when `progress + remainingQueue ≤ bestFound`.
  - **Mobility bound:** a checker-pip budget, i.e. the sum over own checkers of the max steps each could still take given the blocked points ahead. Implementer to design and prove.
  - **Fuzz:** compare against the unpruned search on ≥ 1M finals (reuse the SP1/SP2 fuzz harness ideas). `diceUsed`, `remainder` and finals must be identical.
  - **Measure:** the `worstFailingCascade`, `worstCascade` and slowest-real-cascade fixtures, before/after.
- **Target:** worst case ≤ 50 ms desktop asserts-off. If it isn't reached, stop and report the numbers; the controller decides (b) in design §5.4.
- Commit: `"tavli_core: public turnStartContext; failing-cascade pruning bound"`.

### Task 2: Bot request builder and BotClient
- **`tavli_bot`:** `BotRequest BotRequests.fromState(GameState s, {required BotRequestKind kind, required BotLevel level, required int id, required int seed, Duration? budget})`.
  - Handles moving phases (turnStart + steps for analyze; `turnStartContext`), cascades/remainder turns (dice queue + `cascade`), cube, `crawfordGame`.
  - Tests: for every kind, across 13 variants on random reachable states (moving, mid-turn, remainder turns), `Bot.decide(fromState(...))` returns no `ErrorReply` and PlayReply steps are legal from `s`.
- **App `lib/gameplay/session/bot_client.dart`:** wraps `BotWorker`.
  - Lazy spawn + warm on first game open; one per app; cancel/supersede helpers; `dispose` on app shutdown.
  - Riverpod `botClientProvider`.
  - Tests with a fake worker interface.
- Commit: `"gameplay: BotRequest.fromState and BotClient"`.

### Task 3: Adapters, gameplay settings, audio, haptics
- **`lib/gameplay/adapters/`:**
  - `GameVariant ↔ Variant` (all 13 + round-trip test);
  - `DifficultyLevel → (BotLevel, teaching)`;
  - core `GameResult → app GameResult` (kinds → `GameResultType`, points, cube; test per kind).
- **`lib/gameplay/services/gameplay_settings.dart`:** reads `SettingsService` plus new keys, persisted via the existing service. Add keys to `SettingsService` with getters/setters and defaults:

| Key | Default |
|---|---|
| `tavli_anim_speed` | normal |
| `tavli_haptics` | true |
| `tavli_autoplay_forced` | true |
| `tavli_auto_pass` | true |
| `tavli_auto_roll` | false |

  - Existing keys used: `moveConfirmation` (governs auto-commit), `showPipCount`, `sfxVolume`.
  - Reduced motion via MediaQuery.
- **`GameAudio`:** singleton, initialised in `main.dart` after `runApp` (non-blocking); one preloaded player per SfxType (pool of 3 for checker sounds); honours `sfxVolume`; procedural fallbacks.
- **`GameHaptics`:** exactly one haptic per event, honours the setting.
- **Tests:**
  - adapters;
  - settings defaults/persistence;
  - GameAudio with a fake player factory: preload once, play doesn't reload, volume applied, overlapping checker sounds use different players;
  - GameHaptics fires once per event and none when disabled.
- Flip the architecture test to `allowMissing: false` (create `lib/gameplay/`).
- Commit: `"gameplay: adapters, settings, audio and haptics services"`.

---

## Batch B — session

### Task 4: MatchController — human flows
`lib/gameplay/session/match_controller.dart` + `match_setup.dart` + `ui_selection.dart` (APIs per design §3).

- **Dice:** injected `Random` (`Random.secure()` default).
- **Intents:**
  - `rollOpening`, `roll`
  - `selectSource(int pip)`, `stepTo(int pip)` (bear-off die disambiguation per design §4.3), `quickMove(int pip)`, `swapDice`, `undo`, `commit`
  - `offerDouble`, `take`, `drop`, `resign`
- **Autoplay:** forced, auto-pass, auto-commit/confirm, auto-roll, per settings.
- **Board output:** emits a `Stream<BoardCommand>`:
  - `Sync(state)`
  - `AnimateSteps(List<AppliedStep>, side)`
  - `ShowSelection`, `ClearSelection`
  - `DiceRolled`, `CubeChanged`, `Rattle`
- **Tests** (fake settings, seeded dice): every intent including illegal ones (no state change, no throw); highlight sets equal `node.nextSteps` filtered; die disambiguation; autoplay matrix; undo to turn start; commit with/without `moveConfirmation`; resign A9 result; opening roll both procedures.
- Commit: `"gameplay: MatchController human flows"`.

### Task 5: MatchController — bot seat, pass & play, teaching, game end
- **Bot loop:**
  - `TurnPacing` beats;
  - cube offer/take via `BotClient`;
  - `choosePlay` → `SubmitPlay` → `AnimateSteps` step by step with `interMoveSettle`;
  - pause suspension;
  - cancellation on dispose.
- **Pass & play:** two human seats, pass interstitial state, flip in `ViewTransform` input.
- **Teaching:** analyze requests supersede; qualities into highlights; end-of-turn feedback event.
- **Game/match end:** vs-bot records via existing services (progression, match history, achievements, coins) through the adapters; pass & play records nothing; then navigation intent `GoVictory(...)`.
- **Gul Bara cascade rolls:** per the Task 1 outcome. If pruning met the target, reduce inline; else implement design §5.4(b).
- **Tests** (fake `BotClient` with scripted replies and a real-`decide` variant):
  - a full scripted game vs bot per variant (13) to `GameEnded`, events sane;
  - pass & play full game;
  - teaching flow;
  - cube flows vs bot;
  - pause halts the bot loop;
  - dispose cancels pending requests.
- Commit: `"gameplay: bot seat, pass & play, teaching, game end"`.

---

## Batch C — board

### Task 6: BoardLayout and ViewTransform (pure)
- Port the legacy baked-mode calibration (design §8) into `lib/gameplay/board/board_layout.dart`, with pip-based APIs:
  - `pointBase(view pip)`, `checkerCenter(view pip, index, total)` (compress > 7)
  - `barSlot(side, i)`, `traySlot(side, i)` (sliver aspect from the cropped asset)
  - `diceCenter`, `cubeSpot`
  - `columnAt(Offset) → hit region`
- `ViewTransform`: maps (side, player-relative pip) ↔ view pip for opposing/same direction and flip.
- Tests: ported calibration assertions from `test/unit/board_layout_test.dart`; `ViewTransform` round-trip for all directions × flips × sides; `columnAt` covers full columns incl. tips; no overlap.
- Commit: `"gameplay: board layout and view transform"`.

### Task 7: Asset pipeline
- **`tool/assets/build_game_assets.dart`** (or a documented script) producing:
  - boards → 1200 px wide WebP;
  - table → 1600×1000 WebP;
  - checker and dice atlases at about 192 px with cropped content and JSON frame data;
  - vertical sliver cropped.
- Commit the outputs under `assets/images/game/` and register them in `pubspec.yaml`. Keep legacy assets until legacy deletion, because the online screen still uses them.
- Measure the sizes.
- Test: the atlas JSON frames cover all sprite names used by the components.
- Commit: `"assets: game atlases and resized boards"`.

### Task 8: BoardGame and components
- `BoardGame extends FlameGame`, consuming the `BoardCommand` stream.
- Components per design §4.2: CheckerSprite pool (pins, selection), DiceSprite (doubles, used, active ring, rattle), CascadeIndicator, HighlightLayer, CubeSprite, DiceCueRing.
- The static board image is a Flutter `Image` behind a transparent `GameWidget`, using `ResizeImage`.
- No per-frame allocation; no collision detection.
- **Tests (`flame_test`):**
  - component count stable through a scripted game, so none are created after load;
  - `Sync` places checkers at layout positions;
  - pins drawn;
  - doubles show 4 dice;
  - used dice dimmed;
  - goldens per board set with CI-tolerant comparators.
- Commit: `"gameplay: Flame board components (retained)"`.

### Task 9: Input and animation
- **Input:** a game-level `PointerHandler` per design §4.3 (pointer-down select in the same frame, tap destination, drag with per-frame follow and drop/spring-back, double-tap quickMove, dice tap swap, clear). It emits controller intents.
- **Animation:** an `AnimationQueue` (move 130 ms `easeOutCubic` × speed factor, restack 200 ms, fast-forward on new intent, cascade bear-off in parallel, reduced motion = instant).
- **Tests:**
  - select highlights in the same frame as pointer-down;
  - drag position equals pointer each frame, with no controller calls during move;
  - drop legal → `stepTo`, illegal → spring back;
  - fast-forward completes all tweens instantly on new input;
  - speed settings;
  - reduced motion.
- Commit: `"gameplay: input and animation queue"`.

---

## Batch D — screens and integration

### Task 10: GameScreen (vs bot) chrome
- `lib/gameplay/screens/game_screen.dart` + widgets per design §5.1: top bar, bottom bar, action area, turn pill (reuse `turn_handoff_pill.dart`), cube indicator, opening-roll and double-offer overlays, pause sheet (correct `/customize` route + reload sets on return), destructive confirms, snackbars/toasts.
- Tokens only; copy via `TavliCopy`/l10n (add missing keys for the previously hard-coded strings in all 6 locales, using English fallback copies flagged for translation).
- Orientation as today.
- Widget tests: each phase renders the right controls; pip count hidden unless the setting is on; semantics labels; no raw hex/size (scan test over `lib/gameplay/screens`).
- Commit: `"gameplay: game screen chrome"`.

### Task 11: Pass & play screen, routing flag, victory fixes
- **PassPlayScreen:** same chrome, two humans, pass interstitial, flip, settings sets.
- **Routing:**
  - `kNewGameplay` flag (true in debug/profile, false in release until exit);
  - `/game` and `/pass-play` choose new vs legacy.
- **Both paths:**
  - victory "Play again" passes the correct Map extras;
  - `/victory` accepts `mode` + `variant`, and pass & play records no stats;
  - the `/game` route forwards `marathon`/`tradition` extras.
- **Tests:** routing picks per flag; the victory play-again route works (widget test); pass & play victory records nothing (fake services).
- Commit: `"gameplay: pass & play screen, routing flag, victory fixes"`.

### Task 12: Integration tests and device perf harness
- `integration_test/gameplay/full_game_test.dart`: real gestures (taps/drags on computed coordinates from `BoardLayout`) to finish games vs Easy and Medium in Portes, Plakoto, Fevga, plus a pass & play game. Run on macOS desktop or the Android emulator if available; otherwise run the logic through `flutter test` with a widget harness, and document which.
- `integration_test/perf/new_game_perf_test.dart`: the same scenario as legacy, through real gestures, plus a screen-open timing mark and a Gul Bara cascade hitch probe. Driver reuse: `tool/device/profile_run.sh new_game_perf`.
- Commit: `"gameplay: integration tests and device perf harness"`.

### Task 13: Exit gates (some require the user and the device)
- [ ] **Gate (b):** the legacy baseline on the Galaxy S (`tool/device/profile_run.sh legacy_game_perf`), recorded in `docs/superpowers/perf/2026-10-01-legacy-baseline.md`.
- [ ] **Gate (c):** AOT core and bot benchmarks on the Galaxy S, recorded.
- [ ] **Device run:** `tool/device/profile_run.sh new_game_perf` against §3.3 budgets; SP3 report.
- [ ] **Manual QA:** checklist `docs/superpowers/qa/sp3-manual-qa.md` (every variant vs bot, pass & play, every control, settings, cube, teaching, pause/resume, rotate), signed off by the user.
- [ ] **Legacy deletion** (only after gate (b)): flip `kNewGameplay` to true everywhere; delete the legacy vs-bot/pass-play screens, the provider, `move_quality_cache` and their tests; keep `lib/flame_game/` for online.
- [ ] **SP3 report** `docs/superpowers/perf/2026-10-20-sp3-report.md`; `tool/ci/check.sh` ALL GREEN.

---

## SP3 exit checklist
- [ ] Batches A–D merged with tests; CI green.
- [ ] Gates (b), (c) captured; the device perf run meets §3.3.
- [ ] Manual QA signed off.
- [ ] Legacy vs-bot/pass-play deleted; flag removed.
- [ ] SP3 report committed.
