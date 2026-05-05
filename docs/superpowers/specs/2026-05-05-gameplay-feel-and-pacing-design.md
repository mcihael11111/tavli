# Gameplay Feel & Pacing — Design Spec

**Date:** 2026-05-05
**Status:** Approved (awaiting written-spec review)
**Scope:** Single unified PR to `fix/gameplay-qa-alignment` (or successor branch)

## 1. Problem

Reported issues:

1. Bot turn end → player turn start has ~1.2–1.4s of perceived lag, during which all input is blocked.
2. Tapping a checker provides no immediate visual feedback on the tapped checker itself; only destination highlights appear, and they are 1+ frame delayed via the Flame component tree.
3. The hint badge (green circle showing dice value above a destination point) is visibly offset from the column centerline, and the highlight glow bleeds outside the triangle path.
4. Turn changes feel "jumpy" — the screen background fades between two distinct colors (`TavliColors.primary` brown ↔ `TavliColors.botThinkingBg` blue-grey) over 400ms on every turn flip, plus avatar borders swap synchronously. The constant chrome flipping reads as visual noise.
5. The player's *second* tap inside their own turn (the second checker move of a non-doubles roll) feels delayed in `easyWithHelp` mode, distinct from general tap latency. Cause: synchronous AI equity evaluation runs twice per move on the UI thread.

## 2. Goals

- Tighten end-of-turn pacing without removing the deliberate "thinking" beat that gives bots personality.
- Make tap responses feel instant: visual confirmation in <16ms, haptic at the moment of tap commit (not after animation).
- Eliminate alignment and clipping bugs in the hint indicator system.
- Allow the player to pre-select their next checker while the bot is finishing its animations (including bear-off).
- Improve readability of game state transitions with a small turn-handoff label and a dice cue ring.
- Calm the screen during turn handoff: replace the animated background-color swap with a static wood-grain image; route the active-player signal through the new turn pill instead of multiple chrome surfaces.
- Eliminate UI-thread freezes between successive player moves in teaching mode by caching move-quality evaluations and decoupling them from `build()`.

## 3. Non-goals

- Onboarding, difficulty selection, victory, settings, multiplayer, marathon, learn/tutorial, customization, profile, replay.
- Changes to AI move-selection logic, doubling-cube logic, or game rules.
- New animation styles beyond the specific additions listed (no easing curve overhaul, no shader work).
- Doubling-cube pacing — the 800ms response delay is intentional and stays.

## 4. Architecture

Three layers, in order of size:

### 4.1 Pacing engine (new module)

`lib/features/ai/pacing/turn_pacing.dart` exposes a `TurnPacing` value object computed from `(DifficultyLevel, BotPersonality)`. It returns:

```dart
class TurnPacing {
  final Duration thinkingBeat;        // before bot rolls
  final Duration dicePostRollBreather;// after roll, before moves start
  final Duration interMoveSettle;     // between successive bot moves
  final Duration finalSettle;         // after bot's last move, before handoff
  final Duration diceRattle;          // dice animation duration
  // Factory: TurnPacing.forBot(DifficultyLevel, BotPersonality)
  // Default fallback: Mikhail-medium row.
}
```

The hardcoded `Future.delayed(...)` calls in `game_screen.dart` (`_handleAiTurn`, lines 489, 512, 558, 595) are migrated to read from this object.

### 4.2 Input gating (refactor)

The single `_animationInProgress` flag in `game_screen.dart` is split into two:

- `_destinationLocked` — blocks **destination** taps while the current move animation runs. Same role the old flag had for moves.
- `_selectionLocked` — blocks **selection** taps. True only during dice rattle and during the brief window between turn-state changes when board state is mid-sync.

The pre-input window is the result: when the bot's last move begins animating, `_selectionLocked` releases (the bot's destination is committed in state) but `_destinationLocked` stays until the animation finishes. The player can pre-select their checker, but their destination tap waits for the animation.

The existing 3-second `Future.wait(animations).timeout(...)` guard at `tavli_game.dart:380` remains — pre-input behavior is safe inside that guard because state sync runs first.

### 4.3 Visual additions

