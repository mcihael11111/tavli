/// One of the two players.
enum Side {
  one,
  two;

  /// The other side.
  Side get opponent => this == one ? two : one;

  String toJson() => name;

  /// Throws [ArgumentError] for an unknown name.
  static Side fromJson(String s) => Side.values.byName(s);
}
