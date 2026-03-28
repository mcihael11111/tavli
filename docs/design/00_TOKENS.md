# Token Registry

> **This is the single source of truth for every design token value in Tavli.**
> All other design docs reference tokens **by name only** — never by raw hex/px values.
> When a token value changes, update it HERE and nowhere else.
>
> Version 2.0 | March 2026 | Flutter + Flame + Material 3

---

## 1. Color Tokens

### 1.1 Core Palette (5 colors — no additional UI hues permitted)

| Token Name | Dart Constant | Hex | Role |
|------------|---------------|-----|------|
| `background` | `TavliColors.background` | `#D4C2A8` | Elevated cards, profile cards, nav bar, dialogs |
| `surface` | `TavliColors.surface` | `#A67F5B` | Page/scaffold background, input fills |
| `primary` | `TavliColors.primary` | `#6B4F3A` | Standard card fill, buttons, borders, icons |
| `text` | `TavliColors.text` | `#1A1A1A` | Body text, high-contrast headings |
| `light` | `TavliColors.light` | `#F3F0EB` | Text on primary, button labels, nav icons (active) |

> **Page background** uses `surface` (`#A67F5B`), not `background`.
> **Elevated cards** use `background` (`#D4C2A8`) to stand out from the page.

### 1.2 State Shades (derived from core — not independent tokens)

| Base Color | Hover (8% shift) | Active/Pressed (12% shift) |
|------------|-------------------|---------------------------|
| `background` `#D4C2A8` | `backgroundHover` `#C4B298` | `backgroundActive` `#BAA88E` |
| `surface` `#A67F5B` | `surfaceHover` `#997353` | `surfaceActive` `#906A4A` |
| `primary` `#6B4F3A` | `primaryHover` `#7A5E49` | `primaryActive` `#846852` |
| `light` `#F3F0EB` | `lightHover` `#E9E6E1` | `lightActive` `#DFDCD7` |
| `text` `#1A1A1A` | `textHover` `#333333` | `textActive` `#4D4D4D` |

**Derivation rules:**
- Light colors → darken by N%
- Dark colors (primary, text) → lighten by N%
- Light color hover uses 4% darken (exception)

### 1.3 Semantic Colors (always paired with icon/shape — never color alone)

| Token Name | Dart Constant | Hex |
|------------|---------------|-----|
| `error` | `TavliColors.error` | `#A0442C` |
| `success` | `TavliColors.success` | `#6B8E4E` |
| `warning` | `TavliColors.warning` | `#D4A03C` |
| `info` | `TavliColors.info` | `#4A7B8C` |

### 1.4 Dark Mode Colors

| Token Name | Light Mode | Dark Mode | Dart Constant (Dark) |
|------------|------------|-----------|---------------------|
| `background` | `#D4C2A8` | `#1A1A1A` | `TavliColors.backgroundDark` |
| `surface` | `#A67F5B` | `#3D2E20` | `TavliColors.surfaceDark` |
| `primary` | `#6B4F3A` | `#D4C2A8` | `TavliColors.primaryDark` |
| `text` | `#1A1A1A` | `#F3F0EB` | `TavliColors.textDark` |
| `light` | `#F3F0EB` | `#2C2218` | `TavliColors.lightDark` |

### 1.5 Game Board Colors (separate system — Flame canvas only, not UI)

| Token | Hex | Usage |
|-------|-----|-------|
| Mahogany & Olive | `#8B4513`, `#808000`, `#DEB887` | Default board |
| Teal | `#008080`, `#2F4F4F`, `#B0C4DE` | Premium board |
| Walnut & Navy | `#5C4033`, `#000080`, `#F5DEB3` | Premium board |
| Checker Light | `#F0E4C8` | Light checkers |
| Checker Dark | `#2C1810` | Dark checkers |

---

## 2. Typography Tokens

### 2.1 Font Families (Dual-Font System)

| Role | Family | Dart | Used For |
|------|--------|------|----------|
| Serif (headings) | Playfair Display | `TavliTheme.serifFamily` | `displayLarge`–`titleMedium` (via Google Fonts) |
| Sans-serif (body) | Poppins | `fontFamily: 'Poppins'` | `titleSmall`, `bodyLarge`–`labelSmall`, button text |
| Greek fallback | Noto Sans | `fontFamilyFallback: ['NotoSans']` | Greek character rendering |

