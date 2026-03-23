/// Base class for tavli game variants.
///
/// Portes (standard backgammon) is the MVP variant.
/// Plakoto and Fevga are V1.5+ additions.
enum GameVariant {
  /// Standard backgammon — the MVP game mode.
  portes,

  /// Plakoto (Πλακωτό) — pinning variant.
  plakoto,

  /// Fevga (Φεύγα) — running variant.
  fevga,
}
