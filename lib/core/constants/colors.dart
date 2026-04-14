import 'package:flutter/painting.dart';

/// Tavli color palette — 5 core colors with WCAG-compliant state shades.
///
/// Design system: docs/design/01_DESIGN_SYSTEM.md
/// Accessibility: docs/design/05_ACCESSIBILITY.md
abstract final class TavliColors {
  // ── Core Palette (5 colors) ──────────────────────────────────
  /// Warm beige — page backgrounds, scaffold.
  static const background = Color(0xFFD4C2A8);

  /// Warm brown — cards, elevated surfaces, slider tracks.
  static const surface = Color(0xFFA67F5B);

  /// Dark brown — primary buttons, borders, interactive emphasis.
  static const primary = Color(0xFF6B4F3A);

  /// Near-black — body text on light backgrounds.
  static const text = Color(0xFF1A1A1A);

  /// Off-white — text on dark surfaces, button labels on primary.
  static const light = Color(0xFFF3F0EB);

  // ── State Shades (derived from core, for interaction states only) ─
  /// Background hover: darken 8%.
  static const backgroundHover = Color(0xFFC4B298);

  /// Background active/pressed: darken 12%.
  static const backgroundActive = Color(0xFFBAA88E);

  /// Surface hover: darken 8%.
  static const surfaceHover = Color(0xFF997353);

  /// Surface active/pressed: darken 12%.
  static const surfaceActive = Color(0xFF906A4A);

  /// Primary hover: lighten 8%.
  static const primaryHover = Color(0xFF7A5E49);

  /// Primary active/pressed: lighten 12%.
  static const primaryActive = Color(0xFF846852);

  /// Light hover: darken 4%.
  static const lightHover = Color(0xFFE9E6E1);

  /// Light active/pressed: darken 8%.
  static const lightActive = Color(0xFFDFDCD7);

  /// Text hover: lighten 8%.
  static const textHover = Color(0xFF333333);

  /// Text active/pressed: lighten 12%.
  static const textActive = Color(0xFF4D4D4D);

  // ── Dark Mode Core ───────────────────────────────────────────
  /// Dark mode background.
  static const backgroundDark = Color(0xFF1A1A1A);

  /// Dark mode surface.
  static const surfaceDark = Color(0xFF3D2E20);

  /// Dark mode primary (inverted to warm beige).
  static const primaryDark = Color(0xFFD4C2A8);

  /// Dark mode text.
  static const textDark = Color(0xFFF3F0EB);

  /// Dark mode light (inverted to dark brown).
  static const lightDark = Color(0xFF2C2218);

  // ── Semantic Colors (shared across themes) ─────────────────
  static const success = Color(0xFF6B8E4E);
  static const warning = Color(0xFFD4A03C);
  static const error = Color(0xFFA0442C);
  static const info = Color(0xFF4A7B8C);

  // ── Game Board Colors (Flame rendering only) ───────────────
  // These are NOT affected by app theme — the game has its own lighting.

  /// Checker colors.
  static const checkerLight = Color(0xFFF0E4C8);
  static const checkerDark = Color(0xFF2C1810);

  /// Selection / highlight.
  static const selectionGlow = Color(0xFF9C6644);
  static const hitEffect = Color(0xFFC67B5C);

  /// Bot thinking background — cool blue-grey (contrast with warm primary).
  static const botThinkingBg = Color(0xFF4A6B7C);

  /// Bot thinking banner background.
  static const botThinkingBanner = Color(0xFF3D5A6E);

  /// Move highlight — bright green for valid destinations.
  static const moveHighlight = Color(0xFF4CAF50);

  /// Move highlight for hit destinations — red-tinted.
  static const moveHighlightHit = Color(0xFFE57373);

  /// Selection green — for selected checker ring.
  static const selectionGreen = Color(0xFF66BB6A);

  /// Complete button — green.
  static const completeButton = Color(0xFF4CAF50);

  // Board Set 1: Μαόνι (Mahogany & Olive Wood)
  static const mahoganyLight = Color(0xFFB86B3A);
  static const mahoganyDark = Color(0xFF8B4513);
  static const oliveWoodLight = Color(0xFFD4C06A);
  static const oliveWoodDark = Color(0xFF7A6B2C);

  // Board Set 2: Σμαραγδί (Mahogany & Teal)
  static const tealFrameLight = Color(0xFF8B4226);
  static const tealFrameDark = Color(0xFF6F3024);
  static const tealPointLight = Color(0xFF1A5C5C);
  static const tealPointDark = Color(0xFF0D4F4F);
  static const paleMaple = Color(0xFFDEC8A0);
  static const paleMapleDark = Color(0xFFC4AD7C);