> Playfair Display gives headings a premium, classical feel. Poppins handles body/label text for readability.
> Button `textStyle` in the theme uses `serifFamily` for filled, outlined, elevated, and text buttons.

### 2.2 Type Scale (Minor Second ratio 1.067, base 16px)

| M3 Style | Size | Weight | Line Height | Letter Spacing | Font | Usage |
|-----------|------|--------|-------------|----------------|------|-------|
| `displayLarge` | 42px | w700 | 52px (1.24) | -0.84 | Serif | Hero text |
| `displayMedium` | 31px | w700 | 40px (1.29) | -0.62 | Serif | Display |
| `displaySmall` | 27px | w600 | 36px (1.33) | -0.27 | Serif | Display small |
| `headlineLarge` | 24px | w600 | 32px (1.33) | -0.48 | Serif | Screen titles |
| `headlineMedium` | 21px | w600 | 28px (1.33) | -0.42 | Serif | Dialog titles |
| `headlineSmall` | 18px | w600 | 24px (1.33) | 0 | Serif | Section headings |
| `titleLarge` | 18px | w500 | 24px (1.33) | 0 | Serif | Card titles |
| `titleMedium` | 16px | w500 | 22px (1.38) | 0.15 | Serif | Subtitles |
| `titleSmall` | 14px | w500 | 20px (1.43) | 0.1 | Sans | Section headers |
| `bodyLarge` | 16px | w400 | 24px (1.5) | 0 | Sans | Body text |
| `bodyMedium` | 14px | w400 | 20px (1.43) | 0.25 | Sans | Supporting text |
| `bodySmall` | 12px | w400 | 16px (1.33) | 0.4 | Sans | Metadata |
| `labelLarge` | 14px | w500 | 20px (1.43) | 0.1 | Sans | Button labels |
| `labelMedium` | 12px | w500 | 16px (1.33) | 0.5 | Sans | Small labels |
| `labelSmall` | 11px | w500 | 16px (1.45) | 0.5 | Sans | Captions (minimum) |

> **Serif** = Playfair Display (via `TavliTheme.serifFamily`). **Sans** = Poppins.

### 2.3 Typography Color Rules

| Content Type | Light Mode Color | Dark Mode Color |
|-------------|-----------------|-----------------|
| Display/Headlines | `primary` | `primaryDark` |
| Titles/Body/Labels | `text` | `light` |
| `labelSmall` | `primary` | `primaryDark` |

### 2.4 Typography Rules

- **Minimum text size:** 11px (`labelSmall`)
- **No inline font sizes** — always use `Theme.of(context).textTheme.*`
- **Permitted sizes only:** 11, 12, 14, 16, 18, 21, 24, 27, 31, 42
- **Headings:** `primary` color in light mode
- **Body text:** `text` color for maximum readability
- **Line height:** ≥ 1.4× for body, ≥ 1.2× for headings
- **No underlines** except hyperlinks

---

## 3. Spacing Tokens (4px base grid)

| Token | Value | Dart Constant | Usage |
|-------|-------|---------------|-------|
| `xxs` | 4px | `TavliSpacing.xxs` | Icon-to-label gap, tight padding |
| `xs` | 8px | `TavliSpacing.xs` | Inline element spacing, chip padding |
| `sm` | 12px | `TavliSpacing.sm` | Related element spacing, card internal gaps |
| `md` | 16px | `TavliSpacing.md` | Standard padding, page horizontal padding |
| `lg` | 24px | `TavliSpacing.lg` | Section separation, dialog padding |
| `xl` | 32px | `TavliSpacing.xl` | Major section breaks |
| `xxl` | 48px | `TavliSpacing.xxl` | Page-level padding, hero spacing |

**No other spacing values are permitted.** If a design needs 20px, use 16px or 24px.

**One exception:** 10px gap between stacked list cards (from Figma). Documented in Components. Must not be used elsewhere.

