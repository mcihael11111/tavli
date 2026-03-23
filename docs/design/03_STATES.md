# Interaction States

> Every interaction state for every component in the Tavli design system.
> All state treatments use tokens from [Design System](01_DESIGN_SYSTEM.md).

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — State shade colors, core tokens
- [Components](02_COMPONENTS.md) — Component specifications (default state)
- [Accessibility](05_ACCESSIBILITY.md) — Focus visibility, state announcements
- [Material Design 3](07_MATERIAL_DESIGN.md) — `WidgetState` implementation

---

## 1. State Definitions

### 1.1 Universal States

| State | Trigger | Visual Treatment | Duration |
|-------|---------|-----------------|----------|
| **Default** | Rest | Base colors, no overlay | — |
| **Hover** | Pointer over element | Darken/lighten by 8% | Instant (50ms fade) |
| **Pressed** | Active touch/click | Darken/lighten by 12% + scale 0.98 | 100ms |
| **Focused** | Keyboard/tab focus | 2px `primary` focus ring, 2px offset | Instant |
| **Disabled** | Element non-interactive | 38% opacity, no pointer events | — |
| **Selected** | Active choice (tabs, toggles) | Distinct fill/border treatment | 150ms transition |
| **Error** | Validation failure | `error` border + error icon + message | 200ms transition |
| **Loading** | Async operation in progress | Shimmer or spinner replacement | Continuous |

### 1.2 State Treatment Formula

```
Hover:    core_color.darken(8%)    — for light colors
          core_color.lighten(8%)   — for dark colors (primary, text)
Pressed:  core_color.darken(12%)   — for light colors
          core_color.lighten(12%)  — for dark colors
Focused:  core_color + 2px ring(primary, offset: 2px)
Disabled: core_color.withOpacity(0.38)
```

### 1.3 Transition Timing

| Transition | Duration | Curve | M3 Token |
|------------|----------|-------|----------|
| Default → Hover | 50ms | `easeIn` | Duration Short 1 |
| Hover → Default | 100ms | `easeOut` | Duration Short 2 |
| Default → Pressed | 100ms | `easeIn` | Duration Short 2 |
| Pressed → Default | 150ms | `easeOut` | Duration Short 3 |
| Default → Focused | Instant | — | — |
| Default → Disabled | 200ms | `easeInOut` | Duration Short 4 |
| Default → Selected | 150ms | `easeInOut` | Duration Short 3 |
| Default → Error | 200ms | `easeInOut` | Duration Short 4 |

---

## 2. Filled Button States

| State | Background | Text | Border | Elevation | Scale | Other |
|-------|-----------|------|--------|-----------|-------|-------|
| Default | `primary` #6B4F3A | `light` #F3F0EB | None | `xsmall` | 1.0 | — |
| Hover | `primaryHover` #7A5E49 | `light` #F3F0EB | None | `xsmall` | 1.0 | Cursor: pointer |
| Pressed | `primaryActive` #846852 | `light` #F3F0EB | None | None (flat) | 0.98 | — |
| Focused | `primary` #6B4F3A | `light` #F3F0EB | 2px `primary` ring | `xsmall` | 1.0 | Ring offset 2px |
| Disabled | `primary` at 38% | `light` at 38% | None | None | 1.0 | No pointer |
| Loading | `primary` #6B4F3A | Hidden | None | `xsmall` | 1.0 | Spinner centered |

