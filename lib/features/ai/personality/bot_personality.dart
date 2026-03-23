/// Bot personality presets — each defines a unique opponent character.
enum BotPersonality {
  /// Μιχαήλ — The kafeneio owner (original default).
  mikhail,

  /// Θείος Σπύρος — Extreme Greek, crazy uncle.
  spyrosUncle,

  /// Ξάδερφος Νίκος — Young Greek cousin.
  cousinNikos,

  /// Παππούς Γιώργος — Wholesome grandfather.
  pappoosYiorgos,

  /// Θεία Ελένη — Sassy Greek aunt.
  theiaEleni;

  /// English display name.
  String get displayName => switch (this) {
        mikhail => 'Mikhail',
        spyrosUncle => 'Uncle Spyros',
        cousinNikos => 'Cousin Nikos',
        pappoosYiorgos => 'Grandpa Giorgos',
        theiaEleni => 'Aunt Eleni',
      };

  /// Greek display name.
  String get greekName => switch (this) {
        mikhail => 'Μιχαήλ',
        spyrosUncle => 'Θείος Σπύρος',
        cousinNikos => 'Ξάδερφος Νίκος',
        pappoosYiorgos => 'Παππούς Γιώργος',
        theiaEleni => 'Θεία Ελένη',
      };

  /// Single character for the avatar circle.
  String get avatarInitial => switch (this) {
        mikhail => 'Μ',
        spyrosUncle => 'Σ',
        cousinNikos => 'Ν',
        pappoosYiorgos => 'Γ',
        theiaEleni => 'Ε',
      };

  /// Short personality description (English).
  String get subtitle => switch (this) {
        mikhail => 'The kafeneio owner. Warm but competitive.',
        spyrosUncle => 'Over-the-top dramatic. Slams the table.',
        cousinNikos => 'Casual and chill. Loves to tease.',
        pappoosYiorgos => 'Wise and patient. Tells stories.',
        theiaEleni => 'Sassy and proud. Feeds you while playing.',
      };

  /// Short personality description (Greek).
  String get greekSubtitle => switch (this) {
        mikhail => 'Ο καφετζής. Ζεστός αλλά ανταγωνιστικός.',
        spyrosUncle => 'Δραματικός στο φουλ. Χτυπάει το τραπέζι.',
        cousinNikos => 'Χαλαρός και cool. Σε πειράζει συνέχεια.',
        pappoosYiorgos => 'Σοφός και υπομονετικός. Λέει ιστορίες.',
        theiaEleni => 'Σπαρταριστή και περήφανη. Σε ταΐζει ενώ παίζεις.',
      };

  /// Welcome greeting shown in onboarding.
  String get onboardingGreeting => switch (this) {
        mikhail => "I'm Mikhail. Welcome to Tavli.",
        spyrosUncle => 'ΩΩΩΠΑ! Uncle Spyros is here! Let\'s PLAY!',
        cousinNikos => 'Γεια ρε! I\'m Nikos. Ready to lose?',
        pappoosYiorgos =>
          'Καλώς ήρθες, παιδί μου. Sit. Let me teach you.',
        theiaEleni =>
          'Ah, finally someone to play with! Sit, I made κουλουράκια.',
      };

  /// Serialize to string for SharedPreferences.
  String toStorageKey() => name;

  /// Deserialize from SharedPreferences string.
  static BotPersonality fromStorageKey(String? key) {
    if (key == null) return mikhail;
    return BotPersonality.values.where((p) => p.name == key).firstOrNull ??
        mikhail;
  }
}
