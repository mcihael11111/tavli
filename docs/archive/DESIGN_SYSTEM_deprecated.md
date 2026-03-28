> **DEPRECATED** — This document has been superseded by the new design system in [`docs/design/`](design/).
> See [`design/01_DESIGN_SYSTEM.md`](design/01_DESIGN_SYSTEM.md) for the current specification.

# Tavli Design System v2 (Deprecated)

**Updated**: March 2026
**Stack**: Flutter + Flame + Material 3

---

## 1. Color Palette

### Core Palette (6 colors)

| Swatch | Name | Hex | RGB | Role |
|--------|------|-----|-----|------|
| ![#ede0d4](https://via.placeholder.com/20/ede0d4/ede0d4) | **Cream** | `#ede0d4` | 237, 224, 212 | Primary background (light theme) |
| ![#e6ccb2](https://via.placeholder.com/20/e6ccb2/e6ccb2) | **Tan** | `#e6ccb2` | 230, 204, 178 | Cards, surfaces, secondary background |
| ![#ddb892](https://via.placeholder.com/20/ddb892/ddb892) | **Sand** | `#ddb892` | 221, 184, 146 | Outlines, borders, dividers, inactive states |
| ![#b08968](https://via.placeholder.com/20/b08968/b08968) | **Mocha** | `#b08968` | 176, 137, 104 | Icons, decorative elements, dark-mode accent |
| ![#9c6644](https://via.placeholder.com/20/9c6644/9c6644) | **Sienna** | `#9c6644` | 156, 102, 68 | Accent, interactive highlights, secondary CTA |
| ![#7f5539](https://via.placeholder.com/20/7f5539/7f5539) | **Chocolate** | `#7f5539` | 127, 85, 57 | Primary buttons, headings, app bar |

### Extended Palette (derived for accessibility)

| Swatch | Name | Hex | RGB | Role |
|--------|------|-----|-----|------|
| ![#2c1a0e](https://via.placeholder.com/20/2c1a0e/2c1a0e) | **Espresso** | `#2c1a0e` | 44, 26, 14 | Body text (light theme), dark-mode background |
| ![#362117](https://via.placeholder.com/20/362117/362117) | **Dark Roast** | `#362117` | 54, 33, 23 | Dark-mode card/surface |
| ![#4a3020](https://via.placeholder.com/20/4a3020/4a3020) | **Dark Surface** | `#4a3020` | 74, 48, 32 | Dark-mode elevated surfaces |
| ![#f5efe8](https://via.placeholder.com/20/f5efe8/f5efe8) | **Latte** | `#f5efe8` | 245, 239, 232 | Lightest background, dark-mode text |

**Why extended colors?** The 6-color palette is monochromatic warm brown, which limits contrast between text and background. `Espresso` provides AAA-compliant body text on all light surfaces, while `Latte` ensures readable text in dark mode.

---

## 2. Accessibility — Contrast Matrix

All text/interactive element combinations are WCAG 2.1 verified.

### Light Theme Contrast Ratios

| Text / Foreground | Background | Ratio | WCAG AA (4.5:1) | WCAG AAA (7:1) | Use |
|---|---|---|---|---|---|
| Espresso `#2c1a0e` | Cream `#ede0d4` | **12.86:1** | PASS | PASS | Body text, labels |
| Espresso `#2c1a0e` | Tan `#e6ccb2` | **10.82:1** | PASS | PASS | Body text on cards |
| Espresso `#2c1a0e` | Sand `#ddb892` | **9.00:1** | PASS | PASS | Text on sand surfaces |
| Chocolate `#7f5539` | Cream `#ede0d4` | **4.97:1** | PASS | - | Headings, large text, icons |
| Chocolate `#7f5539` | Tan `#e6ccb2` | **4.18:1** | - | - | Large text only (18px+ bold) |
| Cream `#ede0d4` | Chocolate `#7f5539` | **4.97:1** | PASS | - | Button text on primary |
| White `#ffffff` | Chocolate `#7f5539` | **6.44:1** | PASS | - | Button text (alt) |
| White `#ffffff` | Sienna `#9c6644` | **4.78:1** | PASS | - | Button text on accent |

### Dark Theme Contrast Ratios

| Text / Foreground | Background | Ratio | WCAG AA | WCAG AAA | Use |
|---|---|---|---|---|---|
| Cream `#ede0d4` | Espresso `#2c1a0e` | **12.86:1** | PASS | PASS | Primary text |
| Cream `#ede0d4` | Dark Roast `#362117` | **11.69:1** | PASS | PASS | Text on cards |
| Sand `#ddb892` | Espresso `#2c1a0e` | **9.00:1** | PASS | PASS | Secondary text |
| Sand `#ddb892` | Dark Roast `#362117` | **8.18:1** | PASS | PASS | Secondary text on cards |
| Mocha `#b08968` | Espresso `#2c1a0e` | **5.25:1** | PASS | - | Accent text, icons |
| Mocha `#b08968` | Dark Roast `#362117` | **4.78:1** | PASS | - | Interactive accent |

### Colors NOT Safe for Text

| Combination | Ratio | Verdict |
|---|---|---|
| Mocha `#b08968` on Cream `#ede0d4` | 2.45:1 | FAIL — decorative only |
| Mocha `#b08968` on Tan `#e6ccb2` | 2.06:1 | FAIL — decorative only |
| Sienna `#9c6644` on Cream `#ede0d4` | 3.69:1 | FAIL for body text — large text (18px+ bold) only |
| Sand `#ddb892` on Cream `#ede0d4` | 1.38:1 | FAIL — borders/dividers only |

### Rules

1. **Body text** must always use `Espresso` on light backgrounds (12.86:1 AAA)
2. **Headings** (18px+ bold or 24px+ regular) may use `Chocolate` on `Cream` only (4.97:1 AA)
3. **Mocha** is never used for text — only for decorative elements, icons on dark bg, or progress indicators
4. **Sienna** text is only permitted at 18px+ bold on `Cream` background (3.69:1 AA large)
5. **Buttons** use `Cream`/`White` text on `Chocolate` or `Sienna` backgrounds — never the reverse
6. **Never** use alpha below 0.8 on any text color
7. **Focus rings** and **interactive outlines** must use `Chocolate` at full opacity (not reduced alpha)

---

## 3. Semantic Color Assignments

### Light Theme

| Role | Color | Hex | Notes |
|------|-------|-----|-------|
| **Background** | Cream | `#ede0d4` | Main scaffold, page background |
| **Surface** | Tan | `#e6ccb2` | Cards, bottom sheets, dialogs |
| **Surface Variant** | Sand | `#ddb892` | Input fields, chips, tags |
| **Primary** | Chocolate | `#7f5539` | App bar, primary buttons, nav selected |
| **On Primary** | Latte | `#f5efe8` | Text/icons on primary |
| **Accent / Secondary** | Sienna | `#9c6644` | Secondary buttons, links, FAB |
| **On Accent** | White | `#ffffff` | Text on accent buttons |
| **On Background** | Espresso | `#2c1a0e` | Body text, labels |
| **On Surface** | Espresso | `#2c1a0e` | Card body text |
| **Heading Text** | Chocolate | `#7f5539` | Display, headline styles |
| **Secondary Text** | Chocolate @ 72% | `#7f5539b8` | Subtitles, captions (72% on cream = 3.6:1 AA large) |
| **Outline** | Sand | `#ddb892` | Borders, dividers, input outlines |
| **Outline Strong** | Mocha | `#b08968` | Focused input borders, active outlines |
| **Error** | `#A0442C` | — | Error states (kept from previous system) |
| **Success** | `#6B8E4E` | — | Success/best move indicator |

### Dark Theme

| Role | Color | Hex | Notes |
|------|-------|-----|-------|
| **Background** | Espresso | `#2c1a0e` | Main scaffold |
| **Surface** | Dark Roast | `#362117` | Cards, bottom sheets |
| **Surface Variant** | Dark Surface | `#4a3020` | Elevated containers |
| **Primary** | Mocha | `#b08968` | Buttons, active indicators |
| **On Primary** | Espresso | `#2c1a0e` | Text on primary buttons |
| **Accent** | Sand | `#ddb892` | Links, highlights |
| **On Background** | Cream | `#ede0d4` | Primary text |
| **On Surface** | Cream | `#ede0d4` | Card text |
| **Secondary Text** | Sand | `#ddb892` | Subtitles, captions |
| **Outline** | Chocolate | `#7f5539` | Borders, dividers |
| **Outline Strong** | Mocha | `#b08968` | Focused borders |

---

## 4. Typography

### Type Scale

| Style | Size | Weight | Letter Spacing | Color (Light) | Color (Dark) |
|-------|------|--------|---------------|---------------|--------------|
| **Display Large** | 40px | Bold (700) | 2.0 | Chocolate `#7f5539` | Cream `#ede0d4` |
| **Headline Large** | 24px | SemiBold (600) | 0 | Chocolate `#7f5539` | Cream `#ede0d4` |
| **Headline Medium** | 18px | SemiBold (600) | 0 | Chocolate `#7f5539` | Cream `#ede0d4` |
| **Body Large** | 16px | Regular (400) | 0 | Espresso `#2c1a0e` | Cream `#ede0d4` |
| **Body Medium** | 14px | Regular (400) | 0 | Espresso `#2c1a0e` | Sand `#ddb892` |
| **Body Small** | 12px | Regular (400) | 0.2 | Espresso `#2c1a0e` | Sand `#ddb892` |
| **Label Large** | 14px | Medium (500) | 0.5 | Espresso `#2c1a0e` | Cream `#ede0d4` |
| **Label Small** | 11px | Medium (500) | 0.5 | Chocolate `#7f5539` | Sand `#ddb892` |

### Typography Rules
- Headings (display/headline) use `Chocolate` for warmth — they're large enough to pass AA at 4.97:1
- Body text always uses `Espresso` (AAA on all light surfaces at 12.86:1)
- Never use `Mocha` or `Sand` as standalone text on light backgrounds — insufficient contrast
- Caption/label at 11px must use `Espresso` on light, `Sand` on dark (both AAA)

---

## 5. Component Styles

### Buttons

#### Primary Button (Elevated)
| Property | Light | Dark |
|----------|-------|------|
| Background | Chocolate `#7f5539` | Mocha `#b08968` |
| Text/Icon | Latte `#f5efe8` | Espresso `#2c1a0e` |
| Contrast | 6.14:1 PASS | 5.25:1 PASS |
| Border radius | 10px | 10px |
| Padding | 24h x 14v | 24h x 14v |
| Text style | 15px, SemiBold (600), 0.5 spacing | same |

#### Accent Button (Elevated)
| Property | Light | Dark |
|----------|-------|------|
| Background | Sienna `#9c6644` | Sand `#ddb892` |
| Text/Icon | White `#ffffff` | Espresso `#2c1a0e` |
| Contrast | 4.78:1 PASS | 9.00:1 PASS |

#### Outlined Button
| Property | Light | Dark |
|----------|-------|------|
| Background | Transparent | Transparent |
| Border | Chocolate `#7f5539`, 1.5px, solid | Cream `#ede0d4`, 1.5px |
| Text | Chocolate `#7f5539` | Cream `#ede0d4` |

#### Text Button
| Property | Light | Dark |
|----------|-------|------|
| Text | Sienna `#9c6644` | Mocha `#b08968` |
| Use | Only for large text (14px+) on Cream bg | Any size on dark bg |

### Cards
| Property | Light | Dark |
|----------|-------|------|
| Background | Tan `#e6ccb2` | Dark Roast `#362117` |
| Border | none | none |
| Elevation | 2 | 2 |
| Shadow | `#2c1a0e` at 12% | `#000000` at 25% |
| Border radius | 12px | 12px |
| Body text | Espresso `#2c1a0e` (10.82:1) | Cream `#ede0d4` (11.69:1) |

### App Bar
| Property | Light | Dark |
|----------|-------|------|
| Background | Chocolate `#7f5539` | Espresso `#2c1a0e` |
| Title text | Latte `#f5efe8` | Cream `#ede0d4` |
| Icons | Latte `#f5efe8` | Cream `#ede0d4` |

### Navigation Bar
| Property | Light | Dark |
|----------|-------|------|
| Background | Cream `#ede0d4` | Espresso `#2c1a0e` |
| Selected icon | Chocolate `#7f5539` | Cream `#ede0d4` |
| Unselected icon | Mocha `#b08968` | Chocolate `#7f5539` |
| Indicator | Sienna at 20% | Mocha at 25% |
| Selected label | Chocolate `#7f5539` | Cream `#ede0d4` |
| Unselected label | Mocha `#b08968` | Chocolate `#7f5539` |

### Inputs / Text Fields
| Property | Light | Dark |
|----------|-------|------|
| Fill | Sand `#ddb892` at 30% | Dark Surface `#4a3020` |
| Border (rest) | Sand `#ddb892` | Chocolate `#7f5539` |
| Border (focus) | Chocolate `#7f5539` | Mocha `#b08968` |
| Label | Chocolate `#7f5539` | Sand `#ddb892` |
| Input text | Espresso `#2c1a0e` | Cream `#ede0d4` |
| Placeholder | Mocha `#b08968` | Chocolate `#7f5539` |

### Switches / Toggles
| Property | Light | Dark |
|----------|-------|------|
| Active thumb | Chocolate `#7f5539` | Mocha `#b08968` |
| Active track | Chocolate at 35% | Mocha at 35% |
| Inactive thumb | Sand `#ddb892` | Chocolate `#7f5539` |
| Inactive track | Tan `#e6ccb2` | Dark Surface `#4a3020` |

### Sliders
| Property | Light | Dark |
|----------|-------|------|
| Active | Chocolate `#7f5539` | Mocha `#b08968` |
| Inactive | Sand `#ddb892` at 50% | Mocha at 20% |
| Thumb | Chocolate `#7f5539` | Mocha `#b08968` |

---

## 6. Interaction States

| State | Light Theme Treatment | Dark Theme Treatment |
|-------|----------------------|---------------------|
| **Default** | Base colors as specified | Base colors as specified |
| **Hover** | +8% darker overlay | +8% lighter overlay |
| **Pressed** | +12% darker overlay | +12% lighter overlay |
| **Focused** | 2px Chocolate outline | 2px Mocha outline |
| **Disabled** | 38% opacity | 38% opacity |
| **Selected** | Sienna at 20% fill | Mocha at 25% fill |
| **Error** | `#A0442C` border + text | `#C67B5C` border + text |

### Specific Interaction Examples

**Difficulty Card (selected)**:
- Light: Tan bg with Sienna left border (4px)
- Dark: Dark Roast bg with Mocha left border (4px)

**Checker (selected in-game)**:
- Golden glow ring: Sienna `#9c6644` at 60% opacity, 4px blur
- Scale: 110%

**Button press ripple**:
- Light: Espresso at 8%
- Dark: Cream at 8%

---

## 7. Spacing & Layout

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Inline spacing, icon gaps |
| `sm` | 8px | Between related items |
| `md` | 16px | Section padding, card content |
| `lg` | 24px | Between sections |
| `xl` | 32px | Page margins, major sections |
| `xxl` | 48px | Hero spacing |

### Border Radius
| Element | Radius |
|---------|--------|
| Buttons | 10px |
| Cards | 12px |
| Dialogs | 16px |
| Chips/Tags | 8px |
| Avatars | 50% (circle) |
| Input fields | 8px |

---

## 8. Shadows & Elevation

| Level | Use | Light Theme | Dark Theme |
|-------|-----|-------------|------------|
| 0 | Flat elements | none | none |
| 1 | Cards at rest | `0 1px 3px #2c1a0e1f` | `0 1px 3px #00000040` |
| 2 | Cards, buttons | `0 2px 6px #2c1a0e1f` | `0 2px 6px #00000040` |
| 3 | Floating elements | `0 4px 12px #2c1a0e29` | `0 4px 12px #00000059` |
| 4 | Dialogs, overlays | `0 8px 24px #2c1a0e33` | `0 8px 24px #00000066` |

All shadows use warm tones (Espresso-based) — never pure black in light theme.

---

## 9. Game-Specific Colors

These colors are used within the Flame game rendering and are **separate from the UI palette**. They remain unchanged.

### Checker Colors
| Player | Color | Hex |
|--------|-------|-----|
| Player 1 (Light) | Warm Ivory | `#F0E4C8` |
| Player 2 (Dark) | Rich Ebony | `#2C1810` |

### Board Sets
Board rendering colors remain as defined in the asset brief — they are rendered by Flame, not Material widgets.

### In-Game Semantic Colors
| Role | Hex | Use |
|------|-----|-----|
| Best move hint | `#6B8E4E` | Green indicator |
| Caution | `#D4A03C` | Warning highlight |
| Bad move | `#A0442C` | Error/mistake |
| Info | `#4A7B8C` | Informational |
| Selection glow | `#9c6644` | Replaces old oliveGold for selected pieces |
| Hit effect | `#C67B5C` | Terracotta hit burst |

---

## 10. Dark Mode Strategy

Dark mode inverts the luminance scale while keeping the warm tone:

```
Light:  Cream → Tan → Sand → Mocha → Sienna → Chocolate → Espresso
Dark:   Espresso → Dark Roast → Dark Surface → Chocolate → Mocha → Sand → Cream
```

Key principles:
- Dark backgrounds use `Espresso` and `Dark Roast` — warm near-black, never pure #000000
- Text uses `Cream` (primary) and `Sand` (secondary) — both AAA compliant on dark surfaces
- Accent shifts from `Sienna` (light) to `Mocha` (dark) to maintain contrast
- Game board rendering is unaffected by theme — it has its own lighting system

---

## 11. Implementation Reference

### Flutter Color Constants
```dart
// Core palette
static const cream     = Color(0xFFEDE0D4);
static const tan       = Color(0xFFE6CCB2);
static const sand      = Color(0xFFDDB892);
static const mocha     = Color(0xFFB08968);
static const sienna    = Color(0xFF9C6644);
static const chocolate = Color(0xFF7F5539);

// Extended (derived for accessibility)
static const espresso    = Color(0xFF2C1A0E);
static const darkRoast   = Color(0xFF362117);
static const darkSurface = Color(0xFF4A3020);
static const latte       = Color(0xFFF5EFE8);
```

### ColorScheme Mapping
```dart
// Light
primary:     chocolate
onPrimary:   latte
secondary:   sienna
onSecondary: white
surface:     cream
onSurface:   espresso

// Dark
primary:     mocha
onPrimary:   espresso
secondary:   sand
onSecondary: espresso
surface:     espresso
onSurface:   cream
```

---

*Design System v2.0 — March 2026*