### 3.1 Standard Spacing Application

| Context | Value |
|---------|-------|
| Page horizontal padding | `md` (16px) — all screens |
| Card internal padding | `md` (16px) — all cards |
| Gap between stacked cards | 10px (custom, list items only) |
| Gap between side-by-side cards | `sm` (12px) |
| Section title to content | `sm` (12px) |
| Between unrelated sections | `lg` (24px) or `xl` (32px) |
| Bottom safe area | `lg` (24px) minimum |
| Button horizontal spacing | `sm` (12px) |

---

## 4. Border Radius Tokens

| Token | Value | Dart Constant | Usage |
|-------|-------|---------------|-------|
| `xs` | 4px | `TavliRadius.xs` | Subtle rounding (dividers) |
| `sm` | 8px | `TavliRadius.sm` | Buttons, inputs |
| `md` | 12px | `TavliRadius.md` | Dialogs, example boxes, chips |
| `lg` | 16px | `TavliRadius.lg` | Cards, list items, tabs, bottom sheets |
| `xl` | 24px | `TavliRadius.xl` | Large containers, modals |
| `full` | 100px | `TavliRadius.full` | Avatars, pills, bottom nav, slider thumb |

---

## 4b. Gradient Tokens

Gradient backgrounds create the depth-layered aesthetic. All screens use `GradientScaffold` instead of flat `Scaffold`.

| Token | Type | Colors | Dart Constant | Usage |
|-------|------|--------|---------------|-------|
| `warm-scaffold` | Linear (top→bottom) | `surface` → `primary` | `TavliGradients.warmScaffold` | Default scaffold background for all screens |
| `deep-scaffold` | Radial (center-top→edges) | `surface` → `primary` | `TavliGradients.deepScaffold` | Splash, sign-in, matchmaking — focused/centered layouts |
| `warm-scaffold-dark` | Linear (top→bottom) | `surfaceDark` → `backgroundDark` | `TavliGradients.warmScaffoldDark` | Dark mode default |
| `deep-scaffold-dark` | Radial (center-top→edges) | `surfaceDark` → `backgroundDark` | `TavliGradients.deepScaffoldDark` | Dark mode focused layouts |

## 4c. Module (Translucent Card) Tokens

Content Modules are the signature translucent cards that float on gradient backgrounds, creating the 3-layer depth system.

| Token | Value | Dart Constant | Usage |
|-------|-------|---------------|-------|
| `module-fill` | `background` at 12% alpha | `TavliModule.fill` | Module card background |
| `module-border` | `primary` at 40% alpha, 1px | `TavliModule.border` | Module card border |
| `module-radius` | `lg` (16px) | `TavliRadius.lg` | Module card corner rounding |
| `module-shadow` | None | — | Depth comes from transparency on gradient, not shadows |
| `module-fill-dark` | `primaryDark` at 12% alpha | `TavliModule.fillDark` | Dark mode module fill |
| `module-border-dark` | `primaryDark` at 40% alpha | `TavliModule.borderDark` | Dark mode module border |

> **Depth Model (3 layers):**
> 1. **Back**: Gradient scaffold (`warm-scaffold` or `deep-scaffold`)
> 2. **Mid**: Translucent Content Modules (12% alpha fill, subtle border)
> 3. **Front**: Solid elements inside modules (avatars, action buttons, icons)

---

## 5. Elevation & Shadow Tokens

Shadows use warm-tinted black. Pure `#000000` shadows are prohibited.

| Token | Shadow Value | Dart Constant | Usage |
|-------|-------------|---------------|-------|
| None | — | — | Flat elements |
| `xsmall` | `0 1px 2px rgba(0,0,0,0.3)` | `TavliShadows.xsmall` | Cards, list items, buttons |
| `small` | `0 0 8px rgba(0,0,0,0.1)` | `TavliShadows.small` | Slider thumb, tooltips |
| `medium` | `0 4px 16px rgba(0,0,0,0.15)` | `TavliShadows.medium` | Dialogs, bottom sheets |
| `large` | `0 0 48px rgba(0,0,0,0.2)` | `TavliShadows.large` | Carousel cards, hero images |

---

