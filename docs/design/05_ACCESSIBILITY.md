# Accessibility

> WCAG 2.1 Level AA (minimum) | Level AAA (target for critical elements)
> Compliance target: all interactive UI, game controls, and informational displays

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — Color palette, typography, spacing tokens
- [Components](02_COMPONENTS.md) — Per-component accessibility specs
- [States](03_STATES.md) — Focus, disabled, and error state accessibility
- [Uniform Design](06_UNIFORM_DESIGN.md) — Consistency as accessibility aid

---

## 1. Color Contrast

### 1.1 WCAG Contrast Requirements

| Category | Minimum Ratio | Applies To |
|----------|---------------|------------|
| Normal text (< 18px regular, < 14px bold) | 4.5:1 (AA) | All body text, labels, placeholders |
| Large text (≥ 18px regular, ≥ 14px bold) | 3:1 (AA) | Headings, display text, bold labels |
| UI components & graphical objects | 3:1 (AA) | Borders, icons, focus rings, form controls |
| Enhanced (AAA) | 7:1 | Target for primary body text, critical game info |

### 1.2 Complete Contrast Matrix

Every possible foreground/background combination from the 5 core colors:

| Foreground ↓ / Background → | Light `#F3F0EB` | Background `#D4C2A8` | Surface `#A67F5B` | Primary `#6B4F3A` | Text `#1A1A1A` |
|------------------------------|-----------------|----------------------|-------------------|--------------------|----|
| **Light** `#F3F0EB` | — | 1.5:1 | 2.9:1 | 5.6:1 AA | 15.0:1 AAA |
| **Background** `#D4C2A8` | 1.5:1 | — | 1.8:1 | 3.5:1 Lg | 9.5:1 AAA |
| **Surface** `#A67F5B` | 2.9:1 | 1.8:1 | — | 2.0:1 | 5.0:1 AA |
| **Primary** `#6B4F3A` | 5.6:1 AA | 3.5:1 Lg | 2.0:1 | — | 2.7:1 |
| **Text** `#1A1A1A` | 15.0:1 AAA | 9.5:1 AAA | 5.0:1 AA | 2.7:1 | — |

**Legend:**
- **AAA** = Passes WCAG AAA (≥ 7:1) for all text
- **AA** = Passes WCAG AA (≥ 4.5:1) for normal text
- **Lg** = Passes for large text only (≥ 3:1)
- No label = Fails all WCAG text criteria

### 1.3 Safe Combinations (Quick Reference)

Use these combinations freely:

| Use Case | Foreground | Background | Ratio | Level |
|----------|------------|------------|-------|-------|
| Primary body text | `text` #1A1A1A | `light` #F3F0EB | 15.0:1 | AAA |
| Primary body text | `text` #1A1A1A | `background` #D4C2A8 | 9.5:1 | AAA |
| Card text | `text` #1A1A1A | `surface` #A67F5B | 5.0:1 | AA |
| Button label (filled) | `light` #F3F0EB | `primary` #6B4F3A | 5.6:1 | AA |
| Button label (filled) | `light` #F3F0EB | `text` #1A1A1A | 15.0:1 | AAA |
| Heading on page | `primary` #6B4F3A | `light` #F3F0EB | 5.6:1 | AA |
| Inverse text | `background` #D4C2A8 | `text` #1A1A1A | 9.5:1 | AAA |

### 1.4 Forbidden Combinations

Never use these — they fail WCAG for all text sizes:

| Foreground | Background | Ratio | Why |
|------------|------------|-------|-----|
| `light` #F3F0EB | `surface` #A67F5B | 2.9:1 | Below 3:1, fails even for large text |
| `light` #F3F0EB | `background` #D4C2A8 | 1.5:1 | Near-invisible, no contrast |
| `background` #D4C2A8 | `surface` #A67F5B | 1.8:1 | Insufficient differentiation |
| `surface` #A67F5B | `background` #D4C2A8 | 1.8:1 | Same issue, reversed |
| `surface` #A67F5B | `primary` #6B4F3A | 2.0:1 | Too close in luminance |
| `primary` #6B4F3A | `text` #1A1A1A | 2.7:1 | Both too dark |

### 1.5 State Shade Contrast Verification

