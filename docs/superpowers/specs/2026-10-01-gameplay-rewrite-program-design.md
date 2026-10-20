# Gameplay Rewrite — Program Design

**Date:** 2026-10-01
**Status:** Draft — awaiting user review
**Supersedes:** `2026-05-05-gameplay-feel-and-pacing-design.md` (its pacing values carry over; its input-gating, move-quality-cache and Flame-sync mechanisms are replaced)
**Shape:** Program spec. Defines architecture, decisions, quality bar and six sub-projects. Each sub-project gets its own spec → plan → TDD implementation → review → on-device verification cycle.

---

## 1. Why

The user reports gameplay is "slow, laggy, not usable" on a Samsung Galaxy S (recent) and on the Android emulator, at every difficulty, every game state, and every variant; online games never connect. Research on 2026-10-01 found the causes are in our code, not in Flutter.

### 1.1 Measured / verified root causes

| Area | Finding | Evidence |
|---|---|---|
| Bot | Medium/Hard run full 2-ply expectimax (Pappous 3-ply) **synchronously on the UI isolate** | 4.8 s – 94 s per bot move measured on a Mac; phones 3–10× slower; Pappous effectively never returns |
| Bot | Search moves the wrong side at depth ≥ 2; all variants searched with Portes rules | `ai_player.dart:92,104,115`; `:56,63` |
| Input | Checker tap target = painted disc only (~13 px radius); `CircleHitbox` ignored by Flame taps; select fires on finger-up | `checker_component.dart:83-87,472`; Flame `CircleComponent.containsLocalPoint` |
| Input | Every move locks input for its animation; no drag, no tap-to-move, no auto-play | `game_screen.dart:290-302` |
| Rendering | `HasCollisionDetection` with 30 overlapping hitboxes every frame, unused | `tavli_game.dart:20` |
| Rendering | Hidden procedural wood texture (~2,000 path segments) drawn every frame under the board sprite | `board_component.dart:117` |
| Rendering | Highlights: `clipPath` + `MaskFilter.blur` + `TextPainter` layout per frame; paints/vectors allocated per frame in checkers & dice | `highlight_component.dart`, `checker_component.dart:288-306` |
| Rendering | `build()` destroys and recreates dice + highlight components on every rebuild | `game_screen.dart:685-717` |
| Assets | `table.png` 4320×2700 decoded at full size (44.5 MB GPU); boards 2102×2374 (19 MB each); 16 MB of unused board PNGs | asset audit |
| Audio | Game screen's `AudioService` is never initialised → no SFX; when it works it reloads the asset per sound on one player | `game_screen.dart:77`, `audio_service.dart:179` |
| Rules | Human move selection ignores `legalTurns` → mandatory-play rules (use both dice / higher die) not enforced | `game_provider.dart:307-345` |
| Rules | 13 variants offered, 3 rule engines used. Gul Bara and Long Nard play as Fevga; Tawla 31 scoring missing; Tapa wrongly gets mother-piece rule; Plakoto/Fevga dedup broken (~10× duplicates) | inventory |
| Modes | Pass & play stuck at opening roll; victory "Play again" crashes (router cast); replay/marathon/challenges/discovery/per-variant rating never invoked; spectate & dual-board unreachable | inventory |
| Online | Join-by-code impossible (rules deny the joiner reading the room); Google sign-in can't work on Android (no SHA-1 / OAuth client); `activePlayer` not serialized → player 2 never gets a turn; Quick Match hard-codes both as player 1; FCM subscribe failures hang spinners | online audit |
| Online | Client-rolled dice, any participant may write any room field, self-editable ratings — trivially cheatable | `firestore.rules:111`, `rollDice` |
| Startup | `main()` awaits FCM permission/token/Firestore write before `runApp`; 7 services init serially; fonts fetched at runtime | `main.dart:21-38` |
| Size | 142 MB fat APK: 3 ABIs, unused TFLite (+7.4 MB/ABI), unused images | APK audit |
| Process | Device testing done on debug builds; CI pinned to Flutter 3.22 (local is 3.41); no tests for any non-Portes variant or real online code | build dir, `.github/workflows/ci.yml` |