## 6. Iconography Tokens

| Property | Value |
|----------|-------|
| Default size | 24dp |
| Card leading icon | 32–40dp |
| Touch target | 48dp minimum (always) |
| Color (on background/surface) | `primary` |
| Color (on primary) | `light` |
| Color (disabled) | `primary` at 38% opacity |
| Style | Outlined, 1.5px stroke, rounded joins |

---

## 7. State Formula Tokens

These formulas are **universal** — they apply to every component without exception.

| State | Treatment | Duration | Curve |
|-------|-----------|----------|-------|
| Hover | 8% darken (light) / lighten (dark) | 50ms in, 100ms out | `easeIn` / `easeOut` |
| Pressed | 12% darken/lighten + scale 0.98 | 100ms in, 150ms out | `easeIn` / `easeOut` |
| Focused | 2px `primary` ring, 2px offset | Instant | — |
| Disabled | 38% opacity, no pointer events | 200ms | `easeInOut` |
| Selected | Distinct fill/border per component | 150ms | `easeInOut` |
| Error | `error` border + icon + message | 200ms | `easeInOut` |

### 7.1 Animation Duration Tokens

| Context | Duration |
|---------|----------|
| State transitions | 50–200ms (per state table above) |
| Page transitions | 300ms |
| Component enter/exit | 250ms |
| Checker movement | 400ms |
| Dice roll | 800ms |
| Standard curve | `easeInOut` |
| Enter curve | `easeOutCubic` |

---

## 8. Contrast Reference (Quick Lookup)

### Safe Combinations

| Foreground | Background | Ratio | Level |
|------------|------------|-------|-------|
| `text` on `light` | `#1A1A1A` / `#F3F0EB` | 15.0:1 | AAA |
| `text` on `background` | `#1A1A1A` / `#D4C2A8` | 9.5:1 | AAA |
| `text` on `surface` | `#1A1A1A` / `#A67F5B` | 5.0:1 | AA |
| `light` on `primary` | `#F3F0EB` / `#6B4F3A` | 5.6:1 | AA |
| `light` on `text` | `#F3F0EB` / `#1A1A1A` | 15.0:1 | AAA |
| `primary` on `light` | `#6B4F3A` / `#F3F0EB` | 5.6:1 | AA |
| `primary` on `background` | `#6B4F3A` / `#D4C2A8` | 3.5:1 | Large text only |

### Forbidden Combinations (fail all WCAG text criteria)

| Foreground | Background | Ratio |
|------------|------------|-------|
| `light` on `background` | `#F3F0EB` / `#D4C2A8` | 1.5:1 |
| `background` on `surface` | `#D4C2A8` / `#A67F5B` | 1.8:1 |
| `surface` on `primary` | `#A67F5B` / `#6B4F3A` | 2.0:1 |
| `primary` on `text` | `#6B4F3A` / `#1A1A1A` | 2.7:1 |

---

## 9. Dart Implementation Reference

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

  // Dark mode
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surfaceDark    = Color(0xFF3D2E20);
  static const Color primaryDark    = Color(0xFFD4C2A8);
  static const Color textDark       = Color(0xFFF3F0EB);
  static const Color lightDark      = Color(0xFF2C2218);
}

abstract final class TavliSpacing {
  static const double xxs = 4;
  static const double xs  = 8;
  static const double sm  = 12;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

abstract final class TavliRadius {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 100;

  static final BorderRadius xsBorder   = BorderRadius.circular(xs);
  static final BorderRadius smBorder   = BorderRadius.circular(sm);
  static final BorderRadius mdBorder   = BorderRadius.circular(md);
  static final BorderRadius lgBorder   = BorderRadius.circular(lg);
  static final BorderRadius xlBorder   = BorderRadius.circular(xl);
  static final BorderRadius fullBorder = BorderRadius.circular(full);
}

abstract final class TavliShadows {
  static const xsmall = [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000))];
  static const small  = [BoxShadow(blurRadius: 8, color: Color(0x1A000000))];
  static const medium = [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x26000000))];
  static const large  = [BoxShadow(blurRadius: 48, color: Color(0x33000000))];
}
```
