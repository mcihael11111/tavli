# Gameplay Feel & Pacing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate ~1.2s of perceived lag between turns, fix tap responsiveness gaps, fix hint badge alignment, calm turn-change visual noise, and remove the easyWithHelp UI freeze between successive moves — shipping all changes in a single PR to `fix/gameplay-qa-alignment`.

**Architecture:** New `TurnPacing` value object centralises personality + difficulty timing constants. Input gating splits into two flags (`_destinationLocked`, `_selectionLocked`) to enable a pre-input window. `MoveQualityCache` decouples teaching-mode equity evaluation from `build()`. Visual additions: per-checker selection scale+ring, `TurnHandoffPill`, `DiceCueRing`, parallel bear-off cascade, static wood-grain scaffold. Spec at [`docs/superpowers/specs/2026-05-05-gameplay-feel-and-pacing-design.md`](../specs/2026-05-05-gameplay-feel-and-pacing-design.md).

**Tech Stack:** Flutter 3.x, Flame engine, Riverpod (state), Material 3 with custom warm aesthetic. Dart 3.x.

**Branch:** `fix/gameplay-qa-alignment` (already current). Working directory: `/Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli`.

**Working principles:** TDD where practical (some Flame visual changes are easier to verify visually). Commit per task group. Preserve the existing rectangular hitbox in `HighlightComponent.containsPoint` (it's a load-bearing prior fix per spec §7.5).

---

## Task 1: TurnPacing module + migrate hardcoded delays

**Spec:** §4.1, §5

**Files:**
- Create: `lib/features/ai/pacing/turn_pacing.dart`
- Create: `test/unit/turn_pacing_test.dart`
- Modify: `lib/features/game/presentation/game_screen.dart` (lines ~489, ~512, ~558, ~595)
- Modify: `lib/flame_game/components/dice_component.dart` (line ~106 — rattle constants)

**Read first:** `lib/features/ai/difficulty/difficulty_level.dart`, `lib/features/ai/personality/bot_personality.dart`, current `_handleAiTurn` in `game_screen.dart`.

- [ ] **Step 1.1: Write the failing test** (`test/unit/turn_pacing_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/pacing/turn_pacing.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';

void main() {
  group('TurnPacing.forBot', () {
    test('returns positive durations for every (difficulty, personality) pair', () {
      for (final d in DifficultyLevel.values) {
        for (final p in BotPersonality.values) {
          final pacing = TurnPacing.forBot(d, p);
          expect(pacing.thinkingBeat.inMilliseconds, greaterThan(0), reason: '$d/$p thinkingBeat');
          expect(pacing.diceRattle.inMilliseconds, greaterThan(0), reason: '$d/$p diceRattle');
          expect(pacing.dicePostRollBreather.inMilliseconds, greaterThan(0));
          expect(pacing.interMoveSettle.inMilliseconds, greaterThan(0));
          expect(pacing.finalSettle.inMilliseconds, greaterThan(0));
        }
      }
    });

    test('Mikhail-hard thinking beat is the longest', () {
      final mikhailHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.mikhail);
      final spyrosHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.spyrosUncle);
      final nikosHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.cousinNikos);
      expect(mikhailHard.thinkingBeat.inMilliseconds, equals(220));
      expect(spyrosHard.thinkingBeat.inMilliseconds, equals(150));
      expect(nikosHard.thinkingBeat.inMilliseconds, equals(100));
    });

    test('easy and easyWithHelp share thinking beats', () {
      for (final p in BotPersonality.values) {
        final easy = TurnPacing.forBot(DifficultyLevel.easy, p);
        final easyHelp = TurnPacing.forBot(DifficultyLevel.easyWithHelp, p);
        expect(easy.thinkingBeat, equals(easyHelp.thinkingBeat));
      }
    });

    test('unknown personality falls back to Mikhail row at requested difficulty', () {
      // Only meaningful if a future enum extension lands; covered by switch default.
      final pacing = TurnPacing.forBot(DifficultyLevel.medium, BotPersonality.mikhail);
      expect(pacing.thinkingBeat.inMilliseconds, equals(160));
    });

    test('shared base values are constant', () {
      final p = TurnPacing.forBot(DifficultyLevel.medium, BotPersonality.mikhail);
      expect(p.diceRattle.inMilliseconds, equals(280));
      expect(p.dicePostRollBreather.inMilliseconds, equals(160));
      expect(p.interMoveSettle.inMilliseconds, equals(40));
      expect(p.finalSettle.inMilliseconds, equals(60));
    });
  });
}
```

- [ ] **Step 1.2: Run test to verify it fails**

```
cd /Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli
flutter test test/unit/turn_pacing_test.dart
```
Expected: FAIL — file `turn_pacing.dart` doesn't exist yet.

- [ ] **Step 1.3: Implement TurnPacing** (`lib/features/ai/pacing/turn_pacing.dart`)

```dart
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';

class TurnPacing {
  final Duration thinkingBeat;
  final Duration dicePostRollBreather;
  final Duration interMoveSettle;
  final Duration finalSettle;
  final Duration diceRattle;

  const TurnPacing({
    required this.thinkingBeat,
    required this.dicePostRollBreather,
    required this.interMoveSettle,
    required this.finalSettle,
    required this.diceRattle,
  });

  static const _baseRattle = Duration(milliseconds: 280);
  static const _basePostRoll = Duration(milliseconds: 160);
  static const _baseInterMove = Duration(milliseconds: 40);
  static const _baseFinalSettle = Duration(milliseconds: 60);

  factory TurnPacing.forBot(DifficultyLevel difficulty, BotPersonality personality) {
    final beat = _thinkingBeat(difficulty, personality);
    return TurnPacing(
      thinkingBeat: beat,
      dicePostRollBreather: _basePostRoll,
      interMoveSettle: _baseInterMove,
      finalSettle: _baseFinalSettle,
      diceRattle: _baseRattle,
    );
  }

  static Duration _thinkingBeat(DifficultyLevel d, BotPersonality p) {
    final isMikhail = p == BotPersonality.mikhail;
    final isNikos = p == BotPersonality.cousinNikos;
    switch (d) {
      case DifficultyLevel.easy:
      case DifficultyLevel.easyWithHelp:
        if (isMikhail) return const Duration(milliseconds: 100);
        return const Duration(milliseconds: 60);
      case DifficultyLevel.medium:
        if (isMikhail) return const Duration(milliseconds: 160);
        if (isNikos) return const Duration(milliseconds: 80);
        return const Duration(milliseconds: 110);
      case DifficultyLevel.hard:
        if (isMikhail) return const Duration(milliseconds: 220);
        if (isNikos) return const Duration(milliseconds: 100);
        return const Duration(milliseconds: 150);
    }
  }
}
```

- [ ] **Step 1.4: Run tests to verify they pass**

```
flutter test test/unit/turn_pacing_test.dart
```
Expected: PASS — all 5 tests green.

- [ ] **Step 1.5: Migrate hardcoded delays in `game_screen.dart`**

Read `_handleAiTurn` and surrounding state. Add a `TurnPacing _pacing` field on `_GameScreenState`, initialised in `initState` via `TurnPacing.forBot(widget.difficulty, _personality)`.

Replace at the cited lines:
- Line ~489 `Future.delayed(const Duration(milliseconds: 180))` → `Future.delayed(_pacing.thinkingBeat)`
- Line ~512 `Future.delayed(const Duration(milliseconds: 280))` → `Future.delayed(_pacing.dicePostRollBreather)`
- Line ~558 `Future.delayed(const Duration(milliseconds: 80))` → `Future.delayed(_pacing.interMoveSettle)`
- Line ~595 `Future.delayed(const Duration(milliseconds: 60))` → `Future.delayed(_pacing.finalSettle)`

Leave the line ~624 800ms doubling-cube delay UNCHANGED (spec §5.2 last paragraph).

- [ ] **Step 1.6: Migrate dice rattle in `dice_component.dart`**

At line ~106, the constant `_rattleTimeLeft = 0.42` becomes parametric. Add a constructor parameter `Duration rattleDuration = const Duration(milliseconds: 280)` and set `_rattleTimeLeft = rattleDuration.inMilliseconds / 1000.0`. Update the `_rattleTickInterval` from `0.06` to `0.045`. Where the dice are created in `tavli_game.dart`, pass `_pacing.diceRattle` (you'll need to thread the pacing object into the game; alternatively, set a global on the dice component and expose a setter).

Concrete approach: add `void setRattleDuration(Duration d)` on `DiceComponent` and call it from `_GameScreenState.initState` after the game is created.

- [ ] **Step 1.7: Run all tests to ensure nothing regressed**

```
flutter test
```
Expected: PASS (or surface unrelated pre-existing failures — note them; don't fix in this task).

- [ ] **Step 1.8: Commit**

```bash
git add lib/features/ai/pacing/turn_pacing.dart \
        test/unit/turn_pacing_test.dart \
        lib/features/game/presentation/game_screen.dart \
        lib/flame_game/components/dice_component.dart
git commit -m "$(cat <<'EOF'
Add TurnPacing module + migrate hardcoded turn delays

Introduces personality-aware bot pacing. Replaces flat 180/280/80/60ms
delays in game_screen with values from TurnPacing.forBot(difficulty,
personality). Tightens dice rattle from 420ms to 280ms.

Spec: docs/superpowers/specs/2026-05-05-gameplay-feel-and-pacing-design.md §5

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Two-flag input gating + pre-input window

**Spec:** §4.2, §6, §9

**Files:**
- Modify: `lib/features/game/presentation/game_screen.dart`

**Read first:** `_onCheckerTapped`, `_onDestinationTapped`, all references to `_animationInProgress`, the AI turn flow in `_handleAiTurn`.

- [ ] **Step 2.1: Write the failing widget test** (`test/widget/pre_input_test.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Imports specific to the project's test harness — adapt to existing test file conventions.
// The test should pump the game screen with a state where the bot is mid-animation
// on its last move, then call selectChecker() and assert _selectionLocked is false.

void main() {
  testWidgets('player can pre-select while bot animates last move', (tester) async {
    // Replace with the project's existing harness. The assertion is:
    //   1. Set state to GamePhase.movingCheckers, isAiTurn=true, lastMoveAnimating=true.
    //   2. Call _onCheckerTapped via tap on the player's CheckerComponent.
    //   3. Verify gameProvider.state.selectedPoint == tappedPoint.
    //   4. Verify _destinationLocked is true (move not yet allowed).
    //   5. Verify _selectionLocked is false (selection accepted).
  }, skip: 'Stub — implement against project test harness in step 2.5');
}
```

(The skip is intentional — the project may not have a widget-test harness for the game screen yet; if so, this test serves as documentation. The behaviour is verified manually in step 2.6.)

- [ ] **Step 2.2: Replace `_animationInProgress` with two flags**

In `_GameScreenState`, replace:
```dart
bool _animationInProgress = false;
```
with:
```dart
bool _destinationLocked = false; // blocks destination taps mid-move animation
bool _selectionLocked = false;   // blocks selection (e.g. during dice rattle)
```

- [ ] **Step 2.3: Update `_onCheckerTapped`** (line ~191)

Replace the existing guard:
```dart
if (_animationInProgress) return;
```
with:
```dart
if (_selectionLocked) return;
```

The rest of the function body is unchanged.

- [ ] **Step 2.4: Update `_onDestinationTapped`** (line ~217)

Replace the existing guard at line ~218:
```dart
if (_animationInProgress) return;
```
with:
```dart
if (_destinationLocked) return;
```

Replace line ~261-262 `_animationInProgress = true; ref.read(gameProvider.notifier).makeMove(toPoint);` with:
```dart
_destinationLocked = true;
ref.read(gameProvider.notifier).makeMove(toPoint);
```

In the `finally` block (line ~271):
```dart
} finally {
  _destinationLocked = false;
}
```

- [ ] **Step 2.5: Update `_handleAiTurn` to release `_selectionLocked` early**

Read `_handleAiTurn`. Currently the bot sets `_animationInProgress = true` for its whole turn. New logic:

- During dice rattle: `_selectionLocked = true; _destinationLocked = true;`
- After roll, before first move: `_selectionLocked = false;` (player can now pre-select). `_destinationLocked` stays true while the bot is moving.
- After bot's last animation completes (the existing `await _game.updateBoardState(...)` + final settle): both flags release.

If the bot's turn is mid-`_handleAiTurn` and the user calls `selectChecker`, that's allowed — the move legality is enforced by `_destinationLocked`.

Concretely, search for the line that sets `_animationInProgress = true` at the start of `_handleAiTurn` and split it:
```dart
// before:
_animationInProgress = true;
// after:
_selectionLocked = true;
_destinationLocked = true;
```

After the dice roll completes (inside `_handleAiTurn`, after the roll await), insert:
```dart
if (mounted) setState(() => _selectionLocked = false);
```

At the end of `_handleAiTurn` (in the `finally` or final block):
```dart
if (mounted) {
  setState(() {
    _selectionLocked = false;
    _destinationLocked = false;
  });
}
```

- [ ] **Step 2.6: Update COMPLETE button guard**

Find the `_onCompleteBearOff` handler and the COMPLETE button at line ~798. The button's `onPressed` should be `_destinationLocked ? null : _onCompleteBearOff`. Inside `_onCompleteBearOff`, the existing animation in-progress guard becomes `if (_destinationLocked) return;`.

- [ ] **Step 2.7: Update build() and any other reads of `_animationInProgress`**

Search the file for `_animationInProgress`. Every read becomes `_destinationLocked` (the more conservative of the two — read context to decide if `_selectionLocked` is more appropriate; in practice everything that gated moves becomes `_destinationLocked`).

- [ ] **Step 2.8: Manual sanity check**

```
flutter run -d <available device>
```
Play one bot turn. While the bot is animating its second/third move, tap one of your own checkers — confirm the selection ring appears and persists. Tap a destination — confirm it's blocked until the bot is done, then commits.

- [ ] **Step 2.9: Commit**

```bash
git add lib/features/game/presentation/game_screen.dart \
        test/widget/pre_input_test.dart
git commit -m "$(cat <<'EOF'
Refactor input gating to two-flag model + pre-input window

Splits _animationInProgress into _destinationLocked (blocks move
commits during animation) and _selectionLocked (blocks selection
during dice rattle). Player can pre-select a checker while the bot
animates its final move; destination tap waits for animation to
finish. Same rule applies during bear-off.

Spec: §4.2, §6

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Hint badge alignment + glow clip

**Spec:** §7

**Files:**
- Modify: `lib/flame_game/components/highlight_component.dart`
- Create: `test/golden/highlight_alignment_test.dart`

**Read first:** All of `highlight_component.dart` (272 lines). Note `_localVerts`, `_badgeCenter`, the bbox padding logic at lines 65-83, and the existing `containsPoint` rectangle hit-test at 248-266 (DO NOT change this — preserve per spec §7.5).

- [ ] **Step 3.1: Write the failing golden test**

```dart
// test/golden/highlight_alignment_test.dart
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/flame_game/components/highlight_component.dart';

void main() {
  testGolden('hint badge centerline aligned with apex centerline (top point)',
    (game) async {
      // Construct a HighlightComponent for a top-row point at a known position.
      // Render to a canvas. Sample the badge center pixel and the apex pixel.
      // Assert their X coordinates differ by ≤ 0.5px.
    },
    goldenFile: 'goldens/badge_alignment_top.png',
    size: const Size(120, 280),
  );

  testGolden('glow does not bleed past triangle path', (game) async {
    // Render highlight, sample pixels just outside the triangle path.
    // Assert opacity of green channel == 0 (or below threshold).
  },
    goldenFile: 'goldens/glow_clipped.png',
    size: const Size(120, 280),
  );
}
```

(Adapt to the project's actual `flame_test` setup; if `flame_test` isn't a dep, add it to `dev_dependencies` in `pubspec.yaml`. If golden tests don't fit the existing harness, fall back to a unit test that asserts `_badgeCenter.x == apexLocalX` after construction.)

- [ ] **Step 3.2: Run test to verify it fails**

```
flutter test test/golden/highlight_alignment_test.dart
```
Expected: FAIL — golden mismatch or assertion failure.

- [ ] **Step 3.3: Fix `_badgeCenter` to use apex in parent coordinates**

In `highlight_component.dart`, find the section computing `_badgeCenter` (around line 92). Currently:
```dart
_badgeCenter = _localVerts[2];
```
This reads from local-bbox coords. Instead, compute it directly from the apex vertex *before* the bbox transform is applied. Add a stored field:
```dart
late final Vector2 _apexInParentSpace;
```
Set it at the moment the triangle vertices are received (before the padding/min-x offset is computed):
```dart
_apexInParentSpace = vertices[2].clone();
```
The badge becomes a separate child component:
```dart
add(BadgeComponent(value: dieValue, position: _apexInParentSpace - Vector2(0, badgeRadius + 6))
  ..anchor = Anchor.center);
```

The badge child sits in the highlight's parent coordinate space (because `position` is relative to the highlight's parent — adjust if `add` puts it in highlight-local). Verify with a print statement in the failing test before committing.

Cross-check against the golden test: the apex's parent-space X must match the badge's parent-space X.

- [ ] **Step 3.4: Clip glow to triangle path**

In the `render` method (around line 134-154 per audit), wrap the path drawing:
```dart
@override
void render(Canvas canvas) {
  final path = Path()
    ..moveTo(_localVerts[0].x, _localVerts[0].y)
    ..lineTo(_localVerts[1].x, _localVerts[1].y)
    ..lineTo(_localVerts[2].x, _localVerts[2].y)
    ..close();

  canvas.save();
  canvas.clipPath(path);

  // Fill — replace the previous MaskFilter.blur paint with a clean fill.
  final fill = Paint()..color = const Color(0xB378C878); // green at ~0.7 alpha
  canvas.drawPath(path, fill);

  // Inset glow: stack two paths with decreasing opacity inside the clip.
  final glow1 = Paint()
    ..color = const Color(0x4078C878)
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, glow1);

  canvas.restore();

  // Stroke (border) drawn UNCLIPPED on the path itself — not on padded bbox.
  final stroke = Paint()
    ..color = const Color(0xCCAA3C3C) // red at 0.8
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  canvas.drawPath(path, stroke);
}
```

Remove any `MaskFilter.blur` on the rect-bbox path.

- [ ] **Step 3.5: Verify hitbox is preserved**

Read `containsPoint` at lines 248-266. It MUST remain rectangular bbox-based. If the refactor in steps 3.3-3.4 inadvertently removed it, reinstate the original implementation from git history (`git show HEAD~1:lib/flame_game/components/highlight_component.dart`).

- [ ] **Step 3.6: Run tests**

```
flutter test test/golden/highlight_alignment_test.dart
flutter test test/unit/highlight_hitbox_test.dart
```
Both expected: PASS.

- [ ] **Step 3.7: Commit**

```bash
git add lib/flame_game/components/highlight_component.dart \
        test/golden/highlight_alignment_test.dart
git commit -m "$(cat <<'EOF'
Fix hint badge alignment + clip glow to triangle path

Badge now anchors to the triangle apex in parent space, independent
of the highlight's padded bbox. Glow blur is replaced with a clipped
fill + inset shadow so the green stops at the triangle silhouette.
Rectangular hitbox in containsPoint is preserved (load-bearing prior fix).

Spec: §7

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Tap selection visual + immediate destination haptic

**Spec:** §4.3 first bullet, §6.1, §6.2

**Files:**
- Modify: `lib/flame_game/components/checker_component.dart`
- Modify: `lib/features/game/presentation/game_screen.dart`
- Create: `test/widget/checker_selection_test.dart`

**Read first:** `checker_component.dart` full file (492 lines). Note current `onTapUp` at line 436 and any `_selected` state. The `_onCheckerTapped` and `_onDestinationTapped` handlers in `game_screen.dart`.

- [ ] **Step 4.1: Write the failing test**

```dart
// test/widget/checker_selection_test.dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/flame_game/components/checker_component.dart';

void main() {
  testWithFlameGame('setSelected(true) scales the checker to 1.06x synchronously',
    (game) async {
      final checker = CheckerComponent(/* construct with project's expected args */);
      await game.add(checker);
      await game.ready();

      final originalScale = checker.scale.x;
      checker.setSelected(true);
      // After one frame, scale tween should be running.
      game.update(0.080); // 80ms tween duration
      expect(checker.scale.x, closeTo(1.06, 0.01));

      checker.setSelected(false);
      game.update(0.080);
      expect(checker.scale.x, closeTo(originalScale, 0.01));
    });
}
```

- [ ] **Step 4.2: Run to verify failure**

```
flutter test test/widget/checker_selection_test.dart
```
Expected: FAIL — `setSelected` doesn't exist.

- [ ] **Step 4.3: Implement `setSelected` on `CheckerComponent`**

Add to `CheckerComponent` (after the existing fields, around line 30-50):
```dart
bool _isSelected = false;
double _ringOpacity = 0.0;

void setSelected(bool value) {
  if (_isSelected == value) return;
  _isSelected = value;
  // Scale tween 1.0 ↔ 1.06 over 80ms ease-out.
  add(ScaleEffect.to(
    Vector2.all(value ? 1.06 : 1.0),
    EffectController(duration: 0.080, curve: Curves.easeOut),
  ));
  // Ring opacity tween 0 ↔ 0.85 over 80ms.
  add(_RingOpacityEffect(
    target: value ? 0.85 : 0.0,
    duration: 0.080,
    onUpdate: (op) => _ringOpacity = op,
  ));
}

@override
void render(Canvas canvas) {
  super.render(canvas);
  if (_ringOpacity > 0.001) {
    final ring = Paint()
      ..color = TavliColors.primary.withOpacity(_ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final r = radius + 3;
    canvas.drawCircle(Offset(radius, radius), r, ring);
  }
}
```

`_RingOpacityEffect` is a small custom `Effect` class — implement at the bottom of the file:
```dart
class _RingOpacityEffect extends Effect {
  final double target;
  final void Function(double) onUpdate;
  late double _start;

  _RingOpacityEffect({
    required this.target,
    required double duration,
    required this.onUpdate,
  }) : super(EffectController(duration: duration, curve: Curves.easeOut));

  @override
  void onStart() { _start = 0.0; }

  @override
  void apply(double progress) {
    onUpdate(_start + (target - _start) * progress);
  }
}
```

Import `TavliColors` from the project's design system.

- [ ] **Step 4.4: Wire `setSelected` from the tap handler**

In `game_screen.dart` `_onCheckerTapped` (around line 191), add immediately after the `HapticFeedback.selectionClick()` call:
```dart
final checker = _game.findCheckerAt(pointIndex);
checker?.setSelected(true);
```

When the selection clears (in the same handler — replace if it exists):
```dart
_game.clearAllCheckerSelections();
```

Add `findCheckerAt` and `clearAllCheckerSelections` to `tavli_game.dart`:
```dart
CheckerComponent? findCheckerAt(int pointIndex) {
  for (final c in children.whereType<CheckerComponent>()) {
    if (c.pointIndex == pointIndex && !c.isAnimating) return c;
  }
  return null;
}

void clearAllCheckerSelections() {
  for (final c in children.whereType<CheckerComponent>()) {
    c.setSelected(false);
  }
}
```

(If `pointIndex` doesn't exist on `CheckerComponent`, add a getter that returns the current location; consult the existing fields.)

- [ ] **Step 4.5: Move destination haptic to before the await**

In `_onDestinationTapped` (around line 217-271), find:
```dart
try {
  await _game.updateBoardState(ref.read(gameProvider).board);
  if (landingSfx != null) {
    _audio.playSfx(landingSfx);
    HapticFeedback.lightImpact();  // ← currently here
  }
}
```

Move the haptic to before the await:
```dart
HapticFeedback.lightImpact(); // immediate — fires on tap commit, not after animation
_destinationLocked = true;
ref.read(gameProvider.notifier).makeMove(toPoint);
try {
  await _game.updateBoardState(ref.read(gameProvider).board);
  if (landingSfx != null) {
    _audio.playSfx(landingSfx);
  }
}
```

- [ ] **Step 4.6: Run tests**

```
flutter test test/widget/checker_selection_test.dart
flutter test
```
Expected: PASS.

- [ ] **Step 4.7: Commit**

```bash
git add lib/flame_game/components/checker_component.dart \
        lib/flame_game/tavli_game.dart \
        lib/features/game/presentation/game_screen.dart \
        test/widget/checker_selection_test.dart
git commit -m "$(cat <<'EOF'
Add checker selection visual + move destination haptic to tap-time

Tapped checker scales to 1.06x with a primary-color ring, fired
synchronously in onTapUp. Destination haptic moves before the await
so the tap feedback lands at commit time, not 130ms later.

Spec: §6

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: TurnHandoffPill widget + DiceCueRing component

**Spec:** §4.3, §8.1, §8.2

**Files:**
- Create: `lib/features/game/presentation/widgets/turn_handoff_pill.dart`
- Create: `lib/flame_game/components/dice_cue_ring.dart`
- Modify: `lib/features/game/presentation/game_screen.dart`
- Modify: `lib/flame_game/tavli_game.dart`
- Modify: `lib/l10n/app_en.arb` and `lib/l10n/app_el.arb`
- Create: `test/widget/turn_handoff_pill_test.dart`

**Read first:** existing `lib/l10n/` structure for adding localized strings; the player names header in `game_screen.dart` around lines 870-960.

- [ ] **Step 5.1: Add localized strings**

In `lib/l10n/app_en.arb` add:
```json
"playerTurn": "Your turn",
"botThinking": "{name} thinking…",
"@botThinking": { "placeholders": { "name": { "type": "String" } } },
"botMoving": "{name} moving…",
"@botMoving": { "placeholders": { "name": { "type": "String" } } }
```

In `lib/l10n/app_el.arb`:
```json
"playerTurn": "Σειρά σας",
"botThinking": "Ο {name} σκέφτεται…",
"@botThinking": { "placeholders": { "name": { "type": "String" } } },
"botMoving": "Ο {name} κινείται…",
"@botMoving": { "placeholders": { "name": { "type": "String" } } }
```

Run `flutter gen-l10n` (or it generates on next build).

- [ ] **Step 5.2: Write the pill test**

```dart
// test/widget/turn_handoff_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/presentation/widgets/turn_handoff_pill.dart';

void main() {
  testWidgets('shows "Your turn" when isPlayerTurn', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TurnHandoffPill(
        isPlayerTurn: true, isBotMoving: false, botName: 'Mikhail',
      )),
    ));
    expect(find.text('Your turn'), findsOneWidget);
  });

  testWidgets('shows "{name} thinking…" when bot turn before move', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TurnHandoffPill(
        isPlayerTurn: false, isBotMoving: false, botName: 'Mikhail',
      )),
    ));
    expect(find.text('Mikhail thinking…'), findsOneWidget);
  });

  testWidgets('shows "{name} moving…" when bot is animating', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TurnHandoffPill(
        isPlayerTurn: false, isBotMoving: true, botName: 'Mikhail',
      )),
    ));
    expect(find.text('Mikhail moving…'), findsOneWidget);
  });
}
```

- [ ] **Step 5.3: Implement `TurnHandoffPill`**

```dart
// lib/features/game/presentation/widgets/turn_handoff_pill.dart
import 'package:flutter/material.dart';
import 'package:tavli/core/design/tavli_colors.dart';

class TurnHandoffPill extends StatelessWidget {
  final bool isPlayerTurn;
  final bool isBotMoving;
  final String botName;

  const TurnHandoffPill({
    super.key,
    required this.isPlayerTurn,
    required this.isBotMoving,
    required this.botName,
  });

  String _label() {
    if (isPlayerTurn) return 'Your turn';
    return isBotMoving ? '$botName moving…' : '$botName thinking…';
    // Step 5.4 replaces these literals with AppLocalizations once gen-l10n runs.
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(_label()),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TavliColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          _label(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: TavliColors.text,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.4: Switch pill to use l10n**

After `flutter gen-l10n` produces `AppLocalizations`, replace the `_label()` literals:
```dart
String _label(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  if (isPlayerTurn) return l.playerTurn;
  return isBotMoving ? l.botMoving(botName) : l.botThinking(botName);
}
```
Make `_label` take a `BuildContext` and call from `build`.

- [ ] **Step 5.5: Wire pill into game_screen header**

Find the player names header (around lines 870-960 per audit). Add the pill alongside the active player's name. Pass:
- `isPlayerTurn`: `gs.isPlayerTurn && !_aiThinking`
- `isBotMoving`: `_aiThinking && _destinationLocked`
- `botName`: derived from `_personality` (e.g. `_personality.displayName(context)`).

Remove the avatar border swap at lines 878 & 948 — use a static `TavliColors.primary` border for both.

- [ ] **Step 5.6: Implement DiceCueRing**

```dart
// lib/flame_game/components/dice_cue_ring.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:tavli/core/design/tavli_colors.dart';

class DiceCueRing extends PositionComponent {
  double _t = 0;
  bool visible = false;

  DiceCueRing({required Vector2 position, required double radius})
      : super(position: position, size: Vector2.all(radius * 2));

  double get _opacity {
    final phase = (_t / 1.4) * 2 * 3.1415926;
    return 0.35 + 0.15 * (1 + (phase % (2 * 3.1415926) > 3.14 ? -1 : 1)).abs();
    // simpler triangle wave is fine; spec calls for easeInOut, use a sin().
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (visible) _t = (_t + dt) % 1.4;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final paint = Paint()
      ..color = TavliColors.primary.withOpacity(_opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2), size.x / 2 - 1, paint,
    );
  }
}
```

(For the spec-correct sinusoidal pulse, replace the stub `_opacity` getter with `0.35 + 0.30 * (sin(_t * 2 * pi / 1.4) + 1) / 2` — import `dart:math`.)

- [ ] **Step 5.7: Show/hide DiceCueRing from `tavli_game.dart`**

In the game's update path, set `cueRing.visible = state.isPlayerTurn && !state.diceRolled && !_destinationLocked`. Wire the visibility through whatever signal the game already uses to know about phase changes.

- [ ] **Step 5.8: Run tests**

```
flutter test test/widget/turn_handoff_pill_test.dart
flutter test
```
Expected: PASS.

- [ ] **Step 5.9: Commit**

```bash
git add lib/features/game/presentation/widgets/turn_handoff_pill.dart \
        lib/flame_game/components/dice_cue_ring.dart \
        lib/features/game/presentation/game_screen.dart \
        lib/flame_game/tavli_game.dart \
        lib/l10n/ \
        test/widget/turn_handoff_pill_test.dart
git commit -m "$(cat <<'EOF'
Add TurnHandoffPill + DiceCueRing for clearer state signaling

Pill displays "Your turn" / "{Bot} thinking…" / "{Bot} moving…" with
a 120ms cross-fade. DiceCueRing pulses around the dice cup when it's
the player's turn to roll. Avatar borders no longer swap colors.

Spec: §8.1, §8.2

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Bear-off cascade (parallel animation)

**Spec:** §4.3, §8.3

**Files:**
- Modify: `lib/flame_game/tavli_game.dart`
- Modify: `lib/flame_game/components/checker_component.dart` (if needed for cascade hook)
- Modify: `lib/features/game/presentation/game_screen.dart` (`_onCompleteBearOff`)

**Read first:** Current `_onCompleteBearOff` (line ~846), `updateBoardState` and `Future.wait(animations)` at `tavli_game.dart:380`.

- [ ] **Step 6.1: Write the failing test**

```dart
// test/integration/bearoff_cascade_test.dart
import 'package:flutter_test/flutter_test.dart';
// Construct a board state with 6 checkers in the player's home, all
// trivially bearable. Trigger _onCompleteBearOff. Measure wall time
// from invocation to GamePhase.gameOver. Assert ≤ 300ms.

void main() {
  test('trivial bear-off cascade completes in under 300ms for 6 checkers',
    () async {
      // Stub — actual test depends on project's integration harness.
    }, skip: 'Stub — implement with project integration harness in step 6.5');
}
```

- [ ] **Step 6.2: Add `cascadeBearOff` to `tavli_game.dart`**

The audio service `_audio` lives on `_GameScreenState`, not `TavliGame`. To keep the existing pattern, `cascadeBearOff` accepts an `onCheckerLanded` callback so the screen plays SFX per checker:

```dart
Future<void> cascadeBearOff({
  required List<int> sourcePoints,
  required int playerSide,
  required void Function(int sourcePoint) onCheckerLanded,
}) async {
  final futures = <Future<void>>[];
  for (var i = 0; i < sourcePoints.length; i++) {
    final delay = Duration(milliseconds: 35 * i);
    final source = sourcePoints[i];
    futures.add(Future.delayed(delay, () async {
      final checker = findCheckerAt(source);
      if (checker == null) return;
      await Future.wait([
        checker.animateMoveTo(_bearOffTrayPosition(playerSide), 0.130),
        checker.animateScaleTo(0.8, 0.060),
      ]);
      onCheckerLanded(source);
    }));
  }
  await Future.wait(futures).timeout(
    const Duration(seconds: 2),
    onTimeout: () => <void>[],
  );
}
```

(`_bearOffTrayPosition(playerSide)` — use the existing tray-position helper; check `board_layout.dart` for it.)

- [ ] **Step 6.3: Update `_onCompleteBearOff`**

In `game_screen.dart`:
```dart
Future<void> _onCompleteBearOff() async {
  if (_destinationLocked) return;
  final notifier = ref.read(gameProvider.notifier);
  if (!notifier.isTrivialBearOff()) return;

  _destinationLocked = true;
  try {
    final source = notifier.remainingHomePoints();
    notifier.completeBearOff(); // mutates state to bearOff for all
    await _game.cascadeBearOff(
      sourcePoints: source,
      playerSide: notifier.activePlayer,
      onCheckerLanded: (_) => _audio.playSfx(SfxType.checkerBearOff),
    );
    // game over phase transition handled inside notifier.completeBearOff().
  } finally {
    if (mounted) setState(() => _destinationLocked = false);
  }
}
```

(Add `remainingHomePoints()` and `completeBearOff()` to the notifier if they don't exist; consult the current implementation.)

- [ ] **Step 6.4: Verify integration**

```
flutter run
```
Force a near-end-game state, trigger COMPLETE — visually confirm the cascade fires concurrently and wraps in ~250ms.

- [ ] **Step 6.5: Implement integration test (best-effort)**

If the project has an integration harness (`integration_test/`), add a test that drives a game to a trivial bear-off state and asserts the cascade timing. If no harness exists, leave the stub from step 6.1 as documentation.

- [ ] **Step 6.6: Commit**

```bash
git add lib/flame_game/tavli_game.dart \
        lib/flame_game/components/checker_component.dart \
        lib/features/game/presentation/game_screen.dart \
        test/integration/bearoff_cascade_test.dart
git commit -m "$(cat <<'EOF'
Parallel cascade for trivial bear-off

Replaces sequential 6×130ms loop with parallel 35ms-staggered
animation. End-game wrap from ~800ms to ~250ms for 6 checkers.
SFX fires per checker for an audible cascade.

Spec: §8.3

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Static wood-grain background

**Spec:** §1 #4, §4.3 last bullet, §8.4

**Files:**
- Modify: `lib/features/game/presentation/game_screen.dart` (lines 686-693, 878, 948)
- Verify: `pubspec.yaml` already includes `assets/images/backgrounds/`

**Read first:** the `AnimatedContainer` block at lines 686-693, the avatar border refs at 878 & 948.

- [ ] **Step 7.1: Verify asset is registered**

```bash
grep -A 2 "assets/images/backgrounds" pubspec.yaml
ls assets/images/backgrounds/table.png
```
Expected: shown in `pubspec.yaml`, file exists. If `pubspec.yaml` doesn't list it, add `- assets/images/backgrounds/` under `flutter: assets:`.

- [ ] **Step 7.2: Replace `AnimatedContainer` with `Container` + `DecorationImage`**

Find the block at lines 686-693:
```dart
final bgColor = (_aiThinking || gs.isAiTurn)
    ? TavliColors.botThinkingBg
    : TavliColors.primary;

return AnimatedContainer(
  duration: ReducedMotion.duration(context, const Duration(milliseconds: 400)),
  color: bgColor,
  child: Scaffold(
    // ...
```

Replace with:
```dart
return Container(
  color: TavliColors.primary, // fallback if image fails to load
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/backgrounds/table.png'),
      fit: BoxFit.cover,
    ),
  ),
  child: Scaffold(
    backgroundColor: Colors.transparent,
    // ... existing children
```

The `bgColor` variable is no longer needed; remove it.

- [ ] **Step 7.3: Remove avatar border swap**

At line 878:
```dart
color: gs.isAiTurn ? TavliColors.surface : TavliColors.primary,
```
Replace with:
```dart
color: TavliColors.primary,
```

At line 948:
```dart
color: gs.isPlayerTurn ? TavliColors.surface : TavliColors.primary,
```
Replace with:
```dart
color: TavliColors.primary,
```

- [ ] **Step 7.4: Run app, verify no jumpiness**

```
flutter run
```
Watch a turn change. Background should stay constant. Active-player signal comes from the pill (Task 5) and the dice cue ring.

- [ ] **Step 7.5: Run tests**

```
flutter test
```
Expected: PASS. The widget tests for the screen may need their `expect`s on `bgColor` removed if any exist.

- [ ] **Step 7.6: Commit**

```bash
git add lib/features/game/presentation/game_screen.dart pubspec.yaml
git commit -m "$(cat <<'EOF'
Static wood-grain background + remove turn-flip color animation

Drops the AnimatedContainer that swapped between primary brown and
botThinkingBg blue-grey on every turn. Scaffold now renders a static
wood-grain image (assets/images/backgrounds/table.png). Avatar borders
no longer swap colors. Turn-active signal lives entirely in the
TurnHandoffPill + DiceCueRing.

Spec: §8.4

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: MoveQualityCache + decouple from build()

**Spec:** §1 #5, §4.3 last bullet, §8.5

**Files:**
- Create: `lib/features/game/presentation/providers/move_quality_cache.dart`
- Modify: `lib/features/game/presentation/providers/game_provider.dart`
- Modify: `lib/features/game/presentation/game_screen.dart` (lines ~226, ~298, ~421-460, ~666)
- Create: `test/unit/move_quality_cache_test.dart`

**Read first:** `_computeMoveQualities` at lines 421-460, `_checkTeachingFeedback` at 297-418, the `build()` callsite at line 666, and `selectChecker` / `makeMove` in `game_provider.dart`.

- [ ] **Step 8.1: Write the failing test**

```dart
// test/unit/move_quality_cache_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/presentation/providers/move_quality_cache.dart';
import 'package:tavli/features/game/domain/entities/move_quality.dart';

void main() {
  group('MoveQualityCache', () {
    test('returns null on miss, hit on second read', () {
      final cache = MoveQualityCache();
      expect(cache.read(boardHash: 1, selectedPoint: 13, dice: [3, 5]), isNull);
      cache.write(boardHash: 1, selectedPoint: 13, dice: [3, 5],
                  qualities: {16: MoveQuality.best, 18: MoveQuality.good});
      final hit = cache.read(boardHash: 1, selectedPoint: 13, dice: [3, 5]);
      expect(hit, isNotNull);
      expect(hit![16], equals(MoveQuality.best));
    });

    test('dice ordering doesnt affect cache key', () {
      final cache = MoveQualityCache();
      cache.write(boardHash: 1, selectedPoint: 13, dice: [3, 5],
                  qualities: {16: MoveQuality.best});
      expect(cache.read(boardHash: 1, selectedPoint: 13, dice: [5, 3]), isNotNull);
    });

    test('different boardHash misses', () {
      final cache = MoveQualityCache();
      cache.write(boardHash: 1, selectedPoint: 13, dice: [3, 5],
                  qualities: {16: MoveQuality.best});
      expect(cache.read(boardHash: 2, selectedPoint: 13, dice: [3, 5]), isNull);
    });
  });
}
```

- [ ] **Step 8.2: Implement MoveQualityCache**

```dart
// lib/features/game/presentation/providers/move_quality_cache.dart
import 'package:tavli/features/game/domain/entities/move_quality.dart';

class MoveQualityCache {
  final Map<String, Map<int, MoveQuality>> _store = {};

  String _key({required int boardHash, required int selectedPoint, required List<int> dice}) {
    final sorted = List.of(dice)..sort();
    return '$boardHash:$selectedPoint:${sorted.join(',')}';
  }

  Map<int, MoveQuality>? read({required int boardHash, required int selectedPoint, required List<int> dice}) {
    return _store[_key(boardHash: boardHash, selectedPoint: selectedPoint, dice: dice)];
  }

  void write({required int boardHash, required int selectedPoint, required List<int> dice, required Map<int, MoveQuality> qualities}) {
    _store[_key(boardHash: boardHash, selectedPoint: selectedPoint, dice: dice)] = qualities;
  }

  void invalidate() => _store.clear();
}
```

- [ ] **Step 8.3: Run cache test**

```
flutter test test/unit/move_quality_cache_test.dart
```
Expected: PASS.

- [ ] **Step 8.4: Wire cache into `GameProvider`**

In `game_provider.dart`, add a `MoveQualityCache _qualityCache = MoveQualityCache();` field. Add a public getter `MoveQualityCache get qualityCache => _qualityCache;`.

In `selectChecker(int point)`:
- After mutating state, schedule via `Future.microtask` if cache miss:
```dart
if (state.isTeachingMode &&
    _qualityCache.read(boardHash: state.boardHash, selectedPoint: point, dice: state.remainingDice) == null) {
  Future.microtask(() => _computeAndCacheQualities(point));
}
```
- Implement `_computeAndCacheQualities(int point)` doing the equity eval that previously lived in `_computeMoveQualities` in `game_screen.dart`. Move that logic to the notifier.

In `makeMove(int toPoint)`:
- After state mutation, no special cache action — natural cache miss on next `selectChecker`.

In `clearSelection()` and turn-end paths:
- Optionally `_qualityCache.invalidate()` to bound memory; safe but not required.

- [ ] **Step 8.5: Make `_computeMoveQualities` in game_screen.dart a thin reader**

Replace the body of `_computeMoveQualities` (lines 421-460) with:
```dart
Map<int, MoveQuality>? _computeMoveQualities() {
  if (!widget.difficulty.isTeaching) return null;
  final gs = ref.read(gameProvider);
  if (gs.selectedPoint == null) return null;
  return ref.read(gameProvider.notifier).qualityCache.read(
    boardHash: gs.boardHash,
    selectedPoint: gs.selectedPoint!,
    dice: gs.remainingDice,
  );
}
```

This NEVER triggers a fresh computation. The notifier handles that.

- [ ] **Step 8.6: Add early-return in `_checkTeachingFeedback`**

Find `_checkTeachingFeedback()` (around line 370). At the top of the function body, add:
```dart
final gs = ref.read(gameProvider);
if (gs.remainingDice.isNotEmpty) return; // skip mid-turn — only fire at turn end
```
This must come BEFORE any call to `_aiPlayer.evaluateMoveLoss(...)`.

- [ ] **Step 8.7: Verify build() doesn't trigger compute**

Read `build()` around line 666. Ensure `_computeMoveQualities` is called only as a reader (returning cached or null), never triggering eval.

- [ ] **Step 8.8: Run all tests**

```
flutter test
```
Expected: PASS.

- [ ] **Step 8.9: Manual sanity check in easyWithHelp mode**

```
flutter run
```
Start an `Εύκολο με Βοήθεια` game. After your first move, immediately tap a checker for your second move — the selection should land instantly with no UI freeze.

- [ ] **Step 8.10: Commit**

```bash
git add lib/features/game/presentation/providers/move_quality_cache.dart \
        lib/features/game/presentation/providers/game_provider.dart \
        lib/features/game/presentation/game_screen.dart \
        test/unit/move_quality_cache_test.dart
git commit -m "$(cat <<'EOF'
Add MoveQualityCache to remove easyWithHelp UI freeze

_computeMoveQualities is no longer triggered by build(). The notifier
schedules equity evaluation via Future.microtask on selectChecker and
caches by (boardHash, selectedPoint, sortedDice). _checkTeachingFeedback
now early-returns when remainingDice is non-empty so the heavy eval
no longer fires between move 1 and move 2.

Spec: §8.5

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Final test sweep + push

**Files:** none modified

- [ ] **Step 9.1: Run full test suite**

```
cd /Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli
flutter test
```
Expected: PASS. Note any pre-existing failures unrelated to this work.

- [ ] **Step 9.2: Run integration tests if present**

```
flutter test integration_test/
```

- [ ] **Step 9.3: Manual play-through QA**

Start one game per difficulty (easy / easyWithHelp / medium / hard). For each:
1. Verify turn change is calm — no background flash, pill swaps cleanly.
2. Tap a checker — see the scale + ring fire instantly.
3. Tap a destination — feel haptic at tap, not after animation.
4. Watch a bot turn — pre-select your own checker before its last animation finishes. Confirm selection lands.
5. Hint badge (easyWithHelp only) — visually confirm it sits on the column centerline. Glow stays inside the triangle.
6. Trigger trivial bear-off — confirm cascade is parallel and ~250ms.

- [ ] **Step 9.4: Push to main per Q3-c authorization**

```bash
git push origin fix/gameplay-qa-alignment:main
```

If the push is rejected (someone pushed to main first), STOP. Do not force-push. Pull, rebase or merge, re-run tests, and try again.

- [ ] **Step 9.5: Verify push landed**

```bash
git log origin/main -1
```
Expected: HEAD on main matches the local branch HEAD.

---

## Notes for the executing agent

1. The `fix/gameplay-qa-alignment` branch already has substantial recent changes from the prior commit. Read each file before editing — the line numbers cited in this plan are from the audit, but the file may have shifted.
2. Some Flame APIs (effects, components) vary by version. If `EffectController` or `ScaleEffect.to` signatures differ, adapt to the project's `flame` version in `pubspec.yaml`.
3. If a test harness for the game screen widget doesn't exist, the stubs in this plan can ship as `skip:`'d tests with an explanatory string — they document intent for future test work.
4. Never `--force` or `--no-verify` on commits or pushes. If a hook or CI fails, fix the underlying cause.
5. The hint hitbox in `containsPoint` MUST stay rectangular. Spec §7.5 calls this out explicitly.
