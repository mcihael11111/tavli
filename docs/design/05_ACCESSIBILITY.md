# Accessibility — Universal Rules

> WCAG 2.1 Level AA (minimum) | Level AAA (target for critical elements)
> Per-component accessibility (contrast, touch targets, semantic labels, states) is inline in [02_COMPONENTS.md](02_COMPONENTS.md).
> Token values are in [00_TOKENS.md](00_TOKENS.md).

---

## 1. Color Contrast

### 1.1 WCAG Requirements

| Category | Minimum Ratio | Applies To |
|----------|---------------|------------|
| Normal text (< 18px regular, < 14px bold) | 4.5:1 (AA) | Body text, labels, placeholders |
| Large text (≥ 18px regular, ≥ 14px bold) | 3:1 (AA) | Headings, display, bold labels |
| UI components & graphical objects | 3:1 (AA) | Borders, icons, focus rings, controls |
| Enhanced (AAA) | 7:1 | Target for primary body text, critical game info |

### 1.2 Contrast Matrix

See [00_TOKENS.md § Contrast Reference](00_TOKENS.md#8-contrast-reference-quick-lookup) for safe and forbidden color combinations.

### 1.3 Opacity Rules

| Context | Minimum Opacity |
|---------|-----------------|
| Interactive text (buttons, links) | 100% |
| Body text | 100% |
| Placeholder text | 60% of `text` |
| Disabled elements | 38% (exempt from contrast per WCAG) |
| Decorative elements | Any |
| Borders (informational) | 100% |

---

## 2. Touch Targets

### 2.1 Minimum Sizes

| Element | Minimum | Recommended |
|---------|---------|-------------|
| Buttons | 48 × 48dp | 56 × 48dp |
| Icon buttons | 48 × 48dp | 48 × 48dp |
| List items | 48dp height | 56dp height |
| Chips/tags | 32dp height, 48dp touch | 36dp height |
| Navigation items | 48 × 48dp | 64 × 48dp |
| Slider thumb | 48 × 48dp touch | 28px visual |
| Game checkers | 48 × 48dp | Scale with board |
| Game dice | 48 × 48dp | 64 × 64dp |

### 2.2 Spacing

Adjacent touch targets: **≥ 8dp** spacing between edges.

---

## 3. Color-Independent Information

Color must never be the sole means of conveying information. Every color-coded element needs a secondary indicator:

| Information | Color | Secondary Indicator |
|-------------|-------|---------------------|
| Valid move | Green | Pulsing dot + shape outline |
| Invalid move | Red | X icon + haptic |
| Selected checker | Glow | Elevated shadow + scale 1.1× |
| Player turn | Color accent | Text label "Your turn" + icon |
| Error state | `error` | Error icon + text |
| Success state | `success` | Checkmark icon + text |
| Warning state | `warning` | Warning triangle + text |
| Dice value | Dot pattern | Semantic label with value |

---

## 4. Screen Reader Support

### 4.1 Semantic Label Rules

Labels describe **purpose**, not appearance:

| Element | Good | Bad |
|---------|------|-----|
| Dice button | "Roll dice" | "Dice button" |
| Settings icon | "Open settings" | "Gear icon" |
| Checker | "Your checker on point 12" | "Brown circle" |
| Undo | "Undo last move" | "Arrow" |
| Board point | "Point 8, 3 of your checkers" | "Triangle" |

### 4.2 Game State Announcements

Via `Semantics.liveRegion`:

| Event | Announcement |
|-------|-------------|
| Dice rolled | "You rolled {die1} and {die2}" |
| Move made | "Moved checker from point {from} to point {to}" |
| Hit | "Hit opponent's checker on point {point}" |
| Bear off | "Bore off checker from point {point}" |
| Turn change | "Opponent's turn" / "Your turn" |
| Double offered | "Opponent offers double. Cube would be {value}" |
| Game over | "{Winner} wins by {type}. Score: {points}" |

### 4.3 Navigation Order

1. App bar / screen title
2. Primary content (top to bottom)
3. Action buttons (left to right)
4. Bottom navigation

---

## 5. Keyboard & Focus

### 5.1 Focus Indicator

See [03_STATES.md § Focus Ring](03_STATES.md#4-focus-ring-specification) — 2px `primary`, 2px offset, matches element shape.

### 5.2 Focus Order

Tab order matches visual reading order (top-to-bottom, LTR). Use `FocusTraversalGroup`.

### 5.3 Game Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space / Enter | Confirm / roll dice |
| Escape | Cancel / deselect |
| Arrow keys | Navigate board points |
| Tab | Move focus between UI |
| U | Undo last move |
| D | Offer double |

---

## 6. Motion & Animation

### 6.1 Reduced Motion

When `MediaQuery.disableAnimations` is `true`:

| Animation | Reduced Motion |
|-----------|---------------|
| Page transitions | Instant cut |
| Checker movement | Instant reposition |
| Dice roll | Static result |
| Card hover/press | Instant state change |
| Loading shimmer | Static placeholder |
| Victory celebration | Static badge |

### 6.2 Constraints

- Max duration: 1000ms
- No flashing < 3 flashes/second (WCAG 2.3.1)
- No auto-play loops (WCAG 2.2.2)
- Essential motion only (game moves, dice); decorative optional

---

## 7. Text Scaling

| Scale Factor | Requirement |
|-------------|-------------|
| 100% | Fully functional |
| 150% | No clipping |
| 200% | All text readable, layouts may reflow |
| > 200% | Best effort, no crashes |

Rules:
- Never use fixed heights on text containers
- Use `TextScaler` from `MediaQuery`
- Minimum text size after scaling: 11px
- Overflow: `TextOverflow.ellipsis` with `Tooltip`, or allow wrapping

---

## 8. Audio Accessibility

- All audio has visual equivalent
- Independent volume controls (SFX, music, voice)
- Game fully playable with sound off
- Mikhail voice lines displayed as text bubbles (persist ≥ 3s)

---

## 9. Cognitive Accessibility

- Consistent navigation on every screen
- Predictable button behavior
- Undo available for all game moves
- Simple language (6th-grade reading level)
- No time pressure in local play

---

## 10. Testing Checklist

### Automated
- [ ] Color pairs verified against WCAG in unit tests
- [ ] Touch targets ≥ 48dp in widget tests
- [ ] 200% text scale: no overflow errors
- [ ] Semantic labels on all interactive widgets
- [ ] Focus traversal order matches visual order

### Manual
- [ ] VoiceOver (iOS) / TalkBack (Android) walkthrough
- [ ] Full game playable via screen reader
- [ ] Keyboard-only navigation
- [ ] Reduced motion mode respected
- [ ] Color-blind simulation: all info accessible
- [ ] Sound off: all events have visual feedback
- [ ] 200% text scale: all screens usable

### Per-Release
1. Run `flutter test --tags accessibility`
2. VoiceOver/TalkBack on changed screens
3. Verify contrast if colors modified
4. Test with max system font size