### 1.2 Native vs Flutter — decided: stay on Flutter + Flame

There is no credible evidence that a native app would be meaningfully faster for ~30 sprites. Benchmarks show Flame sustaining ~1,200 moving entities at 60 fps, and Impeller is the default renderer on iOS and on modern Android. A native rewrite would double cost (two codebases) without touching any root cause above.

---

## 2. Decisions (confirmed by user 2026-10-01)

| # | Decision |
|---|---|
| D1 | Approach C: rewrite the gameplay core in Flutter/Dart and keep all visual assets and art direction |
| D2 | Online is **server-authoritative**, using a **Dart server on Google Cloud Run** that imports the same rules package as the app. Requires the Firebase Blaze plan |
| D3 | **All 13 variants with fully correct rules** |
| D4 | Wire in **Replay, Spectate, Marathon + Challenges (incl. discovery & per-variant rating), and Dual-board (BLE)** |
| D5 | Performance budgets target a **recent Samsung Galaxy S (120 Hz)** |
| D6 | Vs-bot, pass & play and online are always in scope |

---

## 3. Goals, non-goals, quality bar

### 3.1 Goals
1. Interaction that feels instant and never blocks: the first visual response lands in the next frame, and input is never locked behind animation or computation.
2. Every variant plays by its real rules, verified by tests.
3. One game model and one controller serve every mode: bot, pass & play, online, replay, spectate, marathon, dual-board.
4. Online play that connects, stays in sync, survives reconnects, and cannot be cheated.
5. Best-in-class engineering process: test-first, measured performance gates, automated CI, on-device profile verification.

### 3.2 Non-goals
- New art, a new board style, or new screens outside gameplay. Home, onboarding, learn, shop and settings UIs are only touched where they launch or receive gameplay.
- A neural-network evaluator. The evaluator interface allows one later; it is not built now.
- iOS device verification until Xcode is installed. Code stays iOS-compatible.

### 3.3 Performance budgets — acceptance gates (Galaxy S, profile/release build)

| Metric | Budget | How measured |
|---|---|---|
| Tap → first visual response | next frame (≤ 8.3 ms at 120 Hz, ≤ 16.7 ms at 60 Hz) | integration test timeline + event timestamps |
| Drag | checker tracks the finger every frame; zero logic on the drag path | timeline |
| Frame time during play | ≥ 99 % of frames within budget; no frame > 16.7 ms during interaction | `flutter drive --profile` timeline summary |
| Bot decision (off UI isolate) | Easy ≤ 20 ms · Medium ≤ 80 ms · Hard ≤ 300 ms · Pappous ≤ 800 ms (p95) | benchmark suite (CI on desktop with scaled limits, device run per sub-project) |
| Legal-play generation per roll | ≤ 2 ms p95 for any variant, including doubles | benchmark suite |
| Online: opponent sees a move | ≤ 500 ms p90 on normal mobile data | e2e test timestamps + manual |
| Cold start → home interactive | ≤ 2 s | `flutter run --profile --trace-startup` |
| Open game screen → board interactive | ≤ 400 ms | timeline |
| Download size (arm64 split / AAB) | ≤ 45 MB | build output |
| GPU image memory in a game | ≤ 30 MB | DevTools memory |

A sub-project is not done until its relevant budgets pass on the user's device.

---

## 4. Architecture

### 4.1 Repository layout (Dart pub workspace)

```
tavli/                          Flutter app (existing)
  lib/gameplay/                 NEW — all gameplay UI and session code
    session/                    MatchSession, seats, autoplay, pacing, results pipeline
    board/                      Flame BoardScene, input, animation, render layers
    screens/                    game, pass&play, online, replay, spectate, dual-board chrome
    services/                   bot worker client, audio/haptics adapters
  packages/
    tavli_core/                 NEW — pure Dart, zero Flutter imports
    tavli_bot/                  NEW — pure Dart, depends on tavli_core
  server/                       NEW — Dart (shelf) Cloud Run service, depends on tavli_core
```

