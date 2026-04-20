import '../../features/game/domain/engine/variants/game_variant.dart';

/// The cultural tradition a player identifies with.
///
/// Each tradition groups a set of game variants, provides culturally
/// appropriate personalities, and defines language/aesthetic context.
enum Tradition {
  tavli,
  tavla,
  nardy,
  sheshBesh,
  tawla;

  /// English display name.
  String get displayName => switch (this) {
        tavli => 'Tavli',
        tavla => 'Tavla',
        nardy => 'Nardy',
        sheshBesh => 'Shesh Besh',
        tawla => 'Tawla',
      };

  /// Name in native script.
  String get nativeName => switch (this) {
        tavli => 'Τάβλι',
        tavla => 'Tavla',
        nardy => 'Нарды',
        sheshBesh => 'שש בש',
        tawla => 'طاولة',
      };

  /// Region label.
  String get regionLabel => switch (this) {
        tavli => 'Greece',
        tavla => 'Turkey',
        nardy => 'Russia & Caucasus',
        sheshBesh => 'Israel',
        tawla => 'Arab World',
      };

  /// Flag emoji. Empty string for traditions that span multiple countries.
  String get flagEmoji => switch (this) {
        tavli => '🇬🇷',
        tavla => '🇹🇷',
        nardy => '🇷🇺',
        sheshBesh => '🇮🇱',
        tawla => '',
      };

  /// The game variants belonging to this tradition.
  List<GameVariant> get variants => switch (this) {
        tavli => [GameVariant.portes, GameVariant.plakoto, GameVariant.fevga],
        tavla => [GameVariant.tavla, GameVariant.tapa, GameVariant.moultezim, GameVariant.gulBara],
        nardy => [GameVariant.longNard, GameVariant.shortNard],
        sheshBesh => [GameVariant.sheshBesh, GameVariant.mahbusa],
        tawla => [GameVariant.tawla31, GameVariant.mahbusaArab],
      };

  /// The default variant for this tradition.
  GameVariant get defaultVariant => variants.first;

  /// Human-readable language name.
  String get languageName => switch (this) {
        tavli => 'Greek',
        tavla => 'Turkish',
        nardy => 'Russian',
        sheshBesh => 'Hebrew',
        tawla => 'Arabic',
      };

  /// The language code used for cultural flavor mixing.
  String get flavorLanguageCode => switch (this) {
        tavli => 'el',
        tavla => 'tr',
        nardy => 'ru',
        sheshBesh => 'he',
        tawla => 'ar',
      };

  /// Serialize to string for storage.
  String toStorageKey() => name;

  /// Deserialize from storage string.
  static Tradition fromStorageKey(String? key) {
    if (key == null) return tavli;
    return Tradition.values.where((t) => t.name == key).firstOrNull ?? tavli;
  }
}

/// The fundamental mechanic family a variant belongs to.
enum MechanicFamily {
  /// Standard backgammon: hitting sends opponent to bar.
  hitting,

  /// Plakoto-family: landing on single opponent pins it in place.
  pinning,

  /// Fevga/Nard-family: no capture, single checker blocks point.
  running;

  String get displayName => switch (this) {
        hitting => 'Hitting Game',
        pinning => 'Pinning Game',
        running => 'Running Game',
      };
}

/// Pool type for online matchmaking.
enum PoolType {
  /// Match within the same tradition + variant.
  tradition,

  /// Match across traditions by mechanic family.
  international;
}