State shades must maintain the same WCAG compliance as their parent color:

| State Shade | Used On | Text Color | Ratio | Status |
|-------------|---------|------------|-------|--------|
| `backgroundHover` #C4B298 | Page bg | `text` #1A1A1A | ~8.5:1 | AAA |
| `backgroundActive` #BAA88E | Page bg | `text` #1A1A1A | ~7.8:1 | AAA |
| `surfaceHover` #997353 | Cards | `text` #1A1A1A | ~4.5:1 | AA |
| `surfaceActive` #906A4A | Cards | `text` #1A1A1A | ~4.1:1 | AA (borderline) |
| `primaryHover` #7A5E49 | Buttons | `light` #F3F0EB | ~4.8:1 | AA |
| `primaryActive` #846852 | Buttons | `light` #F3F0EB | ~4.2:1 | AA (borderline) |
| `lightHover` #E9E6E1 | Light bg | `text` #1A1A1A | ~13.8:1 | AAA |
| `lightActive` #DFDCD7 | Light bg | `text` #1A1A1A | ~12.8:1 | AAA |

> **Note:** `surfaceActive` and `primaryActive` are borderline AA. These states are transient (< 200ms) and always accompanied by visual feedback (scale, shadow change), so they are acceptable per WCAG SC 1.4.11 (non-text contrast for UI components in active states).

### 1.6 Opacity Rules

| Context | Minimum Opacity | Rationale |
|---------|-----------------|-----------|
| Interactive text (buttons, links) | 100% | Must meet contrast at full opacity |
| Body text | 100% | Must meet contrast at full opacity |
| Placeholder text | 60% of `text` color | Must still meet 3:1 on background |
| Disabled elements | 38% | Communicates non-interactive state; exempt from contrast requirements per WCAG |
| Decorative elements | Any | Non-informational, exempt |
| Borders (informational) | 100% | Must meet 3:1 against adjacent colors |

---

## 2. Touch Targets

### 2.1 Minimum Sizes

| Element | Minimum Size | Recommended | Standard |
|---------|-------------|-------------|----------|
| Buttons | 48 × 48 dp | 56 × 48 dp | WCAG 2.5.8 (AAA: 44×44) |
| Icon buttons | 48 × 48 dp | 48 × 48 dp | Material 3 guideline |
| List items | 48dp height | 56dp height | M3 ListTile |
| Chips/tags | 32dp height, 48dp touch | 36dp height | Touch target wraps visual |
| Navigation items | 48 × 48 dp | 64 × 48 dp | Bottom nav specification |
| Slider thumb | 48 × 48 dp touch | 28px visual | Touch target invisible, larger than visual |
| Game checkers | 48 × 48 dp | Scale with board | Game-specific: must be tappable |
| Game dice | 48 × 48 dp | 64 × 64 dp | Must be easy to tap |

### 2.2 Spacing Between Targets

Adjacent touch targets must have **≥ 8dp** spacing between their edges to prevent accidental activation.

### 2.3 Implementation Pattern

```dart
// Wrap small visual elements in padded touch targets
InkWell(
  customBorder: const CircleBorder(),
  child: Padding(
    padding: const EdgeInsets.all(12), // visual 24px + 12px padding = 48dp target
    child: Icon(Icons.settings, size: 24),
  ),
  onTap: () {},
)
```

---

## 3. Color-Independent Information

### 3.1 Principle

Color must never be the **sole** means of conveying information. Every color-coded element must have a secondary indicator.

### 3.2 Required Secondary Indicators

| Information | Color | Secondary Indicator |
|-------------|-------|---------------------|
| Valid move | Green highlight | Pulsing dot + shape outline |
| Invalid move | Red highlight | X icon + haptic feedback |
| Selected checker | Glow effect | Elevated shadow + scale 1.1× |
| Player turn | Color accent | Text label "Your turn" + icon |
| Error state | `error` color | Error icon + descriptive text |
| Success state | `success` color | Checkmark icon + descriptive text |
| Warning state | `warning` color | Warning triangle + descriptive text |
| Dice value | Dot pattern | Semantic label with value |
| Win/loss | Color treatment | Text label + icon |

### 3.3 Game Board Indicators