Dependency rules, enforced by an import-lint test:
- `tavli_core` → nothing.
- `tavli_bot` → `tavli_core`.
- `server` → `tavli_core` and `tavli_bot` (for bot-backfill and analysis).
- App → all three.
- Nothing in `packages/` imports Flutter.

### 4.2 Layers and data flow

```
 ┌──────────── screens (Flutter chrome; ref.watch(select) only) ────────────┐
 │                                                                         │
 │   BoardScene (Flame)  ◄── GameEvents ──  MatchSession  ◄── Actions ──┐  │
 │        │  intents (select/drag/drop/tap-die)    │                    │  │
 │        └────────────────────────────────────────►                    │  │
 │                                      reduce(state, action)           │  │
 │                                       (tavli_core, pure)             │  │
 │                                                │                     │  │
 │                    Seats:  Human │ Bot (worker isolate) │ Remote (server / BLE) │ Recorded │ Observer
 └─────────────────────────────────────────────────────────────────────────┘
```

- **State flows one way.** Seats produce `Action`s, the reducer produces new state plus `GameEvent`s, the board animates events, and the chrome renders state.
- **The board never reads state in `build()`** and is never rebuilt by Flutter. It subscribes to the session's event stream.
- **Animations are presentation only.** State commits immediately. If a new intent arrives mid-animation, the running animation fast-forwards to its end, so input is never locked.

### 4.3 `tavli_core` — rules and game model

**Position.** A compact value type over an `Int8List`:
- 24 points
- 2 bars
- 2 borne-off counts
- a pin mask for pinning games
- side to move

Stored in **player-relative coordinates**, so one move generator serves both opposing-direction and same-direction games. Each position has a web-safe incremental 30-bit Zobrist hash with equality confirmation, used for deduplication and memoization (see the SP1 design spec §3.2). Side-to-move lives in `GameState`, not `Position`.