- `CheckerComponent.setSelected(bool)` — synchronous scale tween (1.00 → 1.06, 80ms ease-out) + ring overlay using `TavliColors.primary` (2px stroke at radius+3px, opacity 0 → 0.85, 80ms) + soft drop-shadow. Fires same frame as `onTapUp`. Color choice: `primary` reads on both light and dark checker palettes, avoids needing a per-player accent token.
- `HighlightComponent` — alignment fix (badge center reads from apex vertex in parent coords, not padded-bbox local coords) + glow clipping (`canvas.clipPath(trianglePath)` before fill, replacing `MaskFilter.blur` on rect).
- `TurnHandoffPill` (new widget, in player names header) — three states: "Your turn" / "{BotName} thinking…" / "{BotName} moving…". 24px-tall, surface bg, Poppins 12sp, 120ms cross-fade between labels.
- `DiceCueRing` (new Flame component) — faint pulsing ring around the dice cup region while it's the player's turn to roll AND no roll initiated. Color: `primary` at 0.35, 2px stroke, pulse 0.35→0.65→0.35 over 1400ms loop. Disappears instantly when roll begins.
- Bear-off cascade (modification to `tavli_game.dart` orchestration) — when `isTrivialBearOff()` triggers, remaining checkers animate concurrently with 35ms staggered start. Per-checker: 130ms move + 60ms scale-down (0.8). Total ~200–270ms for 2–6 checkers. Same path used for AI's trivial bear-off ending.
- **Static wood-grain background** — replace the `AnimatedContainer` color swap at `game_screen.dart:686-693` with a `Container` whose `decoration` is `DecorationImage(AssetImage('assets/images/backgrounds/table.png'), fit: BoxFit.cover)`. The asset is already present (5.5 MB) and registered under `assets/images/backgrounds/` in `pubspec.yaml`. Scaffold becomes `backgroundColor: Colors.transparent`. `TavliColors.botThinkingBg` is no longer used by the game screen (we leave the constant defined for any other consumer). Avatar borders no longer swap colors on turn change — the active-player signal moves entirely to the `TurnHandoffPill`.
- **Move-quality cache** (teaching mode performance fix) — `_computeMoveQualities()` becomes a cached, microtask-scheduled computation. New `MoveQualityCache` keyed by `(boardHash, selectedPoint, remainingDice)` lives on the `gameProvider` notifier. `selectChecker(point)` schedules the computation via `Future.microtask`; `build()` reads from cache only (synchronous, no recomputation). `_checkTeachingFeedback()` early-returns on `gs.remainingDice.isNotEmpty` *before* invoking `evaluateMoveLoss()`, so the heavy AI call no longer fires between move 1 and move 2.

## 5. Pacing tables

### 5.1 Base values (apply at all difficulties)

| Constant | Today | New |
|---|---|---|
| Dice rattle | 420ms | 280ms (face-flip cadence 60ms → 45ms) |
| Post-roll breather (bot) | 280ms | 160ms |
| Inter-move settle (non-final) | 80ms | 40ms |
| Final settle (after last move) | 60ms | 60ms (unchanged) |
| Checker move animation | 130ms | 130ms (unchanged) |
| Trivial bear-off cascade total | 6×130=780ms | ~250ms (parallel, 35ms stagger) |

### 5.2 Personality-aware "thinking" beat (replaces flat 180ms at game_screen.dart:489)

| Difficulty | Mikhail | Spyros | Nikos |
|---|---|---|---|
| easy | 100 | 60 | 60 |
| easyWithHelp | 100 | 60 | 60 |
| medium | 160 | 110 | 80 |
| hard | 220 | 150 | 100 |

All values in milliseconds. Mikhail (kafeneio elder) is +40–60ms over the others by design; harder difficulty = longer pause to read as "calculating."

The doubling-cube response delay (`game_screen.dart:624`) stays at 800ms — explicitly out of scope.

## 6. Tap feedback details

### 6.1 Selection (checker tapped)

Synchronous in `CheckerComponent.onTapUp`:

1. `setSelected(true)` fires (scale + ring + shadow tween starts same frame).
2. `HapticFeedback.selectionClick()` (already exists, unchanged).
3. `selectChecker(pointIndex)` on notifier (already exists, unchanged).

The new piece is step 1: visual confirmation lands before any state propagation. Highlights still appear next frame as today.

### 6.2 Destination (highlight tapped)

In `_onDestinationTapped`:

1. `HapticFeedback.lightImpact()` fires **immediately** (currently fires at line 268 *after* `await animateMoveTo`).
2. `_destinationLocked = true`.
3. `makeMove(toPoint)` (synchronous state mutation).
4. `await _game.updateBoardState(...)` (130ms animation).
5. Landing SFX fires when animation completes (unchanged).
6. `_destinationLocked = false`.
7. The selected checker's `setSelected(false)` fires automatically when board state syncs and the moving checker reaches its new home.