**Contrast verification:**
- Hover: Light on primaryHover (#7A5E49) ≈ 4.8:1 → AA pass
- Pressed: Light on primaryActive (#846852) ≈ 4.2:1 → AA borderline (transient, acceptable)
- Disabled: Exempt from contrast requirements per WCAG

### Implementation

```dart
FilledButton.styleFrom(
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return TavliColors.primary.withOpacity(0.38);
    if (states.contains(WidgetState.pressed)) return TavliColors.primaryActive;
    if (states.contains(WidgetState.hovered)) return TavliColors.primaryHover;
    return TavliColors.primary;
  }),
  foregroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return TavliColors.light.withOpacity(0.38);
    return TavliColors.light;
  }),
);
```

---

## 3. Outlined Button States

| State | Background | Text | Border | Elevation | Scale |
|-------|-----------|------|--------|-----------|-------|
| Default | `background` #D4C2A8 | `primary` #6B4F3A | 1px `primary` | `xsmall` | 1.0 |
| Hover | `backgroundHover` #C4B298 | `primary` #6B4F3A | 1px `primary` | `xsmall` | 1.0 |
| Pressed | `backgroundActive` #BAA88E | `primary` #6B4F3A | 1px `primary` | None | 0.98 |
| Focused | `background` #D4C2A8 | `primary` #6B4F3A | 2px `primary` ring | `xsmall` | 1.0 |
| Disabled | `background` at 38% | `primary` at 38% | 1px `primary` at 38% | None | 1.0 |

**Contrast verification:**
- Default: Primary on Background = 3.5:1 (large text, 16px Medium = bold equivalent → passes)
- Hover: Primary on backgroundHover (#C4B298) ≈ 3.2:1 (large text pass)

---

## 4. Text Button States

| State | Text | Background | Other |
|-------|------|-----------|-------|
| Default | `primary` #6B4F3A | Transparent | — |
| Hover | `primary` #6B4F3A | `backgroundHover` #C4B298 at 50% | Subtle highlight |
| Pressed | `primaryActive` #846852 | `backgroundActive` #BAA88E at 50% | — |
| Focused | `primary` #6B4F3A | Transparent + 2px ring | — |
| Disabled | `primary` at 38% | Transparent | No pointer |

---

## 5. Icon Button States

| State | Icon Color | Background | Other |
|-------|-----------|-----------|-------|
| Default | `primary` #6B4F3A | Transparent | — |
| Hover | `primary` #6B4F3A | `backgroundHover` at 30% | Circular highlight |
| Pressed | `primaryActive` #846852 | `backgroundActive` at 30% | Scale 0.95 |
| Focused | `primary` #6B4F3A | Transparent + 2px ring | Circle ring |
| Disabled | `primary` at 38% | Transparent | No pointer, no tooltip |

---

## 6. Card States

### 6.1 Standard Card (Tappable)

| State | Background | Border | Elevation | Scale | Other |
|-------|-----------|--------|-----------|-------|-------|
| Default | `surface` #A67F5B | 1px `primary` | `xsmall` | 1.0 | — |
| Hover | `surfaceHover` #997353 | 1px `primary` | `small` | 1.0 | Cursor: pointer |
| Pressed | `surfaceActive` #906A4A | 1px `primary` | None | 0.98 | — |
| Focused | `surface` #A67F5B | 2px `primary` ring | `xsmall` | 1.0 | Ring offset 2px |
| Disabled | `surface` at 38% | 1px `primary` at 38% | None | 1.0 | Content at 38% |

**Contrast verification:**
- Hover: Text on surfaceHover (#997353) ≈ 4.5:1 → AA pass (borderline)
- Pressed: Text on surfaceActive (#906A4A) ≈ 4.1:1 → transient, acceptable

### 6.2 Non-Tappable Card

Cards that display information but are not interactive (e.g., example box on Greek slider screen):
- Only **Default** state applies
- No hover, pressed, or focus states
- Cursor: default

### 6.3 User Profile Card

| State | Background | Border | Other |
|-------|-----------|--------|-------|
| Default | `background` #D4C2A8 | 1px `primary` | — |
| Hover | `backgroundHover` #C4B298 | 1px `primary` | Cursor: pointer |
| Pressed | `backgroundActive` #BAA88E | 1px `primary` | Scale 0.98 |

---

## 7. Tab/Segment States

| State | Background | Text | Border | Other |
|-------|-----------|------|--------|-------|
| Unselected | `surface` #A67F5B | `text` #1A1A1A | 1px `primary` | — |
| Selected | `primary` #6B4F3A | `light` #F3F0EB | 1px `primary` | — |
| Hover (unselected) | `surfaceHover` #997353 | `text` #1A1A1A | 1px `primary` | Cursor: pointer |
| Pressed (unselected) | `surfaceActive` #906A4A | `text` #1A1A1A | 1px `primary` | — |
| Focused | Current bg + 2px ring | Current text | 2px `primary` ring | — |
| Disabled | Current bg at 38% | Current text at 38% | 1px at 38% | No pointer |

**Contrast verification:**
- Selected: Light on Primary = 5.6:1 → AA pass
- Unselected: Text on Surface = 5.0:1 → AA pass

**Accessibility:**
- Role: `tab` / `tablist`
- Selected state announced by screen reader
- Arrow keys navigate between tabs within group

---

## 8. Input Field States

| State | Fill | Border | Label | Other |
|-------|------|--------|-------|-------|
| Empty | `surface` #A67F5B | 1px `primary` | Above field, `text` | Placeholder at 60% opacity |
| Filled | `surface` #A67F5B | 1px `primary` | Above field, `text` | Input text in `text` |
| Focused | `surface` #A67F5B | 2px `primary` | Label in `primary`, scaled | Caret visible |
| Error | `surface` #A67F5B | 2px `error` #A0442C | Label in `error` | Error text + icon below |
| Disabled | `surface` at 38% | 1px `primary` at 38% | Label at 38% | No input, cursor: default |
| Read-only | `background` #D4C2A8 | 1px `primary` at 50% | Above field, `text` | Selectable but not editable |

**Error state details:**
- Border changes to 2px `error`
- Error icon (16dp) + error text (12px) appear below the field
- Error text color: `error` (#A0442C)
- Entire field does NOT turn red — only the border

---

## 9. Switch States

| State | Thumb | Track | Other |
|-------|-------|-------|-------|
| Off | `surface` #A67F5B | `backgroundHover` #C4B298 | — |
| On | `primary` #6B4F3A | `surface` #A67F5B | — |
| Off + Hover | `surfaceHover` #997353 | `backgroundActive` #BAA88E | — |
| On + Hover | `primaryHover` #7A5E49 | `surfaceHover` #997353 | — |
| Off + Disabled | `surface` at 38% | `backgroundHover` at 38% | No pointer |
| On + Disabled | `primary` at 38% | `surface` at 38% | No pointer |
| Focused | Current + 2px ring | Current | Ring around thumb |

**Accessibility:**
- Role: `switch`
- Label: describes what the switch controls
- State: "on" / "off" announced

---

## 10. Slider States

| State | Thumb | Track | Other |
|-------|-------|-------|-------|
| Default | `surface` + `primary` dot + `primary` border | `surface` | Stop dots visible |
| Dragging | `surfaceHover` + `primary` dot | `surface` | Scale thumb 1.1× |
| Hover | `surfaceHover` + shadow increase | `surface` | Cursor: grab |
| Focused | `surface` + 2px `primary` ring | `surface` | — |
| Disabled | `surface` at 38% | `surface` at 38% | No pointer |

**Accessibility:**
- Role: `slider`
- Value: current level announced
- Min/max: announced on focus
- Step changes: announced via live region

---

## 11. Navigation Item States

### 11.1 Bottom Navigation Bar Items

| State | Container Fill | Icon Color | Other |
|-------|---------------|-----------|-------|
| Active | `background` #D4C2A8 | `primary` #6B4F3A | — |
| Inactive | `primary` #6B4F3A | `light` #F3F0EB | — |
| Hover (inactive) | `primaryHover` #7A5E49 | `light` #F3F0EB | — |
| Pressed | `primaryActive` #846852 | `light` #F3F0EB | Scale 0.95 |

### 11.2 Onboarding Pagination

| State | Active Dot | Inactive Dot |
|-------|-----------|-------------|
| Current | Pill 52×14px, `light` #F3F0EB | Circle 14px, `primary` #6B4F3A |

No interactive states — pagination is informational only (progress driven by "Next" button).

---

## 12. List Tile States

When list items are wrapped in cards, card states apply. See [Card States](#6-card-states).

For bare list tiles (without card wrapper):

| State | Background | Text | Divider |
|-------|-----------|------|---------|
| Default | Transparent | `text` #1A1A1A | 1px `primary` at 20% |
| Hover | `backgroundHover` #C4B298 at 50% | `text` #1A1A1A | — |
| Pressed | `backgroundActive` #BAA88E at 50% | `text` #1A1A1A | — |
| Selected | `surface` at 30% | `text` #1A1A1A | — |
| Focused | Transparent + 2px ring | `text` #1A1A1A | — |

---

## 13. Board Carousel Card States

| State | Elevation | Transform | Other |
|-------|-----------|-----------|-------|
| Front (active) | `large` | Upright, z-index top | Full opacity |
| Behind | `large` | Rotated ~9°, lower z | 100% opacity, partially obscured |
| Swiping | `large` | Interactive rotation | Follows gesture |

Carousel cards do not have hover/focus states — interaction is via swipe gesture only.

---

## 14. Game Element States

### 14.1 Checker States

| State | Visual Treatment | Screen Reader |
|-------|-----------------|---------------|
| Default | Base color, resting position | "{player}'s checker on point {n}" |
| Selectable | Subtle pulse animation | "Selectable. {player}'s checker on point {n}" |
| Selected | Elevated, scale 1.1×, glow shadow | "Selected. {player}'s checker on point {n}" |
| Moving | Arc animation to target | "Moving to point {n}" |
| Hit | Flash + move to bar | "Hit! Sent to bar" |
| On bar | Displayed in bar area | "On bar. Must re-enter" |

### 14.2 Board Point States

| State | Visual Treatment | Screen Reader |
|-------|-----------------|---------------|
| Default | Base color | "Point {n}, {count} {player} checkers" |
| Valid target | Pulsing green dot + outline | "Valid move target. Point {n}" |
| Blocked | Red X mark | "Blocked. Point {n}" |
| Highlighted source | Glow + accent | "Move from here" |

### 14.3 Dice States

| State | Visual Treatment | Screen Reader |
|-------|-----------------|---------------|
| Ready to roll | Subtle bounce | "Tap to roll dice" |
| Rolling | Tumble animation | "Rolling..." |
| Result shown | Static, used dice greyed | "Rolled {value}. {remaining} moves left" |
| Used | 50% opacity | "Die {value} used" |

---

## 15. Focus Ring Specification

Consistent across all focusable elements:

| Property | Value |
|----------|-------|
| Color | `primary` #6B4F3A |
| Width | 2px |
| Offset | 2px outward from element edge |
| Shape | Matches element shape |
| Contrast | 3.5:1 against `background`, 5.6:1 against `light` → passes 3:1 UI component requirement |

### Implementation

```dart
// Global focus theme
ThemeData(
  focusColor: TavliColors.primary,
  // Or per-widget:
)

// Custom focus decoration
Container(
  decoration: BoxDecoration(
    border: isFocused
      ? Border.all(color: TavliColors.primary, width: 2)
      : null,
    borderRadius: borderRadius + const BorderRadius.all(Radius.circular(2)),
  ),
)
```

---

## 16. Disabled State Rules

Universal rules for disabled elements:

1. **Opacity:** 38% on the entire element (container + content)
2. **Pointer events:** None (`IgnorePointer` or `AbsorbPointer`)
3. **Cursor:** Default (not pointer)
4. **Focus:** Not focusable (`canRequestFocus: false`)
5. **Screen reader:** Announces "disabled" or "dimmed"
6. **No elevation:** Shadows removed
7. **WCAG exemption:** Disabled elements are exempt from contrast requirements

### Implementation

```dart
Opacity(
  opacity: isDisabled ? 0.38 : 1.0,
  child: IgnorePointer(
    ignoring: isDisabled,
    child: Semantics(
      enabled: !isDisabled,
      child: widget,
    ),
  ),
)
```

---

## 17. Accessibility

### State Announcements

Screen readers must announce state changes for interactive elements:

| State Change | Announcement |
|-------------|-------------|
| Enabled → Disabled | "{label}, disabled" |
| Unselected → Selected | "{label}, selected" |
| Default → Error | "{label}, error: {error message}" |
| Switch off → on | "{label}, on" |
| Slider value change | "{label}, {new value}" |

### Focus Visibility

- Focus ring must be visible at all times when element is focused
- Minimum 2px width, 3:1 contrast against all adjacent backgrounds
- See [Accessibility > Focus Indicator](05_ACCESSIBILITY.md#focus-indicator)

---

## 18. Uniform Design

### Consistency Rules for States

1. **Same state treatment across all instances** of a component type
2. **Hover always darkens/lightens by 8%** — no exceptions
3. **Pressed always darkens/lightens by 12%** — no exceptions
4. **Disabled always 38% opacity** — no exceptions
5. **Focus ring always 2px `primary` with 2px offset** — no exceptions
6. **Transition timing consistent** per state type (see timing table above)
7. **Scale on press always 0.98** for buttons and cards

No one-off state treatments. If a component needs different behavior, it becomes a new documented variant.

---

## 19. Material Design 3 Alignment

### WidgetState Implementation

All state-aware styling uses `WidgetStateProperty.resolveWith`:

```dart
WidgetStateProperty.resolveWith<Color>((states) {
  if (states.contains(WidgetState.disabled)) {
    return baseColor.withOpacity(0.38);
  }
  if (states.contains(WidgetState.pressed)) {
    return activeShade;
  }
  if (states.contains(WidgetState.hovered)) {
    return hoverShade;
  }
  if (states.contains(WidgetState.focused)) {
    return baseColor; // Focus ring handled separately
  }
  return baseColor;
});
```

### Deviation from M3 State Layers

M3 applies semi-transparent color overlays at runtime. Tavli uses pre-computed shade colors. See [Material Design 3 > State Layers](07_MATERIAL_DESIGN.md#state-layers) for rationale.
