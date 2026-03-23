# Tavli Design System

> Version 2.0 | March 2026 | Flutter + Flame + Material 3
> Supersedes: `../DESIGN_SYSTEM.md`, `../DESIGN_STANDARDS.md`

## Related Documents

- [Accessibility](05_ACCESSIBILITY.md) — WCAG 2.1 compliance, contrast verification
- [Components](02_COMPONENTS.md) — UI component specifications
- [States](03_STATES.md) — Interaction state definitions
- [Copy & Content](04_COPY_CONTENT.md) — Voice, tone, bilingual patterns
- [Uniform Design](06_UNIFORM_DESIGN.md) — Consistency rules, do/don't
- [Material Design 3](07_MATERIAL_DESIGN.md) — M3 mapping and deviations

---

## 1. Design Principles

### Board First
The backgammon board is the hero. Every design decision serves the game experience. UI should frame the board, never compete with it.

### 30-Second Rule
A new player should understand how to start a game within 30 seconds. Reduce friction. Prioritize discoverability over density.

### One-Thumb Playable
All game interactions must be reachable with a single thumb in portrait mode. Critical actions live in the lower two-thirds of the screen.

### Warm, Never Cold
Tavli evokes a Mediterranean evening — warm wood tones, soft shadows, tactile surfaces. No blue-greys, no sterile whites, no sharp edges.

### Premium Simplicity
Fewer elements, better crafted. Every pixel should feel considered. Avoid decoration that doesn't earn its place.

### Respect the Ritual
Backgammon is social. The design should feel like setting up a board between friends — unhurried, inviting, familiar.

---

## 2. Color Palette

### 2.1 Core Colors

The palette consists of exactly **5 core colors**. No additional hues are permitted in UI elements.

| Role | Token | Hex | RGB | HSL | Dart Constant |
|------|-------|-----|-----|-----|---------------|
| Background | `background` | `#D4C2A8` | 212, 194, 168 | 35°, 36%, 75% | `TavliColors.background` |
| Surface | `surface` | `#A67F5B` | 166, 127, 91 | 29°, 32%, 50% | `TavliColors.surface` |
| Primary | `primary` | `#6B4F3A` | 107, 79, 58 | 26°, 30%, 32% | `TavliColors.primary` |
| Text | `text` | `#1A1A1A` | 26, 26, 26 | 0°, 0%, 10% | `TavliColors.text` |
| Light | `light` | `#F3F0EB` | 243, 240, 235 | 38°, 24%, 94% | `TavliColors.light` |

> **Note:** The scaffold/page background uses `surface` (`#A67F5B`), not `background`. The `background` color (`#D4C2A8`) is used for elevated cards (e.g. profile cards, onboarding selection cards) that need to stand out from the page.

### 2.2 State Shades

State shades are derived mathematically from core colors. They exist **only** for interaction states (hover, active/pressed, focused, disabled). They are not independent design tokens — they are functions of the core palette.

**Derivation formula:**
- Hover: blend toward black/white by 8%
- Active/Pressed: blend toward black/white by 12%
- Focused: core color + 2px focus ring in `primary`
- Disabled: 38% opacity over parent background

| Core Color | Hover | Active/Pressed | Dart Hover | Dart Active |
|------------|-------|----------------|------------|-------------|
| Background `#D4C2A8` | `#C4B298` (darken 8%) | `#BAA88E` (darken 12%) | `TavliColors.backgroundHover` | `TavliColors.backgroundActive` |
| Surface `#A67F5B` | `#997353` (darken 8%) | `#906A4A` (darken 12%) | `TavliColors.surfaceHover` | `TavliColors.surfaceActive` |
| Primary `#6B4F3A` | `#7A5E49` (lighten 8%) | `#846852` (lighten 12%) | `TavliColors.primaryHover` | `TavliColors.primaryActive` |
| Light `#F3F0EB` | `#E9E6E1` (darken 4%) | `#DFDCD7` (darken 8%) | `TavliColors.lightHover` | `TavliColors.lightActive` |
| Text `#1A1A1A` | `#333333` (lighten 8%) | `#4D4D4D` (lighten 12%) | `TavliColors.textHover` | `TavliColors.textActive` |