## 7. Hint badge & glow fix

### 7.1 Misalignment root cause

`highlight_component.dart:65–83` computes a bounding box around the three triangle vertices, adds 4px uniform padding, sets the component `position` to `(minX - pad, minY - pad)`, and translates vertices to local coords via `v.x - minX + pad`. The badge center is read from `_localVerts[2]` (the apex) at line 92.

Because the triangle base is wider than the apex, the bbox is centered on the *base midpoint*, not the apex. The apex's local x and the bbox horizontal center can diverge by sub-pixel-to-1px amounts due to padding. The badge inherits this drift.

### 7.2 Fix

- Compute `_badgeCenter` directly from the apex vertex in the **parent (board) coordinate space**.
- Set the badge as a separate Flame `PositionComponent` with its own `position`, independent of the highlight's bbox.
- The highlight bbox math stays for hit-testing but no longer drives badge placement.

### 7.3 Glow bleed root cause

The current implementation paints a fill on a path with `MaskFilter.blur(6px)` — the blur extends past the triangle silhouette by ~6px in all directions, into the surrounding background.

### 7.4 Fix

- Build the triangle `Path` once, reuse for fill, stroke, and clip.
- Wrap the highlight rendering in `canvas.save()` → `canvas.clipPath(trianglePath)` → fill + inset glow → `canvas.restore()`.
- Replace `MaskFilter.blur` on the fill with a soft inset shadow (multiple stacked semi-transparent fills, or a `Paint` with `Shader.linear` from edge to center) — anything that stays inside the path.
- Stroke (red border in screenshots) draws the path itself, not the bbox edges.

### 7.5 Hitbox shape (no change)

The `containsPoint` override at `highlight_component.dart:248-266` is **already a rectangular bbox check**, not a point-in-polygon triangle test. The visual is a triangle but the hit zone covers the full bounding box (triangle base width × triangle height plus the 4px padding). This was an explicit prior fix to handle the narrow tip being unhittable. The implementation pass MUST preserve this — do not regress to a triangle hit-test when refactoring the visual rendering.

## 8. New widgets — full specs

### 8.1 TurnHandoffPill

- Location: inline with the active player's name in the players header.
- Width: fits content, no min/max — but never resizes during cross-fade (precompute longest label, lock width).
- Height: 24px.
- Background: `TavliColors.surface`.
- Foreground: `TavliColors.text`.
- Typography: Poppins 12sp, weight 500.
- Padding: 8px horizontal, 4px vertical.
- States and labels (localized via existing `l10n`):
  - Player turn: `playerTurn` → "Your turn" / "Σειρά σας"
  - Bot thinking: `botThinking(name)` → "Mikhail thinking…" / "Μιχαήλ σκέφτεται…"
  - Bot moving: `botMoving(name)` → "Mikhail moving…" / "Μιχαήλ κινείται…"
- Animation: cross-fade label changes 120ms (no width animation).

### 8.2 DiceCueRing (Flame component)

- Renders only when: `state.phase == playerTurnStart` AND dice not yet rolled AND `!_selectionLocked`.
- Position: centered on the dice cup hit area for the active player.
- Geometry: 2px stroke circle, radius = cup hit radius + 4px.
- Color: `TavliColors.primary` at 0.35 alpha.
- Pulse: opacity 0.35 → 0.65 → 0.35, easeInOut, period 1400ms, looping.
- Removal: instant (no fade) when roll begins. Dice rattle is the next visual signal.

### 8.3 Bear-off cascade