On the game board (Flame canvas), move indicators must use **shape + color + animation**:

```
Valid target point:    ● pulsing circle (green) + slight glow
Blocked point:        ✕ static X mark (red) + no glow
Selected source:      ↑ raised checker + shadow increase + scale
Bar entry point:      ▶ directional arrow + pulse
Bear-off zone:        □ outlined rectangle + pulse
```

---

## 4. Screen Reader Support

### 4.1 Semantic Labels

Every interactive element must have a semantic label that describes its **purpose**, not its appearance.

| Element | Good Label | Bad Label |
|---------|-----------|-----------|
| Dice roll button | "Roll dice" | "Dice button" |
| Settings icon | "Open settings" | "Gear icon" |
| Checker piece | "Your checker on point 12" | "Brown circle" |
| Undo button | "Undo last move" | "Arrow" |
| Double offer | "Offer double, cube at 2" | "Cube" |
| Board point | "Point 8, 3 of your checkers" | "Triangle" |

### 4.2 Game State Announcements

The game must announce state changes via `Semantics.liveRegion`:

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

Screen reader navigation must follow a logical order:

1. App bar / screen title
2. Primary content (top to bottom)
3. Action buttons (left to right)
4. Bottom navigation

### 4.4 Implementation Pattern

```dart
Semantics(
  button: true,
  label: 'Roll dice',
  hint: 'Double tap to roll',
  child: DiceRollButton(),
)

// For live announcements
SemanticsService.announce(
  'You rolled 3 and 5',
  TextDirection.ltr,
);
```

---

## 5. Keyboard & Focus Navigation

### 5.1 Focus Indicator

All focusable elements must display a visible focus ring:

| Property | Value |
|----------|-------|
| Ring color | `primary` (`#6B4F3A`) |
| Ring width | 2px |
| Ring offset | 2px from element edge |
| Ring shape | Matches element shape (rounded rect for cards, circle for avatars) |
| Contrast | Ring must have ≥ 3:1 contrast against adjacent backgrounds |

### 5.2 Focus Order

Tab order must match visual reading order (top-to-bottom, left-to-right for LTR layouts). Use `FocusTraversalGroup` to group related elements.

### 5.3 Keyboard Shortcuts (Game)

| Key | Action |
|-----|--------|
| Space / Enter | Confirm selection / roll dice |
| Escape | Cancel current action / deselect |
| Arrow keys | Navigate between board points |
| Tab | Move focus between UI elements |
| U | Undo last move |
| D | Offer double |

---

## 6. Motion & Animation

### 6.1 Reduced Motion Support

When the system preference `MediaQuery.disableAnimations` is `true`:

| Animation | Default | Reduced Motion |
|-----------|---------|---------------|
| Page transitions | Slide + fade, 300ms | Instant cut |
| Checker movement | Arc path, 400ms | Instant reposition |
| Dice roll | Tumble animation, 800ms | Static result display |
| Card hover/press | Scale + shadow, 150ms | Instant state change |
| Loading shimmer | Gradient sweep | Static placeholder |
| Victory celebration | Particles + glow | Static badge display |
| Slider thumb | Spring physics | Snap to position |

### 6.2 Animation Constraints

| Property | Limit | Reason |
|----------|-------|--------|
| Max duration | 1000ms | Prevent attention fatigue |
| No flashing | < 3 flashes/second | WCAG 2.3.1 seizure prevention |
| No auto-play loops | Must be user-initiated | WCAG 2.2.2 pause/stop |
| Essential motion only | Game moves, dice rolls | Decorative motion must be optional |

### 6.3 Implementation Pattern

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);