  // Board Set 3: Νυχτερινό (Dark Walnut & Navy)
  static const darkWalnutLight = Color(0xFF3C2415);
  static const darkWalnutDark = Color(0xFF2A1A0E);
  static const navyLight = Color(0xFF2C3E50);
  static const navyDark = Color(0xFF1C2833);
  static const copperLight = Color(0xFFB87333);
  static const copperDark = Color(0xFFA0522D);
  static const ashLight = Color(0xFFC4B28E);
  static const ashDark = Color(0xFFA89970);

  // ── Disabled / Muted Semantic Colors ─────────────────────────
  /// Muted text/icon on primary backgrounds — WCAG AA compliant (≥4.5:1).
  /// Use instead of light.withOpacity(0.5–0.7) on primary/surface.
  static const disabledOnPrimary = Color(0xFFCDC4BB);

  /// Dark-mode counterpart for disabled text on primary.
  static const disabledOnPrimaryDark = Color(0xFF5C4A3A);

  /// De-emphasized text on light backgrounds (background/light) — WCAG AA.
  static const mutedOnSurface = Color(0xFF4A3A2D);

  /// Dark-mode counterpart for muted text on surface.
  static const mutedOnSurfaceDark = Color(0xFFB8A898);

  // ── Legacy Aliases (backward compatibility for existing code) ──
  static const cream = light;
  static const tan = Color(0xFFE6CCB2);
  static const sand = Color(0xFFDDB892);
  static const mocha = Color(0xFFB08968);
  static const sienna = Color(0xFF9C6644);
  static const chocolate = primary;
  static const espresso = text;
  static const darkRoast = surfaceDark;
  static const darkSurface = Color(0xFF4A3020);
  static const latte = light;
  static const aegeanBlue = Color(0xFF1A5C5C);
  static const warmLamplight = Color(0xFFFFF5E0);
  static const successBestMove = success;
  static const warningCaution = warning;
  static const errorBadMove = error;
  static const kafeneioBrown = primary;
  static const parchment = light;
  static const oliveGold = sienna;
  static const marbleWhite = light;
  static const terracotta = hitEffect;
  static const nightWood = text;
  static const brightText = light;
  static const dimText = sand;
  static const fadedParchment = surfaceDark;
}

/// Spacing tokens — 4px base unit.
/// Design system: docs/design/01_DESIGN_SYSTEM.md#spacing-system
abstract final class TavliSpacing {
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius tokens.
/// Design system: docs/design/01_DESIGN_SYSTEM.md#border-radius
abstract final class TavliRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}

/// Shadow/elevation tokens.
/// Design system: docs/design/01_DESIGN_SYSTEM.md#elevation--shadows
abstract final class TavliShadows {
  static const xsmall = [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000))];
  static const small = [BoxShadow(blurRadius: 8, color: Color(0x1A000000))];
  static const medium = [BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x26000000))];
  static const large = [BoxShadow(blurRadius: 48, color: Color(0x33000000))];
}

/// Gradient tokens for depth-layered backgrounds.
abstract final class TavliGradients {
  /// Warm scaffold gradient — linear top-to-bottom, surface → primary.
  static const warmScaffold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [TavliColors.surface, TavliColors.primary],
  );

  /// Deep scaffold gradient — radial, lighter center-top → darker edges.
  static const deepScaffold = RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.2,
    colors: [TavliColors.surface, TavliColors.primary],
  );

  /// Dark mode warm scaffold.
  static const warmScaffoldDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [TavliColors.surfaceDark, TavliColors.backgroundDark],
  );

  /// Dark mode deep scaffold.
  static const deepScaffoldDark = RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.2,
    colors: [TavliColors.surfaceDark, TavliColors.backgroundDark],
  );
}

/// Semantic module tokens — translucent card decoration.
abstract final class TavliModule {
  /// Module background fill (12% alpha of background on gradient).
  static final Color fill = TavliColors.background.withValues(alpha: 0.12);

  /// Module border (40% alpha of primary).
  static final Color border = TavliColors.primary.withValues(alpha: 0.4);

  /// Module fill — dark mode.
  static final Color fillDark = TavliColors.primaryDark.withValues(alpha: 0.12);

  /// Module border — dark mode.
  static final Color borderDark = TavliColors.primaryDark.withValues(alpha: 0.4);

  /// Complete BoxDecoration for a module card.
  static BoxDecoration decoration({bool isDark = false}) => BoxDecoration(
    color: isDark ? fillDark : fill,
    borderRadius: BorderRadius.circular(TavliRadius.lg),
    border: Border.all(color: isDark ? borderDark : border),
  );
}