All state shades are verified for WCAG contrast compliance. See [Accessibility > Contrast Matrix](05_ACCESSIBILITY.md#contrast-matrix).

### 2.3 Semantic Colors

Semantic colors communicate status. They are used sparingly and always paired with an icon or shape (never color alone).

| Role | Hex | RGB | On Background | On Light | Dart Constant |
|------|-----|-----|---------------|----------|---------------|
| Error | `#A0442C` | 160, 68, 44 | 3.6:1 (large only) | 5.1:1 AA | `TavliColors.error` |
| Success | `#6B8E4E` | 107, 142, 78 | 2.8:1 (with icon) | 3.9:1 (large) | `TavliColors.success` |
| Warning | `#D4A03C` | 212, 160, 60 | 2.2:1 (with icon) | 3.0:1 (large) | `TavliColors.warning` |
| Info | `#4A7B8C` | 74, 123, 140 | 3.0:1 (large only) | 4.2:1 AA | `TavliColors.info` |

> **Accessibility note:** Semantic colors have moderate contrast and must always be accompanied by a secondary indicator (icon, shape, or label). They must never be the sole means of communicating information. See [Accessibility > Color-Independent Information](05_ACCESSIBILITY.md#color-independent-information).

### 2.4 Game Board Colors

Game board colors are a **separate system** from the UI palette. They are used exclusively within the Flame game canvas and do not appear in Flutter UI widgets.

| Set | Colors | Usage |
|-----|--------|-------|
| Mahogany & Olive | `#8B4513`, `#808000`, `#DEB887` | Default board set |
| Teal | `#008080`, `#2F4F4F`, `#B0C4DE` | Premium board set |
| Walnut & Navy | `#5C4033`, `#000080`, `#F5DEB3` | Premium board set |
| Checker Light | `#F0E4C8` | Light checker pieces |
| Checker Dark | `#2C1810` | Dark checker pieces |

### 2.5 Color Usage Rules

**Permitted combinations (foreground on background):**

| Context | Foreground | Background | Ratio |
|---------|------------|------------|-------|
| Body text on page (surface bg) | `light` | `surface` | 2.9:1 Large text/icons |
| Body text on elevated card | `primary` | `background` | 3.5:1 Large text |
| Headings on page (surface bg) | `light` | `surface` | 2.9:1 Large text |
| Headings on page (surface bg) | `text` | `surface` | 5.0:1 AA |
| Card title/body text | `light` | `primary` | 5.6:1 AA |
| Card title (on background card) | `primary` | `background` | 3.5:1 Large only |
| Button text (filled) | `light` | `primary` | 5.6:1 AA |
| Button text (outline) | `primary` | `background` | 3.5:1 Large only |
| Nav bar icon (active) | `light` | `primary` | 5.6:1 AA |
| Nav bar icon (inactive) | `primary` | `background` | 3.5:1 Large/icon |

**Low-contrast combinations (use with care):**

| Foreground | Background | Ratio | Permitted Usage |
|------------|------------|-------|----------------|
| `light` | `surface` | 2.9:1 | Large text (>=18px) and icons only |
| `background` | `surface` | 1.8:1 | Decorative elements only |
| `surface` | `background` | 1.8:1 | Decorative elements only |

> **Rule:** The page background is `surface` (`#A67F5B`). Text on surface should use `light` (`#F3F0EB`) for headings/large text or `text` (`#1A1A1A`) for body text requiring AAA contrast. Cards elevated from the page use `background` (`#D4C2A8`) fill with `primary` (`#6B4F3A`) text.

### 2.6 Dark Mode Strategy

Dark mode inverts luminance relationships while preserving the warm palette identity.

| Role | Light Mode | Dark Mode | Dart Constant |
|------|------------|-----------|---------------|
| Background | `#D4C2A8` | `#1A1A1A` | `TavliColors.background` / `.backgroundDark` |
| Surface | `#A67F5B` | `#3D2E20` | `TavliColors.surface` / `.surfaceDark` |
| Primary | `#6B4F3A` | `#D4C2A8` | `TavliColors.primary` / `.primaryDark` |
| Text | `#1A1A1A` | `#F3F0EB` | `TavliColors.text` / `.textDark` |
| Light | `#F3F0EB` | `#2C2218` | `TavliColors.light` / `.lightDark` |

All dark mode pairings must independently meet WCAG AA contrast requirements.

---

## 3. Typography

### 3.1 Type Scale — Minor Second (1.067)

The typographic scale uses a **Minor Second** ratio of **1.067**, producing subtle, harmonious size increments. Base size: **16px**.

**Rationale:** The Minor Second creates a tight, refined scale ideal for a game UI where content density is low and each size step should feel deliberate rather than dramatic. It avoids the visual "jumps" of larger ratios (Major Third, Perfect Fourth) that suit content-heavy applications.

### 3.2 Full Scale Table

| Step | Calculation | Raw px | Rounded | Name | Usage |
|------|-------------|--------|---------|------|-------|
| -6 | 16 / 1.067⁶ | 10.87 | **11** | Micro | Label small, captions |
| -5 | 16 / 1.067⁵ | 11.60 | **12** | Tiny | Body small, metadata |
| -4 | 16 / 1.067⁴ | 12.38 | **12** | Caption | Secondary labels |
| -3 | 16 / 1.067³ | 13.21 | **13** | Small | Tertiary text |
| -2 | 16 / 1.067² | 14.10 | **14** | Body Small | Supporting body copy |
| -1 | 16 / 1.067¹ | 15.04 | **15** | Body Medium | — (not used in M3 map) |
| **0** | **16** | **16.00** | **16** | **Body (base)** | **Primary body text** |
| +1 | 16 × 1.067¹ | 17.07 | **17** | Body Large | — (not used in M3 map) |
| +2 | 16 × 1.067² | 18.22 | **18** | Subtitle | Subtitles, title large |
| +3 | 16 × 1.067³ | 19.44 | **19** | Title Small | — |
| +4 | 16 × 1.067⁴ | 20.74 | **21** | Title | Headline medium |
| +5 | 16 × 1.067⁵ | 22.13 | **22** | Title Large | — |
| +6 | 16 × 1.067⁶ | 23.62 | **24** | Headline | Headline large |
| +7 | 16 × 1.067⁷ | 25.20 | **25** | Headline Lg | — |
| +8 | 16 × 1.067⁸ | 26.89 | **27** | Display Sm | Display small |
| +9 | 16 × 1.067⁹ | 28.69 | **29** | Display | — |
| +10 | 16 × 1.067¹⁰ | 30.62 | **31** | Display Med | Display medium |
| +15 | 16 × 1.067¹⁵ | 41.55 | **42** | Display Lg | Display large, hero text |

### 3.3 Material 3 TextTheme Mapping

| M3 Style | Scale Step | Size | Weight | Line Height | Letter Spacing | Light Color | Dark Color |
|-----------|-----------|------|--------|-------------|----------------|-------------|------------|
| `displayLarge` | +15 | 42 | w700 | 52 | -0.84 | `text` | `light` |
| `displayMedium` | +10 | 31 | w700 | 40 | -0.62 | `text` | `light` |
| `displaySmall` | +8 | 27 | w600 | 36 | -0.27 | `text` | `light` |
| `headlineLarge` | +6 | 24 | w600 | 32 | -0.48 | `primary` | `primaryDark` |
| `headlineMedium` | +4 | 21 | w600 | 28 | -0.42 | `primary` | `primaryDark` |
| `headlineSmall` | +2 | 18 | w600 | 24 | 0 | `primary` | `primaryDark` |
| `titleLarge` | +2 | 18 | w500 | 24 | 0 | `text` | `light` |
| `titleMedium` | 0 | 16 | w500 | 22 | 0.15 | `text` | `light` |
| `titleSmall` | -2 | 14 | w500 | 20 | 0.1 | `text` | `light` |
| `bodyLarge` | 0 | 16 | w400 | 24 | 0 | `text` | `light` |
| `bodyMedium` | -2 | 14 | w400 | 20 | 0.25 | `text` | `light` |
| `bodySmall` | -4 | 12 | w400 | 16 | 0.4 | `text` | `light` |
| `labelLarge` | -2 | 14 | w500 | 20 | 0.1 | `text` | `light` |
| `labelMedium` | -4 | 12 | w500 | 16 | 0.5 | `text` | `light` |
| `labelSmall` | -6 | 11 | w500 | 16 | 0.5 | `primary` | `primaryDark` |

### 3.4 Typography Rules

1. **Font family:** Poppins (primary), Noto Sans (Greek fallback)
2. **Minimum text size:** 11px (`labelSmall`). No text smaller than 11px anywhere in the app.
3. **Headings** (`headline*`, `display*`) use `primary` color in light mode to create warm hierarchy
4. **Body text** uses `text` color for maximum readability
5. **Line height:** Always ≥ 1.4× font size for body text, ≥ 1.2× for headings
6. **Letter spacing:** Negative for large display text (tighter), positive for small labels (looser)
7. **No underlines** except for hyperlinks
8. **Text scaling:** All text must remain readable at 200% system scale. See [Accessibility > Text Scaling](05_ACCESSIBILITY.md#text-scaling).

### 3.5 Font Loading

```dart
// pubspec.yaml
fonts:
  - family: Poppins
    fonts:
      - asset: assets/fonts/Poppins-Regular.ttf
        weight: 400
      - asset: assets/fonts/Poppins-Medium.ttf
        weight: 500
      - asset: assets/fonts/Poppins-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Poppins-Bold.ttf
        weight: 700
  - family: NotoSans
    fonts:
      - asset: assets/fonts/NotoSans-Regular.ttf
        weight: 400
```

---

## 4. Spacing System

### 4.1 Spacing Scale

All spacing uses a **4px base unit**. Only these values are permitted:

| Token | Value | Dart Constant | Usage |
|-------|-------|---------------|-------|
| `xxs` | 4px | `TavliSpacing.xxs` | Icon-to-label gap, tight padding |
| `xs` | 8px | `TavliSpacing.xs` | Inline element spacing, chip padding |
| `sm` | 12px | `TavliSpacing.sm` | Related element spacing, card internal gaps |
| `md` | 16px | `TavliSpacing.md` | Standard padding, section spacing |
| `lg` | 24px | `TavliSpacing.lg` | Section separation, card-to-card gap |
| `xl` | 32px | `TavliSpacing.xl` | Major section breaks |
| `xxl` | 48px | `TavliSpacing.xxl` | Page-level padding, hero spacing |

### 4.2 Usage Guidelines

- **Page horizontal padding:** `md` (16px) — consistent across all screens
- **Card internal padding:** `md` (16px)
- **Gap between stacked cards:** `sm` (12px) or `xs` (8px)
- **Section title to content:** `sm` (12px)
- **Between unrelated sections:** `lg` (24px) or `xl` (32px)
- **Bottom safe area padding:** `lg` (24px) minimum

### 4.3 Implementation

```dart
abstract final class TavliSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

> **Uniform Design:** Never use arbitrary spacing values. If a design requires 20px, round to 16px or 24px. See [Uniform Design > Spacing Rhythm](06_UNIFORM_DESIGN.md#spacing-rhythm).

---

## 5. Border Radius

| Token | Value | Usage | Dart Constant |
|-------|-------|-------|---------------|
| `xs` | 4px | Subtle rounding (dividers, thin elements) | `TavliRadius.xs` |
| `sm` | 8px | Buttons, inputs, small containers | `TavliRadius.sm` |
| `md` | 12px | Dialogs, example boxes, chips | `TavliRadius.md` |
| `lg` | 16px | Cards, list items, tabs, bottom sheets | `TavliRadius.lg` |
| `xl` | 24px | Large containers, modals | `TavliRadius.xl` |
| `full` | 100px | Avatars, pills, bottom nav bar, slider thumb | `TavliRadius.full` |

### Implementation

```dart
abstract final class TavliRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;

  static final BorderRadius xsBorder = BorderRadius.circular(xs);
  static final BorderRadius smBorder = BorderRadius.circular(sm);
  static final BorderRadius mdBorder = BorderRadius.circular(md);
  static final BorderRadius lgBorder = BorderRadius.circular(lg);
  static final BorderRadius xlBorder = BorderRadius.circular(xl);
  static final BorderRadius fullBorder = BorderRadius.circular(full);
}
```

---

## 6. Elevation & Shadows

Shadows use warm-tinted black to maintain the Mediterranean aesthetic. Pure `#000000` shadows are prohibited.

| Level | Name | Shadow Value | Usage | Dart Constant |
|-------|------|-------------|-------|---------------|
| 0 | None | — | Flat elements | — |
| 1 | XSmall | `0 1px 2px rgba(0,0,0,0.3)` | Cards, list items, buttons | `TavliShadows.xsmall` |
| 2 | Small | `0 0 8px rgba(0,0,0,0.1)` | Slider thumb, tooltips | `TavliShadows.small` |
| 3 | Medium | `0 4px 16px rgba(0,0,0,0.15)` | Dialogs, bottom sheets | `TavliShadows.medium` |
| 4 | Large | `0 0 48px rgba(0,0,0,0.2)` | Board carousel cards, hero images | `TavliShadows.large` |

### Implementation

```dart
abstract final class TavliShadows {
  static const xsmall = [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000))];
  static const small = [BoxShadow(blurRadius: 8, color: Color(0x1A000000))];
  static const medium = [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x26000000))];
  static const large = [BoxShadow(blurRadius: 48, color: Color(0x33000000))];
}
```

---

## 7. Iconography

| Property | Value |
|----------|-------|
| Default size | 24dp |
| Touch target wrapping | 48dp minimum (see [Accessibility](05_ACCESSIBILITY.md#touch-targets)) |
| Color (on background) | `primary` (`#6B4F3A`) |
| Color (on surface/primary) | `light` (`#F3F0EB`) |
| Color (disabled) | `primary` at 38% opacity |
| Style | Outlined, 1.5px stroke, rounded joins |

Icons must always be wrapped in a minimum 48dp touch target when interactive.

---

## 8. Accessibility Summary

This section provides a quick reference. For the full specification, see [Accessibility](05_ACCESSIBILITY.md).

- **Minimum contrast:** 4.5:1 for normal text, 3:1 for large text (≥18px regular or ≥14px bold) and UI components
- **Touch targets:** 48dp minimum in all directions
- **Color independence:** Never communicate information through color alone
- **Text scaling:** Support up to 200% without content clipping
- **Motion:** Respect `MediaQuery.disableAnimations`; provide reduced-motion alternatives
- **Screen readers:** Semantic labels on all interactive elements

---

## 9. Material Design 3 Alignment Summary

Tavli uses Material 3 as its structural foundation while applying a custom warm aesthetic. See [Material Design 3](07_MATERIAL_DESIGN.md) for the complete mapping.

**Key deviations from standard M3:**
- Static warm palette instead of dynamic color (HCT generation)
- Minor Second type scale instead of M3 Major Second
- Custom warm-tinted shadows instead of M3 neutral elevation
- Fully rounded bottom navigation bar instead of standard M3 NavigationBar

---

## 10. Implementation Reference

### Color Constants

```dart
// lib/core/constants/colors.dart
abstract final class TavliColors {
  // Core palette
  static const Color background = Color(0xFFD4C2A8);
  static const Color surface    = Color(0xFFA67F5B);
  static const Color primary    = Color(0xFF6B4F3A);
  static const Color text       = Color(0xFF1A1A1A);
  static const Color light      = Color(0xFFF3F0EB);

  // State shades
  static const Color backgroundHover  = Color(0xFFC4B298);
  static const Color backgroundActive = Color(0xFFBAA88E);
  static const Color surfaceHover     = Color(0xFF997353);
  static const Color surfaceActive    = Color(0xFF906A4A);
  static const Color primaryHover     = Color(0xFF7A5E49);
  static const Color primaryActive    = Color(0xFF846852);
  static const Color lightHover       = Color(0xFFE9E6E1);
  static const Color lightActive      = Color(0xFFDFDCD7);
  static const Color textHover        = Color(0xFF333333);
  static const Color textActive       = Color(0xFF4D4D4D);

  // Semantic
  static const Color error   = Color(0xFFA0442C);
  static const Color success = Color(0xFF6B8E4E);
  static const Color warning = Color(0xFFD4A03C);
  static const Color info    = Color(0xFF4A7B8C);
}
```

### Theme Construction

```dart
// lib/app/theme.dart
static ThemeData get light => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: TavliColors.primary,
    onPrimary: TavliColors.light,
    secondary: TavliColors.surface,
    onSecondary: TavliColors.text,
    surface: TavliColors.surface,
    onSurface: TavliColors.light,
    error: TavliColors.error,
    onError: TavliColors.light,
  ),
  scaffoldBackgroundColor: TavliColors.surface,
  textTheme: _textTheme,
  // ... component themes
);
```

See [Material Design 3 > ThemeData Reference](07_MATERIAL_DESIGN.md#themedata-reference) for the complete annotated theme construction.
