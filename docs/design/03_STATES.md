# Interaction States — Universal Rules

> **This document defines the universal state formulas and timing that apply to ALL components.**
> Per-component state tables (what each button/card/input looks like in each state) are in [02_COMPONENTS.md](02_COMPONENTS.md).
> Token values are defined in [00_TOKENS.md](00_TOKENS.md).

---

## 1. Universal State Definitions

| State | Trigger | Visual Treatment | Duration |
|-------|---------|-----------------|----------|
| **Default** | Rest | Base colors, no overlay | — |
| **Hover** | Pointer over element | Darken/lighten by 8% | 50ms fade in |
| **Pressed** | Active touch/click | Darken/lighten by 12% + scale 0.98 | 100ms |
| **Focused** | Keyboard/tab focus | 2px `primary` focus ring, 2px offset | Instant |
| **Disabled** | Element non-interactive | 38% opacity, no pointer events | 200ms |
| **Selected** | Active choice (tabs, toggles) | Distinct fill/border per component | 150ms |
| **Error** | Validation failure | `error` border + icon + message | 200ms |
| **Loading** | Async in progress | Shimmer or spinner replacement | Continuous |

---

## 2. State Treatment Formula

```
Hover:    core_color.darken(8%)    — for light colors (background, surface, light)
          core_color.lighten(8%)   — for dark colors (primary, text)
Pressed:  core_color.darken(12%)   — for light colors
          core_color.lighten(12%)  — for dark colors
Focused:  core_color + 2px ring(primary, offset: 2px)
Disabled: core_color.withOpacity(0.38)
```

All shades are **pre-computed** (not runtime opacity overlays). See [00_TOKENS.md](00_TOKENS.md) for the exact hex values.

---

## 3. Transition Timing

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
| Page transitions | 300ms | `easeInOut` | Duration Medium 2 |

---

## 4. Focus Ring Specification

Consistent across ALL focusable elements:

| Property | Value |
|----------|-------|
| Color | `primary` |
| Width | 2px |
| Offset | 2px outward from element edge |
| Shape | Matches element shape (rounded rect for cards, circle for avatars) |
| Contrast | 3.5:1 against `background`, 5.6:1 against `light` → passes 3:1 UI component req |

---

## 5. Disabled State Rules

Universal for ALL disabled elements:

1. **Opacity:** 38% on entire element (container + content)
2. **Pointer events:** None (`IgnorePointer` or `AbsorbPointer`)
3. **Cursor:** Default (not pointer)
4. **Focus:** Not focusable (`canRequestFocus: false`)
5. **Screen reader:** Announces "disabled" or "dimmed"
6. **Elevation:** Shadows removed
7. **WCAG exemption:** Disabled elements are exempt from contrast requirements

---

## 6. Consistency Rules

1. **Hover = 8%** — every component, no exceptions
2. **Pressed = 12%** — every component, no exceptions
3. **Disabled = 38% opacity** — every component, no exceptions
4. **Focus = 2px `primary` ring, 2px offset** — every focusable element
5. **Transition timing matches the table above** — no custom durations
6. **Press scale = 0.98** for buttons and cards
7. **No one-off state treatments.** If different behavior is needed, create a new documented component variant.

---

## 7. Screen Reader State Announcements

| State Change | Announcement |
|-------------|-------------|
| Enabled → Disabled | "{label}, disabled" |
| Unselected → Selected | "{label}, selected" |
| Default → Error | "{label}, error: {error message}" |
| Switch off → on | "{label}, on" |
| Slider value change | "{label}, {new value}" |

---

## 8. M3 Implementation

All state-aware styling uses `WidgetStateProperty.resolveWith`:

```dart
WidgetStateProperty.resolveWith<Color>((states) {
  if (states.contains(WidgetState.disabled)) return baseColor.withOpacity(0.38);
  if (states.contains(WidgetState.pressed)) return activeShade;
  if (states.contains(WidgetState.hovered)) return hoverShade;
  if (states.contains(WidgetState.focused)) return baseColor; // Ring handled separately
  return baseColor;
});
```

**M3 deviation:** M3 uses runtime `Color.withOpacity()` overlays. Tavli uses pre-computed shade colors to avoid translucency artifacts on game canvas. See [07_MATERIAL_DESIGN.md](07_MATERIAL_DESIGN.md).
