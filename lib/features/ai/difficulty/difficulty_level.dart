/// AI difficulty levels matching Mikhail's persona evolution.
enum DifficultyLevel {
  /// Εύκολο — Friendly uncle, 0-ply, 30% noise.
  easy,

  /// Εύκολο με Βοήθεια — Patient teacher, same AI as easy + teaching.
  easyWithHelp,

  /// Μέτριο — Competitive regular, 1-ply, 10% noise.
  medium,

  /// Δύσκολο — Intense veteran, 2-ply, 5% noise.
  hard,

  /// Παππούς — The legendary grandfather, 3-ply, 2% noise.
  pappous;

  String get greekName => switch (this) {
        easy => 'Εύκολο',
        easyWithHelp => 'Εύκολο με Βοήθεια',
        medium => 'Μέτριο',
        hard => 'Δύσκολο',
        pappous => 'Παππούς',
      };

  String get englishName => switch (this) {
        easy => 'Easy',
        easyWithHelp => 'Easy + Help',
        medium => 'Medium',
        hard => 'Hard',
        pappous => 'Extra Hard',
      };

  String get description => switch (this) {
        easy => 'A warm, friendly game. Your opponent goes easy on you.',
        easyWithHelp => 'Learn as you play. Your opponent teaches you strategy.',
        medium => 'A real match. Your opponent plays to win.',
        hard => 'No mercy. Your opponent brings their A-game.',
        pappous => 'The legendary difficulty. 60 years of mastery.',
      };

  /// Search depth in plies.
  int get searchDepth => switch (this) {
        easy => 0,
        easyWithHelp => 0,
        medium => 1,
        hard => 2,
        pappous => 3,
      };

  /// Noise factor added to evaluations (0.0 = perfect, 1.0 = random).
  double get noiseFactor => switch (this) {
        easy => 0.15,
        easyWithHelp => 0.15,
        medium => 0.10,
        hard => 0.05,
        pappous => 0.02,
      };

  /// What fraction of top moves to consider.
  double get topMoveFraction => switch (this) {
        easy => 0.50,
        easyWithHelp => 0.50,
        medium => 0.20,
        hard => 0.05,
        pappous => 0.02,
      };

  /// Whether teaching mode is active.
  bool get isTeaching => this == easyWithHelp;

  /// Whether this level uses the doubling cube.
  bool get usesDoublingCube => switch (this) {
        easy => false,
        easyWithHelp => false,
        medium => true,
        hard => true,
        pappous => true,
      };

  /// Unlock condition description.
  String? get unlockCondition => switch (this) {
        easy => null,
        easyWithHelp => null,
        medium => 'Win 3 games on Easy',
        hard => 'Win 5 games on Medium or 3 in a row',
        pappous => 'Win 5 games on Hard or 3 in a row',
      };
}
