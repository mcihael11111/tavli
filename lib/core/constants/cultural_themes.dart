import 'package:flutter/material.dart';
import 'tradition.dart';

/// Cultural visual and audio themes for each tradition.
///
/// Defines accent patterns, ambient sounds, and cultural color hints
/// that subtly differentiate the experience per tradition without
/// breaking the core 5-color palette.
abstract final class CulturalThemes {
  /// Get the cultural theme for a tradition.
  static CulturalTheme forTradition(Tradition tradition) =>
      switch (tradition) {
        Tradition.tavli => _tavliTheme,
        Tradition.tavla => _tavlaTheme,
        Tradition.nardy => _nardyTheme,
        Tradition.sheshBesh => _sheshBeshTheme,
      };

  static const _tavliTheme = CulturalTheme(
    accentName: 'Greek Key',
    boardAccentDescription: 'Meander (Greek key) border pattern',
    ambientSoundId: 'ambient_kafeneio',
    ambientSoundDescription: 'Kafeneio chatter, clinking glasses, distant bouzouki',
    culturalColorHint: Color(0xFF1A5276), // Aegean blue
    defaultBoardWood: 'Mahogany & Olive',
    iconMotif: Icons.waves, // Greek wave pattern
    culturalGreeting: '\u039a\u03b1\u03bb\u03ce\u03c2 \u03ae\u03c1\u03b8\u03b5\u03c2!',
    culturalGoodGame: '\u039c\u03c0\u03c1\u03ac\u03b2\u03bf!',
  );

  static const _tavlaTheme = CulturalTheme(
    accentName: 'Ottoman Arabesque',
    boardAccentDescription: 'Interlocking geometric arabesque border',
    ambientSoundId: 'ambient_cayhane',
    ambientSoundDescription: 'Tea house — clinking glasses, quiet conversation, backgammon pieces',
    culturalColorHint: Color(0xFFC0392B), // Ottoman red
    defaultBoardWood: 'Cedar & Crimson',
    iconMotif: Icons.star_half, // Crescent motif
    culturalGreeting: 'Ho\u015f geldin!',
    culturalGoodGame: 'Tebrikler!',
  );

  static const _nardyTheme = CulturalTheme(
    accentName: 'Carved Geometric',
    boardAccentDescription: 'Deep-carved geometric border pattern',
    ambientSoundId: 'ambient_coffeehouse_ru',
    ambientSoundDescription: 'Russian coffeehouse — quiet murmur, chess clocks, tea pouring',
    culturalColorHint: Color(0xFF1A237E), // Deep blue
    defaultBoardWood: 'Birch & Burgundy',
    iconMotif: Icons.diamond, // Geometric diamond
    culturalGreeting: '\u041f\u0440\u0438\u0432\u0435\u0442!',
    culturalGoodGame: '\u041c\u043e\u043b\u043e\u0434\u0435\u0446!',
  );

  static const _sheshBeshTheme = CulturalTheme(
    accentName: 'Mediterranean Tile',
    boardAccentDescription: 'Mosaic tile border pattern',
    ambientSoundId: 'ambient_cafe_med',
    ambientSoundDescription: 'Mediterranean cafe — Arabic coffee, street sounds, distant oud',
    culturalColorHint: Color(0xFF0E6655), // Mediterranean teal
    defaultBoardWood: 'Olive & Sandstone',
    iconMotif: Icons.hexagon, // Tile/mosaic motif
    culturalGreeting: '!Ahlan',
    culturalGoodGame: '!Mabrook',
  );
}

/// A tradition's cultural visual and audio theme.
class CulturalTheme {
  /// Name of the accent pattern.
  final String accentName;

  /// Description of the board border accent pattern.
  final String boardAccentDescription;

  /// Asset ID for the ambient background sound.
  final String ambientSoundId;

  /// Description of the ambient sound.
  final String ambientSoundDescription;

  /// Cultural color hint — used only for tradition cards and accents,
  /// NOT for the core UI palette (which stays at 5 colors).
  final Color culturalColorHint;

  /// Default board wood description.
  final String defaultBoardWood;

  /// Icon representing the cultural motif.
  final IconData iconMotif;

  /// Cultural greeting in native language.
  final String culturalGreeting;

  /// "Good game" in native language.
  final String culturalGoodGame;

  const CulturalTheme({
    required this.accentName,
    required this.boardAccentDescription,
    required this.ambientSoundId,
    required this.ambientSoundDescription,
    required this.culturalColorHint,
    required this.defaultBoardWood,
    required this.iconMotif,
    required this.culturalGreeting,
    required this.culturalGoodGame,
  });
}
