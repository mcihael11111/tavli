import 'package:flutter/material.dart';
import '../data/models/lesson.dart';

/// The 6 universal foundation lessons that apply to all backgammon variants.
const foundationSection = LessonSection(
  id: 'foundation',
  title: 'Foundations',
  type: LessonSectionType.foundation,
  lessons: _foundationLessons,
);

const _foundationLessons = [
  Lesson(
    id: 'foundation_board',
    title: 'The Board',
    icon: Icons.grid_on,
    botDialogue:
        'Welcome! This is a backgammon board. '
        '24 points, like the hours of the day. Each player has 15 checkers.',
    setup:
        '24 triangles called "points," grouped into 4 quadrants of 6. '
        'A central ridge called the "bar" separates home and outer boards.',
    coreMechanic: [
      'Player\'s Home Board (points 1–6) — where you bear off',
      'Player\'s Outer Board (points 7–12)',
      'Opponent\'s Outer Board (points 13–18)',
      'Opponent\'s Home Board (points 19–24)',
      'You move from high-numbered points to low-numbered points',
    ],
    specialRules: [],
    scoring: [],
    strategyTips: [],
    uniquePoints: [
      'The board has been unchanged for over 5,000 years',
      'The 24 points mirror the 24 hours of the day in ancient symbolism',
    ],
  ),
  Lesson(
    id: 'foundation_moving',
    title: 'Moving Checkers',
    icon: Icons.casino,
    botDialogue:
        'You roll two dice! Each die is a separate move. '
        'Roll a 5 and a 3? Move one checker 5 and another 3. '
        'Or move ONE checker 5 then 3 — but the middle point must be open!',
    coreMechanic: [
      'Each die is a separate move — use them on one or two checkers',
      'A combined move must have the intermediate point open',
      'Doubles = 4 moves (e.g., 6-6 means four sixes)',
      'Can only land on "open" points (fewer than 2 opponent checkers)',
    ],
    specialRules: [
      'You MUST use both dice if legally possible',
      'If only one die can be played, you must play the larger one',
      'If neither die works, your turn is forfeited',
      'Doubles: play as many of the 4 moves as possible',
    ],
    scoring: [],
    strategyTips: [
      'Look for moves that use both dice before committing to one',
      'Remember: the larger die must be played if only one works',
    ],
    uniquePoints: [],
  ),
  Lesson(
    id: 'foundation_hitting',
    title: 'Hitting & The Bar',
    icon: Icons.gavel,
    botDialogue:
        'A checker alone on a point? That\'s a "blot" — vulnerable! '
        'Land on it and send it to the bar. '
        'Then your opponent must re-enter before doing anything else.',
    coreMechanic: [
      'A single checker on a point is called a "blot"',
      'Landing on a blot sends it to the bar (center ridge)',
      'A hit checker must re-enter through the opponent\'s home board',
      'Roll a number matching an open point in opponent\'s home (19–24) to re-enter',
    ],
    specialRules: [
      'If all entry points are blocked, you lose your entire turn',
      'You must enter ALL checkers from the bar before moving others',
      'After entering, remaining dice must be played normally',
    ],
    scoring: [],
    strategyTips: [
      'Avoid leaving blots in areas your opponent can reach',
      'Blocking all 6 home board points traps opponent on the bar',
    ],
    uniquePoints: [
      'Not all variants use hitting — pinning and running games have different mechanics',
    ],
  ),
  Lesson(
    id: 'foundation_bearing_off',
    title: 'Bearing Off',
    icon: Icons.emoji_events,
    botDialogue:
        'When ALL your checkers are in your home board, '
        'you can start taking them off. This is bearing off. '
        'First to remove all 15 wins!',
    coreMechanic: [
      'All 15 checkers must be in your home board (points 1–6) first',
      'Roll a number matching the point to bear off that checker',
      'If no checker is on that point, you must move a checker from a higher point',
      'If no higher point is occupied, bear off from the highest occupied point',
    ],
    specialRules: [
      'If a checker is hit during bearing off, it must re-enter first',
      'You are not required to bear off — you can make a normal move instead',
    ],
    scoring: [],
    strategyTips: [
      'Keep your checkers spread evenly to bear off efficiently',
      'Avoid leaving gaps that waste dice rolls',
    ],
    uniquePoints: [],
  ),
  Lesson(
    id: 'foundation_strategy',
    title: 'Strategy Basics',
    icon: Icons.lightbulb_outline,
    botDialogue:
        'Making "points" — two or more checkers together — is the key. '
        'They block your opponent. Build a wall, a prime! '
        'And never leave blots if you can avoid it.',
    coreMechanic: [
      'A "point" (door): 2+ checkers protect each other and block the opponent',
      'A "prime": consecutive blocked points — traps opponent behind',
      'An "anchor": a point held in opponent\'s home board — safety net',
      'Pip count: total number of pips to bear off — lower is ahead in the race',
    ],
    specialRules: [],
    scoring: [],
    strategyTips: [
      'Make points early — especially the 5-point and 4-point',
      'Build primes (3–6 consecutive points) to trap opponent checkers',
      'Keep an anchor in opponent\'s home board when behind',
      'Count pips to decide: race if ahead, block if behind',
      'Diversify your builders — don\'t stack too many on one point',
    ],
    uniquePoints: [],
  ),
  Lesson(
    id: 'foundation_doubling_cube',
    title: 'The Doubling Cube',
    icon: Icons.casino,
    botDialogue:
        'The cube! This is where real backgammon gets serious. '
        'You can offer to double the stakes before you roll. '
        'Your opponent must accept — or surrender!',
    coreMechanic: [
      'Starts at 1× (center of board, available to both players)',
      'Before rolling, you may offer to double the stakes',
      'Opponent accepts (game at 2×, they own the cube) or declines (loses at current stakes)',
      'Only the cube owner can re-double (to 4×, 8×, up to 64×)',
    ],
    specialRules: [
      'Jacoby rule: gammon/backgammon only count if cube was used',
      'Beaver: immediately re-double after accepting (retaining ownership)',
      'Not all variants use the doubling cube — mainly Short Nard',
    ],
    scoring: [
      'Single: 1× cube value',
      'Gammon (opponent bore off nothing): 2× cube value',
      'Backgammon (opponent on bar/in your home): 3× cube value',
    ],
    strategyTips: [
      'Double when you estimate 65–70% winning chance',
      'Accept a double if you have at least 25% winning chance',
      'The cube adds a layer of bluffing and risk management',
    ],
    uniquePoints: [
      'The doubling cube was invented in the 1920s in New York',
      'It transformed backgammon from a casual game to a competitive one',
    ],
  ),
];
