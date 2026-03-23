/// Move quality classification for teaching mode highlights.
enum MoveQuality {
  /// Top equity move (within 0.01 of best). Gold glow.
  best,

  /// Good move (within 0.03 equity of best). Silver glow.
  good,

  /// Acceptable move (within 0.08 equity). Bronze glow.
  acceptable,

  /// Legal but poor move (>0.08 equity loss). No highlight color.
  poor,
}