**Variant rules.** A `VariantRules` value (extending today's `variant_rules.dart`) plus a small set of rule hooks:
- capture mode: hit / pin / none
- `singleControlsPoint`
- head rule with first-turn double exceptions
- prime restriction
- advancement rule
- mother piece
- bear-off rules
- opening procedure: winner rerolls or plays the opening dice
- doubles behaviour, including Gul Bara cascading doubles, which needs the turn counter tracked
- scoring: gammon, backgammon, Tawla 31 points
- cube availability

Engines are no longer selected by mechanic family; the engine reads the rules config. All 13 variants are declared as data plus tests.

**Play generation.** For each roll, generate the **complete set of legal full plays** once:
- make/unmake on one mutable buffer
- dedup by resulting position hash
- maximum-dice rule and higher-die rule applied

The result is stored as a **play tree**, so the UI can query `nextSteps(prefix)` in O(1). Every tap and drop is validated against this tree, which makes illegal partial plays impossible by construction.

**Game model.** `GameState` is an immutable value holding:
- position, phase, dice, cube state
- the current partial play
- the turn counter
- per-variant extras, e.g. Gul Bara state

The reducer `apply(GameState, Action) → Result(GameState, List<GameEvent>) | RuleViolation`:
- is deterministic and does no I/O
- takes no randomness: dice arrive as `RollDice(d1, d2)` actions, from a local secure RNG or from the server

The action set:
- `RollOpening`, `RollDice`
- `Step(from, to)`, `UndoStep`, `CommitPlay`
- `OfferDouble`, `Take`, `Drop`
- `Resign`, `Timeout`

**Match model.** `MatchState` covers:
- single games
- matches to N with Crawford
- Tawla 31
- marathon sequences: rotating variants, target score

`GameResult` carries the variant, the result type and the points.

**Serialization.** A versioned, compact JSON form of state and of the action log. The log is the single source for:
- undo
- resume-after-app-kill
- replay
- online sync
- spectate
- dual-board

### 4.4 `tavli_bot` — AI

- **Long-lived worker isolate,** spawned once per app session and warmed at game-screen open. Requests carry `(serialized state, difficulty, time budget, request id)` and can be cancelled when superseded. Nothing runs on the UI isolate.
- **Evaluators** per mechanic family (hitting / pinning / running), hand-tuned features behind an `Evaluator` interface. A future NN can drop in.
- **Search:**
  - 0-ply over all plays;
  - 1-ply expectimax over the 21 rolls for the top-K plays, with the opponent replying greedily at 0-ply;
  - iterative widening within the time budget.

  This fixes the side-to-move bug by construction: the side is part of the state.
- **Difficulty knobs:** K, depth, a noise/mistake model, and the share of top moves considered. Personality pacing (`TurnPacing`) is unchanged and sits in the session layer.
- **Also on the worker:**
  - cube decisions (offer / take / drop);
  - teaching-mode analysis, which ranks the player's options for highlight quality and end-of-turn feedback.
- **Speculative precompute:** while the human is moving, the worker may precompute the bot's reply for the likely positions. This is an optimisation only.

### 4.5 Session layer (`lib/gameplay/session`)

**`MatchSession`** is a Riverpod `Notifier`, auto-disposed and scoped per match. It:
- owns the `GameState`, the action log and the seat roster;
- exposes `state` for chrome, which uses `select`;
- exposes a `Stream<GameEvent>` for the board.

**Seats** share one interface:

| Seat | Behaviour |
|---|---|
| `HumanSeat` | Intents from the board |
| `BotSeat` | Calls the worker; plays steps out with `TurnPacing` beats |
| `RemoteSeat` | Over a `MatchTransport`, either the online server or BLE |
| `RecordedSeat` | Replays a log for replay mode |
| `ObserverSeat` | No seat; read-only, for spectate |

**Autoplay**, each item with a settings toggle and defaults on:
- forced moves play themselves;
- a turn with no legal move passes automatically, with a toast;
- greedy auto-bear-off, i.e. the remaining checkers bear off automatically at the end;
- auto-roll when no cube decision is possible;
- auto-commit when the last die is used (the existing `moveConfirmation` setting turns this off).

**Results pipeline.** One `GameFinished` handler feeds:
- progression and difficulty unlocks
- match history
- achievements
- coins
- per-variant rating
- challenges
- discovery
- marathon
- replay save

This replaces the ad-hoc calls in `victory_screen.dart`.

**Persistence.** The in-progress match log is saved on every commit, so a killed app resumes the game.

### 4.6 Board layer (`lib/gameplay/board`)

- **Retained Flame scene.** Components are created once per match, and checkers are pooled. Nothing is created or destroyed per frame or per rebuild. `HasCollisionDetection` and hitboxes are removed.
- **Render layers:**
  - the table and board are a static layer, rasterised once per resize or set change, or drawn as a Flutter image behind a transparent `GameWidget`;
  - checkers, dice and highlights are drawn from **sprite atlases**, with shadows baked into the sprites;
  - all `Paint`/`Vector2`/`TextPainter` objects are preallocated;
  - no blur or `saveLayer` in the per-frame path.
- **Input:**
  - Hit-testing is game-level, by **point column region** (the whole column, generous margins), not per-checker hitboxes. It returns the top playable checker.
  - Selection happens on **pointer-down**.
  - **Gestures:**
    - drag-and-drop: the checker follows the finger, drops snap to the nearest legal target, and an illegal drop springs back;
    - tap-to-move: a tap moves the checker by the active die, and tapping the dice swaps which die is active;
    - tap-then-tap is still supported;
    - double-tap a point to make it, where legal.
  - All gestures emit intents and are validated against the play tree.
- **Animation:**
  - one event queue with interruptible tweens;
  - a speed setting: slow, normal, fast, instant;
  - reduced-motion support;
  - a parallel cascade for bear-off.
- **Highlights:** pooled; quality colours in teaching mode; badge text pre-laid-out.
- **Assets:**
  - boards about 1200 px wide, WebP;
  - table about 1600×1000, WebP or a `ResizeImage`;
  - checker and dice atlases at 192 px;
  - unused PNGs removed;
  - Flame image cache cleared on set switch.
- **Audio/haptics:**
  - a singleton `AudioService` initialised at app start;
  - one preloaded player pool per SFX type;
  - volume and haptic settings honoured;
  - one haptic per event, not two.
- **Design system:** all new chrome uses `TavliColors`, `TavliSpacing` and `textTheme` tokens per `docs/design/00_TOKENS.md` and `02_COMPONENTS.md`. New tokens are added to `00_TOKENS.md` only if unavoidable.

### 4.7 Online (`server/` + `RemoteSeat`)

**Server.** A Dart `shelf` service on Cloud Run. It:
- verifies Firebase ID tokens;
- uses `tavli_core` to validate every action;
- holds the RNG for dice;
- writes authoritative state to Firestore in transactions, with a monotonically increasing `seq`.

**Endpoints:**
- `rooms.create`, `rooms.join(code)`, `rooms.leave`
- `match.enqueue`, `match.cancel`: matchmaking, with rating windows that widen over time and a TTL on queue entries
- `game.act(roomId, seq, action)`: roll, commit play, cube actions, resign, rematch
- `presence.ping`

**Turn flow.** Clients compose their play locally against the play tree, which gives instant feel and undo. They submit one `CommitPlay` per turn. The server validates it, appends it to the log and rolls the next dice. The opponent's client animates the steps.

**Firestore.**

| Path | Contents | Access |
|---|---|---|
| `rooms/{id}` | Authoritative state | Participants read; no client writes |
| `rooms/{id}/log/{seq}` | Action log | Participants read; no client writes |
| `spectate/{id}` | Public summary | Any signed-in user reads |
| `players/{uid}` | Cosmetic fields | Client writes cosmetic fields only; rating and stats are server-written |

**Presence and clock.**
- Server timestamps and an RTDB `onDisconnect` presence flag.
- Turn timers are enforced by the server on the next request and by a scheduled sweep.
- Reconnect resumes from `seq`.
- Abandonment resolves automatically.

**Auth.**
- Anonymous auth, plus Google sign-in with SHA-1/256 fingerprints registered for debug and release keys.
- A real release signing config.
- Account linking from anonymous to Google.

**Client resilience.**
- Every network call has a timeout and a user-visible error with retry.
- FCM topic subscription runs fire-and-forget, outside the critical path.

**Dual-board (BLE).** Uses the same `MatchTransport` abstraction:
- The host phone runs the authoritative session.
- The guest phone is a `RemoteSeat` over BLE.
- Each phone renders its half of the board.

**Spectate.** An `ObserverSeat` reads the room's log stream through `spectate/{id}`.

---

## 5. Engineering process and testing standard

**Process (superpowers):**
- Each sub-project runs brainstorm → spec → plan, then TDD per task, using subagent-driven development where tasks are independent.
- Each sub-project ends with a code-review subagent, then verification-before-completion including an on-device profile run.
- Work happens on a dedicated branch or worktree.
- Commits are small and each one passes the tests.

**Test pyramid:**

| Layer | Tests |
|---|---|
| `tavli_core` | Rulebook example tests per variant (sourced from `BACKGAMMON_RULES.pdf`, `MULTI_VARIANT_STRATEGY.md`, `tradition_lessons.dart`). Reference play-count fixtures. **Property/fuzz tests: ≥ 100,000 random games per variant** asserting invariants: 15 checkers each, no illegal states, max-dice/higher-die, termination, scoring. **Differential test** of Portes against the legacy generator. Serialization round-trips. Import-lint (no Flutter). |
| `tavli_bot` | Benchmarks with hard budgets (CI fails on regression). **Headless tournaments** with fixed seeds: Easy < Medium < Hard < Pappous, each beating the previous ≥ 60 % over 500 games per variant family. Cube-decision sanity suites. |
| Session | Scripted full games for every mode and seat combination. Autoplay rules. Undo. Resume from log. Results pipeline fan-out. |
| Board | `flame_test` component tests. Golden images per board/checker/dice set. Gesture tests (tap-down select, drag/drop, tap-to-move, swap dice, interrupt animation). |
| Device | `integration_test` + `flutter drive --profile` on the Galaxy S. Scripted full games per variant family and mode. Timeline summaries asserted against §3.3. |
| Online | Firebase Emulator Suite (Auth, Firestore, RTDB) plus the local server. **Two-client end-to-end games** (create/join, quick match, reconnect mid-game, timeout, resign, cheating attempts rejected). Firestore rules unit tests. Server unit tests. |

**CI (GitHub Actions):**
- Flutter pinned to the local version (3.41.x).
- Runs `dart analyze --fatal-infos`, format check, all package and app tests, the benchmark suite, and the emulator-backed online suite on every push.
- Builds an AAB and split-per-ABI APKs on tags.

**CI scope by stage (amended 2026-10-01 at SP0 close):**
- **Now:** SP0's CI runs `tool/ci/check.sh`: analyze, format of new code, and all package and app tests.
- **SP1/SP2:** benchmark budgets enter CI as each package gains budgeted benchmarks, scaled by `TAVLI_BENCH_SCALE`.
- **SP4:** the emulator-backed online suite enters CI.
- **SP5:** the tag-triggered AAB / split-APK build job returns, with secrets-based signing and `google-services.json` injection. It was dropped in SP0 because those files are not in git.

**Device workflow:**
- Performance is judged only on profile or release builds on the Galaxy S, never on debug or the emulator.
- The emulator is for functional checks only.

---

## 6. Sub-projects

Effort is relative, in focused development sessions. Each row's exit criteria are pass/fail.

| # | Sub-project | Scope | Exit criteria |
|---|---|---|---|
| **0** | Foundations | Workspace and packages scaffold. CI fixed and extended. Benchmark harness. Device profiling scripts (`adb` + `flutter drive --profile`). Import-lint. Disk-space and toolchain checklist (Firebase CLI, gcloud). | CI green on 3.41. A baseline perf report captured from the Galaxy S for the current app. |
| **1** | Game core | `tavli_core`: position, rules config for all 13 variants, play tree, reducer, match model, serialization. **Per-variant rules matrix reviewed by the user before coding.** | All core tests pass, including the 100k-game fuzz per variant and the Portes differential. Generation ≤ 2 ms p95. |
| **2** | Bot | `tavli_bot`: worker isolate, evaluators per family, budgeted search, difficulty model, cube decisions, teaching analysis. | Tournament ordering holds. Budgets pass on desktop and on the Galaxy S. Zero UI-isolate bot work. |
| **3** | Board & play | Session layer, Flame `BoardScene` rewrite, input model, animation system, assets pipeline, audio/haptics, autoplay settings. Vs-bot and pass & play migrated. Old `game_provider`, `flame_game/` and `ai_player` deleted. | Every §3.3 interaction budget passes on the Galaxy S. Full games in all 13 variants via integration tests. Manual QA checklist signed off by the user. |
| **4** | Online | Server, Firestore model, rules, matchmaking, presence/clock, reconnect, auth fixes (SHA-1, release signing), online screen on `MatchSession`, spectate. | Two-client end-to-end suite green on the emulators. A real two-device game on Galaxy S plus emulator. Cheating suite rejected. Opponent latency ≤ 500 ms p90. |
| **5** | Wire-up & ship | Results pipeline into progression, achievements, history, coins, rating, challenges, discovery, marathon, replay. Victory screen fixes. Dual-board over BLE. Startup (non-blocking init, bundled fonts). APK diet (AAB, split ABIs, drop TFLite, WebP). Release build on device. | All remaining §3.3 budgets pass. Every mode reachable and working. Release AAB ≤ 45 MB arm64. |

**SP0 close-out (2026-10-01).** All engineering items are done and `tool/ci/check.sh` is green locally. Two exit items depend on user actions and carry forward as tracked gates:
- **(a) Remote CI green.** Needs approval to push `rewrite/gameplay`.
- **(b) Galaxy S legacy device baseline.** Needs the phone and ≥ 15 GB of free disk. **It must be captured before SP3 begins**, because SP3 deletes the legacy game screen that `integration_test/perf/legacy_game_perf_test.dart` drives.

**SP1 setup notes from the SP0 review:**
- **Test config:** `tavli_core` needs its own `dart_test.yaml`, because the root one only applies to `flutter test`. It should define a `fuzz` tag with extended timeouts and an iteration count CI can scale, so the 100k-games-per-variant suite fits the 30-minute CI job.
- **Purity allowlist:** the `tavli_core` purity allowlist (`dart:core/async/collection/convert/math/typed_data` plus itself) is deliberate. Adding `package:meta` or `package:collection` means widening it on purpose.
- **Adapter location:** adapters between core types and the app's `GameVariant`/`GameResult` live in the app under `lib/gameplay/`, never in core.

**SP0 gate (a) closed 2026-10-02:** first GitHub CI run on `rewrite/gameplay` green (3m32s). Runner pinned to `ubuntu-24.04`.

**SP1 close-out (2026-10-02).** All exit criteria are met:
- 13 variants;
- rule-ID coverage;
- oracle differential;
- the 100k-per-variant fuzz (1.3M games, 0 failures);
- benchmarks within budget on desktop;
- CI green.

CI runs 40 fuzz games per variant; the 100k run is a recorded local exit run.

**Gates carried forward:**
- **(c)** Galaxy S AOT generation benchmark (≤ 2 ms p95), run alongside gate (b) before SP3.
- **(d)** Gul Bara cascades can take up to about 0.4 s to build, so SP3 reduces Gul Bara rolls off the UI isolate (or adds a pruning bound first), and SP4 keeps live states in memory.

**SP2 inputs from the SP1 review:**
- **Path to a play:** core needs `PlayTree` final→path (e.g. `pathTo(Position)` or plays-with-steps), because bots choose finals but submit `SubmitPlay(steps)`.
- **Bot isolate request:** use a lean request message (variant, position, side, dice, context, cube), not a `GameState` (its cached tree is heavy to copy) and not JSON (re-validation and tree rebuild).
- **Cascades:** cascade bots must walk or sample the lazy tree; Easy's 20 ms budget can't cover a worst-case cascade build, so cascade decisions get their own budget.
- **Minor test hardening:**
  - real hash checks via JSON rebuild in `mutable_position_test`;
  - a reducer-step regression cap of about 5 µs;
  - 200 positions in the legacy differential.

**SP3 input:** a "remaining dice" helper for the UI.

**SP2 close-out (2026-10-20).** All SP2 engineering exit items are met:
- 164 bot tests;
- desktop-gate benchmarks within budget;
- strength gates in Portes, Plakoto and Fevga;
- legacy floor 85.3 %;
- worker responsiveness gate;
- CI green.

Details: `docs/superpowers/perf/2026-10-02-sp2-bot-report.md`.

**Carried gates:**
- **(c), extended:** the Galaxy S AOT run also covers the bot benchmarks. Re-check Expert's margin at the measured device speed ratio; the lever is a smaller Expert kMax.
- **(d):** Gul Bara cascade latency and garbage-collection pauses from the shared isolate heap (measured p99 ≈ 8 ms, max ≈ 15 ms on desktop).

**Open for the user:** the Expert-vs-Hard gate was passed under the lenient reading "the 95 % CI upper bound ≥ 50 %". No family shows Expert *significantly* stronger than Hard. Expert vs Medium is 63–71 %.

**SP3 inputs from the SP2 review:**
- **Request helper:** a `BotRequest.fromState(GameState, {kind, level, id, seed})` helper. The turn-start context is private in core, so expose `GameState.turnStartContext`. The helper must handle cascades, remainder turns, Crawford, the cube, and analyze steps.
- **Evaluator tests:** labelled pairs for the new running-evaluator terms (points held, home, stacking).
- **Tournament log:** commit gate-run outputs and the tuning harness for auditability.

Ordering: 0 → 1 → 2 → 3 → 4 → 5. Sub-project 4's server work may start in parallel with 3 once 1 is done, because both depend only on `tavli_core`.

### 6.1 Migration strategy
- The new code is built alongside the old under `lib/gameplay/` and `packages/`.
- A developer flag routes each mode to the new or legacy implementation until that mode's sub-project exits, then the legacy code for that mode is deleted in the same sub-project.
- Assets, settings keys, design tokens, personalities and dialogue databases are reused unchanged.
- **Shared-vocabulary carve-outs (decided 2026-10-01 in SP0 review).** The architecture test permits these legacy files as boundary files and does not traverse into them:
  - `GameVariant` (`features/game/domain/engine/variants/game_variant.dart`) and `GameResult` (`features/game/data/models/game_result.dart`). Together they form the shared vocabulary of about 20 non-gameplay features: learn, discovery, progression, achievements, settings, copy. `Tradition` reaches legacy code only through `GameVariant`, so it needs no carve-out.
  - `features/game/presentation/widgets/turn_handoff_pill.dart`: reusable chrome.
  - `features/multiplayer/domain/` (rating system, per-variant rating): targets of the SP5 results pipeline.

  Then:
  - **SP1** adds canonical `tavli_core` variant/result types and adapters to and from the app types.
  - **SP5** moves the app-level variant metadata (display names, tradition grouping) to a neutral home, deletes the legacy engine directory, and removes the carve-outs.
- The boundary check is **transitive**: no file reachable from `lib/gameplay/**` may be legacy gameplay code, except through a carve-out.
- `TurnPacing` values carry over.
- Settings that already exist but are unused (`moveConfirmation`, `showPipCount`, volumes) are honoured.

---

## 7. Risks and open items

| Risk / item | Mitigation |
|---|---|
| Variant rules are ambiguous or regional (Gul Bara, Long Nard head-rule exceptions, Tawla 31 scoring, Tapa) | SP1 opens with a per-variant rules matrix, with sources, for **user sign-off** before coding |
| Blaze plan, gcloud project and Cloud Run deploy need the user's account actions | SP0's `tool/doctor.sh` checks that the CLIs are installed. The account-setup checklist (Blaze, gcloud project, Cloud Run, service accounts) is part of the SP4 plan. Claude prepares commands and config; the user performs billing and console steps |
| SHA-1 registration and release keystore need the user's Firebase console access | SP4 step-by-step instructions; verified by a real sign-in on device |
| Low disk space (≈ 1.9 GB free) blocks Android builds | SP0 prerequisite: free ≥ 15 GB |
| No Xcode → iOS untested | Code stays platform-neutral. iOS verification deferred until Xcode is installed |
| Dual-board needs two physical BLE phones | Transport is tested with a fake BLE link in CI. Real-device test when two phones are available |
| Bot strength regressions vs today | Tournament gates against the legacy bot (Easy) and between levels |

---

## 8. Definition of done (program)

1. All six sub-projects have met their exit criteria.
2. Every §3.3 budget passes on the Galaxy S in profile/release mode.
3. All 13 variants are playable vs bot, pass & play and online, with verified rules.
4. Replay, spectate, marathon, challenges and dual-board are reachable and working.
5. CI is green, with the fuzz, tournament, benchmark and online end-to-end suites included.
6. The user has signed off a manual QA session on the Galaxy S.
