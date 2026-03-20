import 'dart:ui';

/// Tavli color palette — warm, modern, accessibility-checked.
///
/// Core palette: 6 warm browns from the brand identity.
/// Extended palette: derived shades for WCAG AA/AAA compliance.
/// Game colors: separate set for Flame board rendering.
abstract final class TavliColors {
  // ── Core Palette ───────────────────────────────────────────
  /// Lightest — primary background (light theme).
  static const cream = Color(0xFFEDE0D4);

  /// Light warm — cards, surfaces, secondary background.
  static const tan = Color(0xFFE6CCB2);

  /// Medium — outlines, borders, dividers, inactive states.
  static const sand = Color(0xFFDDB892);

  /// Warm brown — decorative elements, icons (dark mode), accent.
  static const mocha = Color(0xFFB08968);

  /// Dark accent — interactive highlights, secondary CTA.
  static const sienna = Color(0xFF9C6644);

  /// Darkest core — primary buttons, app bar, heading text.
  static const chocolate = Color(0xFF7F5539);

  // ── Extended Palette (accessibility-derived) ───────────────
  /// Near-black warm — body text (light theme), dark-mode background.
  /// Contrast: 12.86:1 on cream (AAA), 10.82:1 on tan (AAA).
  static const espresso = Color(0xFF2C1A0E);

  /// Dark warm — dark-mode card/surface.
  static const darkRoast = Color(0xFF362117);

  /// Dark warm elevated — dark-mode elevated surfaces.
  static const darkSurface = Color(0xFF4A3020);

  /// Near-white warm — text on dark primary buttons.
  static const latte = Color(0xFFF5EFE8);

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

  // Board Set 1: Μαόνι (Mahogany & Olive Wood)
  static const mahoganyLight = Color(0xFFA0522D);
  static const mahoganyDark = Color(0xFF8B4513);
  static const oliveWoodLight = Color(0xFFC8B560);
  static const oliveWoodDark = Color(0xFF9A8B3C);

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

  // ── Legacy aliases (for backward compatibility in game screens) ─
  static const aegeanBlue = Color(0xFF1A5C5C);
  static const warmLamplight = Color(0xFFFFF5E0);
  static const successBestMove = success;
  static const warningCaution = warning;
  static const errorBadMove = error;
  static const kafeneioBrown = chocolate;
  static const parchment = cream;
  static const oliveGold = sienna;
  static const marbleWhite = latte;
  static const terracotta = hitEffect;
  static const nightWood = espresso;
  static const brightText = cream;
  static const dimText = sand;
  static const fadedParchment = darkRoast;
}