- Trigger: `isTrivialBearOff()` returns true AND user taps COMPLETE button (or AI's auto-trivial-bear-off path fires).
- Per-checker animation: 130ms move-to-tray + 60ms scale 1.0 → 0.8, in parallel.
- Stagger: 35ms between checker starts.
- Total wall time: 35ms × (n−1) + 190ms ≈ 200–270ms for 2–6 checkers.
- SFX: `checkerBearOff` fires per-checker (audible cascade clack).
- State commit ordering: state commit → animate (parallel cascade) → game-over phase transition → victory screen. The pre-input window MUST NOT allow taps on the victory screen until both the cascade animations resolve AND the phase transition fires. The existing `await Future.wait(animations).timeout(...)` at `tavli_game.dart:380` already gates this; we preserve it for the parallel cascade by passing the cascade's animation futures into the same wait.

## 8.4 Background image and active-player signal

- Game screen scaffold body wrapped in a `Container` with `BoxDecoration(image: DecorationImage(...))` pointing at `assets/images/backgrounds/table.png`, `fit: BoxFit.cover`. Image is loaded once via `AssetImage` (Flutter caches it).
- Scaffold `backgroundColor: Colors.transparent` so the wood reads through the entire chrome.
- The previous `AnimatedContainer` and the `(_aiThinking || gs.isAiTurn) ? botThinkingBg : primary` branch are removed.
- Avatar borders at `game_screen.dart:878` and `:948` change from a turn-dependent color to a single static color (`TavliColors.primary`). The active-player signal is delivered exclusively via `TurnHandoffPill`. Per user confirmation, avatars no longer swap.
- ReducedMotion path: prior code wrapped the bg in `ReducedMotion.duration(...)`; with the static image there is nothing to animate and the wrapper is no longer needed at the bg site.
- Image asset memory: 5.5 MB PNG. Acceptable for a game screen that already loads multiple board sprites. If profiling shows pressure on lower-end Android, follow up by adding a downsized variant — explicitly out of scope for this PR.

## 8.5 Move-quality cache

- New class `MoveQualityCache` in `lib/features/game/presentation/providers/move_quality_cache.dart`. Holds an in-memory `Map<String, Map<int, MoveQuality>>`. Key is a normalized string `"$boardHash:$selectedPoint:${(List.of(remainingDice)..sort()).join(',')}"` — sorting `remainingDice` makes the key invariant to dice ordering (which doesn't affect legality or quality).
- Hooks into `GameProvider`:
  - On `selectChecker(point)`: if cache miss, schedule computation via `Future.microtask(() => _computeAndCache(...))`. The provider exposes a `qualitiesForSelected` getter that returns the cached value or `null` (in flight).
  - On `makeMove(...)`: invalidate entries whose `remainingDice` no longer match the new state.
  - On `clearSelection()` / turn end: optional cleanup; map is bounded by the small set of selectable checkers per turn.
- `game_screen.dart:421-460` (`_computeMoveQualities`) becomes a thin reader of `qualitiesForSelected`. It NEVER triggers a fresh computation in `build()`.
- `game_screen.dart:298` (`_checkTeachingFeedback`) gains an early-return `if (gs.remainingDice.isNotEmpty) return;` *above* the call to `evaluateMoveLoss()` so the heavy eval is skipped on intra-turn moves.
- Result: between move 1 completing and move 2 input being accepted, no synchronous AI eval runs. The `_destinationLocked` window stays at 130ms (animation duration only), unblocked by CPU stalls.

## 9. Error handling

- **Bot's last move hits the player's pre-selected checker:** when state syncs and the pre-selected checker is now on the bar, `setSelected(false)` fires automatically. Selection ring clears cleanly.
- **Animation overrun:** existing 3s `Future.wait(...).timeout(onTimeout: () => <void>[])` at `tavli_game.dart:380` stays. Pre-input remains safe because state sync precedes the timeout fallback path.
- **COMPLETE button mid-animation:** the button reads `_destinationLocked` (the same flag that gates per-move destination taps). Tap is rejected until animations idle. No third flag — keeping the input-gating model strictly two-flag.
- **Unknown personality:** `TurnPacing.forBot(diff, persona)` falls back to the Mikhail row at the requested difficulty. Default-safe.
- **Pre-input race on phase change:** if the user pre-selects but the bot's final move triggers a phase change to `gameOver` before the destination tap, `_selectionLocked` re-engages and the pending selection is dropped silently. No crash, no false move.
- **Move-quality cache stale read:** if a checker is selected and the player taps a destination *before* the microtask completes, the destination tap path does not depend on cached qualities — it consults `availableMovesForSelected` directly. Stale or missing cache entries only affect the visual hint badges, not move legality.
- **Background image fails to load:** `AssetImage` failure surfaces as a missing image; the underlying scaffold defaults to `Colors.transparent`, which would render the OS window color. Add a `Container` fallback color of `TavliColors.primary` behind the image so a load failure produces the prior visual instead of a transparent screen.

## 10. Testing

### 10.1 Unit

- `TurnPacing.forBot()` returns positive durations for every `(DifficultyLevel, BotPersonality)` permutation.
- Snapshot test on the full table values to prevent silent regressions.
- Fallback: `TurnPacing.forBot(hard, <unknown_personality>)` returns the Mikhail-hard row.

### 10.2 Widget

- `TurnHandoffPill` swaps label across all three states, cross-fade timing within ±10ms of 120ms.
- Tapping a `CheckerComponent` calls `setSelected(true)` and updates its rendered scale within one frame (no `pumpAndSettle` required before assertion).
- Destination tap: `HapticFeedback.lightImpact()` is invoked synchronously, before `await animateMoveTo` resolves.

### 10.3 Golden

- Hint badge centerline matches triangle apex centerline within 0.5px tolerance, across all 24 board points (12 top + 12 bottom).
- Highlight glow does not extend past the triangle path bounds (compare against a clipping mask).

### 10.4 Integration

- A full bot turn ends within `dicePostRollBreather + Σ(moves × (130 + interMoveSettle))` for each `(personality, difficulty)` pair. Hard upper bound: 1.0s wall-clock for a 4-move bot turn at any difficulty.
- Pre-input window: while bot is animating its final move, the player can call `selectChecker(...)` and observe `setSelected(true)` on the rendered component. Destination tap is rejected until animation finishes.
- Teaching-mode second-tap latency: in `easyWithHelp`, time between move-1 animation completion and move-2 destination tap being accepted MUST be under 50ms (one animation frame plus jitter). Test framework measures this by stubbing the AI evaluator with a 100ms-sleep variant and asserting the second tap is processed without waiting for the eval.
- Background image: scaffold renders `assets/images/backgrounds/table.png` regardless of `(isAiTurn, isPlayerTurn)`. No widget rebuild, no color tween fires on turn transition.

### 10.5 Manual QA

- Three full games, one per difficulty (easy / medium / hard).
- Each personality played at least once (Mikhail / Spyros / Nikos).
- Verify pacing reads right and pill labels match game state at all times.
- Bear-off cascade: trigger trivial bear-off both from player and from bot side, confirm timing.

## 11. Rollout

- Single unified PR.
- No feature flag (these are quality fixes, not gated experiments).
- Commit order inside the PR (for reviewer sanity, not separate ships):
  1. Add `TurnPacing` + tests, migrate hardcoded delays to read from it.
  2. Refactor input gating to two-flag model (`_destinationLocked`, `_selectionLocked`).
  3. Hint badge alignment + glow clip + golden tests.
  4. Tap selection visual + immediate haptic on destination.
  5. `TurnHandoffPill` widget + `DiceCueRing` Flame component.
  6. Bear-off cascade (parallel animation orchestration).
  7. Static wood-grain background + remove avatar border swap.
  8. `MoveQualityCache` + microtask scheduling + teaching-mode early-return.
- After merge, observe one play session in TestFlight before announcing in release notes.

## 12. Files

### Modified (7)

- `lib/features/game/presentation/game_screen.dart` (~200 lines changed, the largest diff — pacing migration, input gating, bg swap, avatar border simplification, teaching-mode early-return, cache reads)
- `lib/features/game/presentation/providers/game_provider.dart` (selection lock state, cache hookup on `selectChecker` / `makeMove`)
- `lib/flame_game/components/checker_component.dart` (selection visual)
- `lib/flame_game/components/highlight_component.dart` (alignment + clipping)
- `lib/flame_game/components/dice_component.dart` (timing constants only)
- `lib/flame_game/tavli_game.dart` (animation orchestration for bear-off cascade)
- `lib/features/ai/engine/ai_player.dart` (no logic change — exposes personality to pacing call site)

### Added (4)

- `lib/features/ai/pacing/turn_pacing.dart`
- `lib/features/game/presentation/widgets/turn_handoff_pill.dart`
- `lib/flame_game/components/dice_cue_ring.dart`
- `lib/features/game/presentation/providers/move_quality_cache.dart`

### Localization

- Three new strings in `lib/l10n/`: `playerTurn`, `botThinking(name)`, `botMoving(name)`. Greek and English at minimum (matching existing supported locales).

## 13. Out of scope

Onboarding, difficulty selection screen, victory screen, settings, multiplayer, marathon, learn/tutorial, customization, profile, replay, dual-board, BLE board integration, AI move-selection logic, doubling-cube logic, game rules, easing-curve system, shader work.
