/// States in the game state machine.
enum GamePhase {
  /// Both players roll to determine who goes first.
  waitingForFirstRoll,

  /// Active player's turn begins (may offer double).
  playerTurnStart,

  /// Waiting for opponent to accept/refuse double.
  doubleOffered,

  /// Active player rolls dice.
  rollingDice,

  /// Active player must enter checkers from bar first.
  enteringFromBar,

  /// Active player moves checkers based on roll.
  movingCheckers,

  /// Active player bearing off checkers.
  bearingOff,

  /// Active player picks up dice, turn passes.
  turnComplete,

  /// Winner determined.
  gameOver,
}
