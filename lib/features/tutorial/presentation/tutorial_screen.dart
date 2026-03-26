import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import 'mini_board_painter.dart';

/// Interactive tutorial — lessons guided by the tradition's bot with board diagrams.
/// Content adapts based on the player's selected tradition.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentLesson = 0;

  Tradition get _tradition => SettingsService.instance.tradition;

  List<_Lesson> get _lessons => _lessonsForTradition(_tradition);

  static List<_Lesson> _lessonsForTradition(Tradition tradition) {
    final base = _baseLessons;
    final extra = _traditionSpecificLessons(tradition);
    return [...base, ...extra];
  }

  static List<_Lesson> _traditionSpecificLessons(Tradition tradition) {
    return switch (tradition) {
      Tradition.tavli => [
        const _Lesson(
          title: 'Plakoto — Pinning',
          botSays: 'In Plakoto, you don\'t hit — you PIN! Land on a single '
              'opponent checker and trap it. And watch out for the μάνα!',
          body: 'Plakoto rules:\n'
              '• All 15 checkers start on your 1-point\n'
              '• Landing on a single opponent checker pins it in place\n'
              '• Pinned checkers cannot move until freed\n'
              '• Mother piece (μάνα): if your last checker on start is pinned, you lose double!',
          icon: Icons.push_pin,
          diagram: null,
        ),
        const _Lesson(
          title: 'Fevga — Running',
          botSays: 'Fevga is the race! No hitting, no pinning. '
              'Just block your opponent and run for the finish!',
          body: 'Fevga rules:\n'
              '• All 15 checkers start on one point\n'
              '• Both players move in the same direction\n'
              '• A single checker blocks the point entirely\n'
              '• You cannot block all 6 points in your starting quadrant\n'
              '• Must advance past opponent\'s start before spreading out',
          icon: Icons.directions_run,
          diagram: null,
        ),
      ],
      Tradition.tavla => [
        const _Lesson(
          title: 'Tapa — Turkish Pinning',
          botSays: 'Tapa is like Plakoto — you pin instead of hit. '
              'Land on a lone opponent piece to trap it!',
          body: 'Tapa rules:\n'
              '• All 15 checkers start on one point\n'
              '• Pin single opponent checkers instead of hitting\n'
              '• Mother piece rule applies\n'
              '• Strategy: control key points early',
          icon: Icons.push_pin,
          diagram: null,
        ),
        const _Lesson(
          title: 'Moultezim — Turkish Running',
          botSays: 'Moultezim is pure racing with blocking. '
              'No captures, just outrun your opponent!',
          body: 'Moultezim rules:\n'
              '• Same as Fevga — same-direction, blocking game\n'
              '• Single checker controls a point\n'
              '• Cannot block all 6 starting quadrant points',
          icon: Icons.directions_run,
          diagram: null,
        ),
      ],
      Tradition.nardy => [
        const _Lesson(
          title: 'Long Nard — The Head Rule',
          botSays: 'In Long Nard, all pieces start on one point — the "head." '
              'You can only move one piece off the head per turn!',
          body: 'Long Nard rules:\n'
              '• All 15 checkers on the "head" point\n'
              '• Only ONE checker may leave the head per turn\n'
              '• Exception: first turn with 3-3, 4-4, or 6-6 allows two\n'
              '• No hitting — single checker blocks\n'
              '• Cannot build a 6-prime if opponent is fully trapped behind it',
          icon: Icons.looks_one,
          diagram: null,
        ),
      ],
      Tradition.sheshBesh => [
        const _Lesson(
          title: 'Mahbusa — Arabic Pinning',
          botSays: 'Mahbusa means "imprisoned" — and that\'s what you do! '
              'Pin your opponent\'s lone checkers to trap them.',
          body: 'Mahbusa rules:\n'
              '• All 15 checkers start on one point\n'
              '• Pin single opponent checkers\n'
              '• Mother piece rule applies\n'
              '• Similar to Plakoto but from the Arabic tradition',
          icon: Icons.push_pin,
          diagram: null,
        ),
      ],
    };
  }

  static final _baseLessons = [
    _Lesson(
      title: 'The Board',
      botSays: 'Welcome! This is a backgammon board. '
          '24 points, like the hours of the day. Each player has 15 checkers.',
      body: 'The board has 24 triangles called "points." Your checkers start '
          'on specific points and must travel around the board to your home board '
          '(points 1-6), then bear off.\n\n'
          'You move from high-numbered points to low-numbered points.',
      icon: Icons.grid_on,
      diagram: MiniBoardPainter(
        showNumbers: true,
        checkers: {
          23: (2, true),
          12: (5, true),
          7: (3, true),
          5: (5, true),
          0: (2, false),
          11: (5, false),
          16: (3, false),
          18: (5, false),
        },
        arrows: [(23, 18), (18, 12)],
      ),
    ),
    _Lesson(
      title: 'Moving Checkers',
      botSays: 'You roll two dice, ρε! Each die is a separate move. '
          'Roll a 5 and a 3? Move one checker 5 and another 3. '
          'Or move ONE checker 5 then 3 — but the middle point must be open!',
      body: 'Rules:\n'
          '• You can only land on "open" points (fewer than 2 opponent checkers)\n'
          '• You MUST use both dice if possible\n'
          '• If only one die works, you must play the larger one\n'
          '• Doubles = 4 moves!',
      icon: Icons.casino,
      diagram: MiniBoardPainter(
        checkers: {
          12: (5, true),
          7: (3, true),
          5: (5, true),
        },
        highlightedPoints: {7, 10},
        arrows: [(12, 7), (12, 10)],
      ),
    ),
    _Lesson(
      title: 'Hitting & The Bar',
      botSays: 'A checker alone on a point? That\'s a "blot" — vulnerable! '
          'I can hit it and send it to the bar. ΩΠΑΑΑ! '
          'Then you must re-enter before doing anything else.',
      body: 'When your checker is hit, it goes to the center bar.\n\n'
          'To re-enter, you must roll a number corresponding to an open point '
          'in your opponent\'s home board.\n\n'
          'If all entry points are blocked — you lose your turn!',
      icon: Icons.gavel,
      diagram: MiniBoardPainter(
        checkers: {
          8: (1, true),
          5: (2, false),
          3: (2, false),
        },
        highlightedPoints: {8},
        arrows: [(5, 8)],
      ),
    ),
    _Lesson(
      title: 'Bearing Off',
      botSays: 'When ALL your checkers are in your home board, '
          'you can start taking them off. This is bearing off. '
          'First one to remove all 15 wins!',
      body: 'To bear off:\n'
          '• All 15 checkers must be in your home board (points 1-6)\n'
          '• Roll the exact number matching the point, or...\n'
          '• If no checker is on a higher point, you can bear off from the highest occupied point\n'
          '• If a checker gets hit during bearing off, you must re-enter first!',
      icon: Icons.emoji_events,
      diagram: MiniBoardPainter(
        checkers: {
          5: (3, true),
          4: (4, true),
          3: (3, true),
          2: (2, true),
          1: (2, true),
          0: (1, true),
        },
        highlightedPoints: {5, 4, 3, 2, 1, 0},
      ),
    ),
    _Lesson(
      title: 'Strategy Tips',
      botSays: 'Now listen carefully, παιδί μου. Making "points" — '
          'two or more checkers together — is the key. '
          'They block your opponent. Build a wall, a πρίμα! '
          'And never leave blots if you can avoid it.',
      body: 'Key strategies:\n'
          '• Make points (πόρτες): 2+ checkers protect each other\n'
          '• Build primes: consecutive points block the opponent\n'
          '• Anchor: keep a point in opponent\'s home board\n'
          '• Balance offense and defense\n'
          '• Count pips to know if you\'re ahead in the race',
      icon: Icons.lightbulb_outline,
      diagram: MiniBoardPainter(
        checkers: {
          7: (2, true),
          6: (2, true),
          5: (3, true),
          4: (3, true),
          3: (2, true),
          2: (2, true),
        },
        highlightedPoints: {7, 6, 5, 4, 3, 2},
      ),
    ),
    const _Lesson(
      title: 'The Doubling Cube',
      botSays: 'Ah, the cube! This is where real tavli gets serious. '
          'You can offer to double the stakes before you roll. '
          'Your opponent must accept... or surrender!',
      body: 'The doubling cube:\n'
          '• Starts at 1x (center of board, available to both)\n'
          '• Before rolling, you can offer to double the stakes\n'
          '• Opponent can Accept (game continues at 2x) or Decline (loses at current stakes)\n'
          '• After accepting, only the acceptor can re-double (to 4x, 8x, etc.)\n'
          '• Max value: 64x\n\n'
          'Offer the cube when you have a strong advantage!\n'
          'Accept if you have at least 25% chance of winning.',
      icon: Icons.casino,
      diagram: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_currentLesson];

    return Scaffold(
      // Background from theme (TavliColors.surface).
      appBar: AppBar(
        title: Text('Learn — ${_currentLesson + 1}/${_lessons.length}'),
      ),
      body: Column(
        children: [
          // Progress bar.
          LinearProgressIndicator(
            value: (_currentLesson + 1) / _lessons.length,
            backgroundColor: TavliColors.primary.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation(TavliColors.light),
            minHeight: 3,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson icon and title.
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: TavliColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(lesson.icon,
                            color: TavliColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: TavliColors.light,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mikhail dialogue.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TavliColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TavliColors.surface,
                          ),
                          child: Center(
                            child: Text(
                              SettingsService.instance.botPersonality.avatarInitial,
                              style: const TextStyle(
                                color: TavliColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lesson.botSays,
                            style: const TextStyle(
                              color: TavliColors.light,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Board diagram.
                  if (lesson.diagram != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: TavliColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: lesson.diagram!,
                          size: const Size(double.infinity, 200),
                        ),
                      ),
                    ),

                  // Lesson content.
                  Text(
                    lesson.body,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: TavliColors.light,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation buttons.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentLesson > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentLesson--),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentLesson > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentLesson < _lessons.length - 1) {
                        setState(() => _currentLesson++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_currentLesson < _lessons.length - 1
                        ? 'Next'
                        : 'Start Playing!'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Lesson {
  final String title;
  final String botSays;
  final String body;
  final IconData icon;
  final MiniBoardPainter? diagram;

  const _Lesson({
    required this.title,
    required this.botSays,
    required this.body,
    required this.icon,
    this.diagram,
  });
}
