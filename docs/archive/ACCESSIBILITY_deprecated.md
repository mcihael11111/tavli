> **DEPRECATED** — This document has been superseded by [`design/05_ACCESSIBILITY.md`](design/05_ACCESSIBILITY.md).

# Tavli Accessibility Standards (Deprecated)

## Overview

Tavli follows WCAG 2.1 AA as a minimum standard, with AAA targets for critical gameplay elements. The app must be usable by players with visual, motor, auditory, and cognitive accessibility needs.

---

## Color Contrast Requirements

### Minimum Ratios (WCAG 2.1)

| Element | Minimum Ratio | Target | Standard |
|---------|--------------|--------|----------|
| Body text (16sp+) | 4.5:1 | 7:1 | AA / AAA |
| Large text (18sp+ bold, 24sp+) | 3:1 | 4.5:1 | AA / AAA |
| Interactive elements | 3:1 | 4.5:1 | AA |
| Icons (informational) | 3:1 | — | AA |
| Decorative elements | None | — | — |

### Tavli-Specific Contrast Ratios

| Combination | Ratio | Grade |
|------------|-------|-------|
| `kafeneioBrown` on `marbleWhite` | **8.8:1** | AAA |
| `kafeneioBrown` on `parchment` | **7.4:1** | AAA |
| `parchment` on `kafeneioBrown` | **8.2:1** | AAA |
| `oliveGold` on `kafeneioBrown` | **4.6:1** | AA |
| `kafeneioBrown` on `oliveGold` | **4.6:1** | AA |
| `brightText` on `nightWood` | **12.5:1** | AAA |
| `dimText` on `nightWood` | **7.8:1** | AAA |

### Opacity Rules

To maintain contrast, text opacity must not drop below these thresholds:

| Background | Text Color | Minimum Alpha |
|-----------|-----------|---------------|
| `marbleWhite` / `parchment` | `kafeneioBrown` | 0.70 |
| `kafeneioBrown` (dark bg) | `parchment` | 0.80 |
| `nightWood` | `brightText` | 0.80 |
| `nightWood` | `dimText` | 1.0 (no reduction) |

**Rule: Never use alpha below 0.7 on text that conveys information.** Decorative text (e.g., watermarks) may use lower values.

---

## Touch Targets

### Minimum Sizes

| Element | Minimum Size | Target Size |
|---------|-------------|-------------|
| Buttons | 48dp × 48dp | 48dp × 48dp |
| Checkers (tap targets) | 48dp × 48dp | Scaled to board |
| Menu items | 48dp height | 56dp height |
| Icons (tappable) | 48dp × 48dp | 48dp × 48dp |
| Slider thumb | 48dp × 48dp | 48dp × 48dp |

### Spacing Between Targets

- Minimum 8dp gap between adjacent touch targets
- Board points: ensure touch area doesn't overlap with adjacent points

---

## Color-Independent Information

Move indicators MUST use **shape + color**, never color alone:

| Move Quality | Color | Shape | Additional |
|-------------|-------|-------|-----------|
| Best move | Gold glow | Solid circle + die number | Pulsing animation |
| Good move | Silver glow | Solid circle + die number | Pulsing animation |
| Hit available | Terracotta | Circle with "×" marker | — |
| Blocked point | — | Dimmed, no highlight | — |
| Selected checker | Gold outline | Scale 1.08× + glow | Lifted shadow |

### Dice

- Die values are shown with **pip patterns** (dots), not just numbers
- Used dice are visually distinct: desaturated + slight transparency
- Both visual and structural (semantic) differentiation

---

## Screen Reader Support

### Semantic Labels

Every interactive element must have an accessible label:

```dart
Semantics(
  label: 'Roll dice',
  button: true,
  child: DiceWidget(),
)

Semantics(
  label: 'Your checker on point 8, tap to select',
  child: CheckerWidget(),
)

Semantics(
  label: 'Move to point 5 using die value 3',
  child: HighlightWidget(),
)
```

### Game State Announcements

Use `SemanticsService.announce()` for key events:
- "Your turn. Tap to roll dice."
- "You rolled 5 and 3."
- "Mikhail is thinking..."
- "Mikhail moved from point 13 to point 7."
- "Your checker was hit and sent to the bar."
- "Game over. You win by gammon!"

### Navigation Order

1. Game status (whose turn, score)
2. Board (point-by-point traversal)
3. Dice area
4. Action buttons (undo, menu)
5. Dialogue bar

---

## Keyboard & Focus Navigation

- Tab order follows visual layout (top → board → bottom)
- Enter/Space activates focused element
- Arrow keys navigate between board points
- Escape opens pause menu
- Focus indicators: 2dp `oliveGold` outline

---

## Motion & Animation

### Reduced Motion Support

When the system `reduceMotion` preference is enabled:
- Checker movement: instant teleport (no arc animation)
- Dice roll: show result immediately (no tumble)
- Screen transitions: instant cut (no slide/fade)
- Highlight pulse: static glow (no animation)
- Mikhail portrait: static (no idle animation)

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
final duration = reduceMotion ? Duration.zero : Duration(milliseconds: 350);
```

---

## Text Scaling

- All text must remain readable at 200% system font scale
- Layout must not break or clip at large text sizes
- Game board text (die values, pip counts) scales proportionally to board size
- Minimum font size for any visible text: 11sp (at 100% scale)

---

## Audio Accessibility

- All game information conveyed by audio must also be conveyed visually
- Sound effects supplement visual feedback, never replace it
- Mikhail's voice lines are also displayed as text in the dialogue bar
- Background music and ambiance can be independently muted
- Volume controls for: Music, SFX, Voice (separate sliders)

---

## Testing Checklist

### Automated
- [ ] Run `flutter analyze` with no warnings
- [ ] Run accessibility scanner on all screens
- [ ] Verify all `Semantics` widgets have labels

### Manual
- [ ] Navigate entire app with TalkBack (Android) / VoiceOver (iOS)
- [ ] Complete a full game using screen reader only
- [ ] Verify all touch targets are ≥ 48dp
- [ ] Test with system font size at 200%
- [ ] Test with system "reduce motion" enabled
- [ ] Test with grayscale display filter (colorblind simulation)
- [ ] Verify all buttons are distinguishable without color (have labels/icons)
- [ ] Test with inverted colors