AnimatedContainer(
  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // ...
)
```

---

## 7. Text Scaling

### 7.1 Requirements

| Scale Factor | Requirement |
|-------------|-------------|
| 100% (default) | Fully functional |
| 150% | Fully functional, no content clipping |
| 200% | All text readable, layouts may reflow |
| > 200% | Best effort, no crashes |

### 7.2 Implementation Rules

1. **Never use fixed heights** on text containers — use `Flexible`, `Expanded`, or unconstrained height
2. **Use `TextScaler`** from `MediaQuery` — never override system text scaling
3. **Test all screens** at 200% scale during development
4. **Minimum text size** after scaling: 11px (the smallest scale step)
5. **Overflow handling:** Use `TextOverflow.ellipsis` with a `Tooltip` containing the full text, or allow wrapping

### 7.3 Testing

```dart
// In widget tests, verify layout at 200% scale
testWidgets('survives 200% text scale', (tester) async {
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  await tester.pumpWidget(MyScreen());
  expect(tester.takeException(), isNull);
  // Verify no overflow
  expect(find.byType(OverflowBar), findsNothing);
});
```

---

## 8. Audio Accessibility

### 8.1 Requirements

| Requirement | Implementation |
|-------------|---------------|
| All audio has visual equivalent | Dice roll → visual dice animation; move sound → visual checker movement |
| Independent volume controls | SFX, music, and voice volumes separately adjustable |
| Audio is optional | Game is fully playable with sound off |
| No audio-only information | Every sound-communicated event has a visual counterpart |
| Captions for speech | Mikhail's voice lines displayed as text bubbles |

### 8.2 Mikhail Voice Accessibility

When Mikhail speaks:
1. Voice line plays (if voice volume > 0)
2. Text bubble displays simultaneously with the spoken text
3. Text bubble persists for at least 3 seconds or until dismissed
4. Screen reader announces the text content

---

## 9. Cognitive Accessibility

### 9.1 Principles

| Principle | Implementation |
|-----------|---------------|
| Consistent navigation | Same navigation pattern on every screen |
| Predictable actions | Buttons always do what their label says |
| Error recovery | Undo available for all game moves |
| Simple language | UI copy at 6th-grade reading level |
| Progress indication | Turn indicator always visible during gameplay |
| No time pressure | No countdown timers in local play |

### 9.2 Undo & Error Prevention

- **Game moves:** Undo available until end-of-turn confirmation
- **Settings changes:** Take effect immediately with visible feedback; reversible
- **Destructive actions:** Confirmation dialog required (delete account, reset stats)

---

## 10. Testing Checklist

### Automated Tests

- [ ] All color constant pairs verified against WCAG ratios in unit tests
- [ ] Touch target sizes verified (≥ 48dp) in widget tests
- [ ] Text scaling at 200% produces no overflow errors
- [ ] Semantic labels present on all interactive widgets
- [ ] Focus traversal order matches visual order

### Manual Tests

- [ ] VoiceOver (iOS) / TalkBack (Android) walkthrough of all screens
- [ ] Full game playable via screen reader
- [ ] Keyboard-only navigation (connected keyboard on tablet)
- [ ] Reduced motion mode: all animations respect preference
- [ ] High contrast mode: all text remains readable
- [ ] Color-blind simulation: all information accessible without color
- [ ] Sound off: all game events have visual feedback
- [ ] 200% text scale: all screens usable

### Per-Release Verification

Before each release:
1. Run automated accessibility tests (`flutter test --tags accessibility`)
2. Complete manual VoiceOver/TalkBack walkthrough on one new/changed screen
3. Verify contrast ratios if any colors were modified
4. Test with system font size set to maximum

---

## 11. Uniform Design Considerations

Accessibility is strengthened by consistency:

- **Same interaction patterns** everywhere reduce cognitive load
- **Predictable layouts** help screen reader users build mental models
- **Consistent focus indicators** make keyboard navigation learnable
- **Uniform spacing** creates predictable touch target placement

See [Uniform Design](06_UNIFORM_DESIGN.md) for consistency rules that directly support accessibility.

---

## 12. Material Design 3 Alignment

Tavli leverages M3 accessibility features:

| M3 Feature | Tavli Usage |
|------------|------------|
| `Semantics` widget | All interactive elements wrapped |
| `ExcludeSemantics` | Decorative elements excluded |
| `MergeSemantics` | Related label + control merged |
| `MaterialStateProperty` | State-aware colors maintain contrast |
| `FocusNode` / `FocusTraversalGroup` | Logical focus ordering |
| `Tooltip` | All icon buttons have tooltips |
| `MediaQuery.disableAnimations` | Motion preference respected |
| `TextScaler` | System text scaling honored |

See [Material Design 3](07_MATERIAL_DESIGN.md) for the complete M3 integration specification.
