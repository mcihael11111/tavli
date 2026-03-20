# Tavli Architecture & Code Patterns

## Overview

This document defines the code architecture, state management patterns, and conventions used throughout the Tavli codebase. All contributors must follow these patterns for consistency.

---

## 1. Project Architecture

Tavli follows **Clean Architecture** with feature-based organization:

```
lib/
├── app/            → App shell (MaterialApp, router, theme)
├── core/           → Shared constants, utilities, errors
├── features/       → Feature modules (vertical slices)
│   ├── game/       → Game engine, board, gameplay
│   ├── ai/         → AI player, difficulty, Mikhail dialogue
│   ├── multiplayer/→ Online rooms, matchmaking, rating
│   ├── social/     → Invitations, friend list
│   ├── profile/    → Player stats, rank
│   ├── customization/ → Board/checker/dice selection
│   ├── tutorial/   → Interactive lessons
│   └── settings/   → App preferences
├── flame_game/     → Flame engine components
└── shared/         → Cross-feature widgets, services, providers
```

### Feature Module Structure

Each feature follows a 3-layer pattern:

```
feature/
├── data/           → Models, repositories, data sources
│   ├── models/     → Data classes (immutable, with Equatable)
│   └── repositories/ → Data access abstraction
├── domain/         → Business logic, engine, use cases
│   ├── entities/   → Domain objects
│   ├── engine/     → Core logic (e.g., game rules)
│   └── usecases/   → Single-responsibility operations
└── presentation/   → UI screens, widgets, state
    ├── screens/    → Full-screen widgets
    ├── widgets/    → Reusable UI components
    └── providers/  → Riverpod state management
```

---

## 2. State Management — Riverpod

### Provider Types

| Type | When to Use | Example |
|------|------------|---------|
| `Provider` | Static/computed values | `routerProvider`, `audioServiceProvider` |
| `StateProvider` | Simple mutable state | `themeProvider`, `selectedBoardProvider` |
| `StateNotifierProvider` | Complex state with logic | `gameProvider` (GameNotifier) |
| `FutureProvider` | Async one-shot data | Loading user profile from storage |
| `StreamProvider` | Real-time data | Firestore game room stream |

### Naming Conventions

```dart
// Providers: noun + "Provider"
final gameProvider = StateNotifierProvider<GameNotifier, GameState>(...);
final themeProvider = StateProvider<ThemeMode>(...);

// Notifiers: feature + "Notifier"
class GameNotifier extends StateNotifier<GameState> { ... }
```

### State Updates

Always create new state objects — never mutate:

```dart
// ✅ Correct
state = state.copyWith(board: newBoard, phase: GamePhase.movingCheckers);

// ❌ Wrong — never mutate state directly
state.board = newBoard;
```

---

## 3. Data Models

### Immutability

All data models are immutable. Use `Equatable` for value equality:

```dart
class BoardState extends Equatable {
  final List<int> points;
  final int bar1;
  // ...

  const BoardState({required this.points, this.bar1 = 0});

  BoardState copyWith({List<int>? points, int? bar1}) {
    return BoardState(
      points: points ?? List.of(this.points),
      bar1: bar1 ?? this.bar1,
    );
  }

  @override
  List<Object?> get props => [points, bar1, ...];
}
```

### Sentinel Values

| Value | Constant | Meaning |
|-------|----------|---------|
| `-1` | `GameConstants.barIndex` | Checker is on the bar |
| `-2` | `GameConstants.bearOffIndex` | Checker is borne off |
| `null` | — | Doubling cube is centered (no owner) |

### Board Representation

- `points[0..23]`: Positive = Player 1 checkers, Negative = Player 2 checkers
- Player 1 moves from high indices → low (bears off from 0-5)
- Player 2 moves from low indices → high (bears off from 18-23)

---

## 4. Game Engine Pattern

The engine is **pure functional** — no side effects, no state:

```dart
class GameEngine {
  // Validate: BoardState + Move → bool
  bool isMoveValid(BoardState state, Move move);

  // Apply: BoardState + Move → new BoardState
  BoardState applyMove(BoardState state, Move move);

  // Query: BoardState → result
  bool isGameOver(BoardState state);
  GameResult? getResult(BoardState state);
}
```

**Key invariant**: The engine never modifies state. It returns new state objects. This makes it testable, predictable, and safe.

### Move Generation Flow

```
DiceRoll + BoardState
    → MoveGenerator.generateAllLegalTurns()
        → List<Turn> (all legal move combinations)
            → Filter by mandatory play rules
                → Deduplicate by final board state
```

---

## 5. Flame Integration Pattern

### Flutter ↔ Flame Communication

```
Flutter (Riverpod)          Flame (TavliGame)
      │                          │
      │── updateBoardState() ──→ │  State flows IN
      │── showHighlights() ───→  │
      │── showDice() ─────────→  │
      │                          │
      │←── onCheckerTapped() ──  │  Events flow OUT
      │←── onDestinationTapped() │
      │←── onDiceRollRequested() │
```

- **State flows in**: Flutter calls methods on TavliGame to update visuals
- **Events flow out**: Flame fires callbacks when user interacts with the board
- **Never**: Flame reads Riverpod state directly or Flutter renders board elements

### BoardLayout

All position calculations are centralized in `BoardLayout`:

```dart
final layout = BoardLayout(gameSize);
Vector2 pos = layout.checkerPosition(pointIndex, stackPosition, player);
Vector2 base = layout.pointBasePosition(pointIndex);
```

---

## 6. AI Pattern

### Move Selection Pipeline

```
1. Generate all legal turns (MoveGenerator)
2. Evaluate each resulting position (BoardEvaluator)
3. Optional: N-ply search (look ahead N opponent turns)
4. Add difficulty-based noise
5. Filter to top N% of moves
6. Weighted random selection from candidates
```

### Difficulty Scaling

Difficulty is parameterized, not branched:

```dart
enum DifficultyLevel {
  easy;    // 0-ply, 30% noise, top 50%
  medium;  // 1-ply, 10% noise, top 20%
  hard;    // 2-ply, 5% noise, top 5%
  pappous; // 3-ply, 2% noise, top 2%
}
```

---

## 7. Navigation Pattern

### go_router Structure

```
/splash           → SplashScreen (no nav bar)
/home             → HomeScreen (with nav bar via ShellRoute)
/profile          → ProfileScreen (with nav bar)
/customize        → CustomizationScreen (with nav bar)
/settings         → SettingsScreen (with nav bar)
/difficulty       → DifficultyScreen (full screen, no nav bar)
/game             → GameScreen (full screen, landscape)
/victory          → VictoryScreen (full screen)
/tutorial         → TutorialScreen (full screen)
```

### Route Data Passing

Use `extra` for complex objects, query params for simple values:

```dart
// Passing difficulty to game screen
context.go('/game', extra: DifficultyLevel.hard);

// Receiving in route builder
final difficulty = state.extra as DifficultyLevel? ?? DifficultyLevel.easy;
```

---

## 8. Error Handling

### Game Engine
- Assertions for invariants (debug only)
- Return empty lists for "no legal moves" (not exceptions)
- Return null for "game not over" queries

### UI
- Show error states with recovery actions
- Never show raw error messages to users
- Log errors to Crashlytics in production

### Network (Multiplayer)
- Optimistic UI: apply move locally, validate server-side
- On server rejection: revert to last known-good state
- Reconnection: 60-second window, resume from server state

---

## 9. Testing Conventions

### File Naming
```
test/unit/board_state_test.dart
test/unit/move_generator_test.dart
test/widget/home_screen_test.dart
test/integration/game_flow_test.dart
```

### Test Structure
```dart
group('ClassName — scenario', () {
  test('specific behavior', () {
    // Arrange
    final state = BoardState.initial();
    // Act
    final result = engine.applyMove(state, move);
    // Assert
    expect(result.points[5], 6);
  });
});
```

### Coverage Targets
- Game engine: 95%+
- AI engine: 80%+
- UI screens: widget tests for key interactions
- Integration: complete game flow (start → play → finish)

---

## 10. Code Style

- Follow Effective Dart guidelines
- Use `dart analyze` with zero warnings before every commit
- Prefer `const` constructors where possible
- Use named parameters for 3+ arguments
- Document all public APIs with `///` dartdoc comments
- No commented-out code in committed files
- Commit messages: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`
