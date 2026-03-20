import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/progression_service.dart';
import '../data/models/game_result.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../ai/mikhail/dialogue_system.dart';
import '../../ai/mikhail/dialogue_event.dart';

/// Victory/defeat screen with score breakdown and Mikhail's reaction.
class VictoryScreen extends StatefulWidget {
  final GameResult result;
  final DifficultyLevel difficulty;

  const VictoryScreen({
    super.key,
    required this.result,
    required this.difficulty,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bannerScale;
  late Animation<double> _detailsFade;
  final _dialogue = DialogueSystem();

  bool get _playerWon => widget.result.winner == 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );
    _bannerScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _detailsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );
    _controller.forward();
    _dialogue.trigger(
      _playerWon ? DialogueEvent.playerWin : DialogueEvent.mikhailWin,
      widget.difficulty,
    );

    // Record result in progression tracking.
    ProgressionService.instance.recordGame(widget.difficulty, widget.result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Victory screen always uses the dark palette for drama.
    final bgColor = _playerWon
        ? TavliColors.kafeneioBrown
        : const Color(0xFF2A1A0E);
    const textColor = TavliColors.parchment;
    final accentColor = _playerWon ? TavliColors.oliveGold : TavliColors.terracotta;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            children: [
              const Spacer(flex: 2),

              // Banner.
              Transform.scale(
                scale: _bannerScale.value,
                child: Column(
                  children: [
                    if (_playerWon)
                      const Text('🏆', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 12),
                    Text(
                      _playerWon ? 'ΝΙΚΗ!' : 'ΗΤΤΑ',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _playerWon ? 'Victory!' : 'Defeat',
                      style: const TextStyle(color: textColor, fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Score details.
              Opacity(
                opacity: _detailsFade.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _scoreLine('Result', _resultLabel(widget.result.type), textColor),
                      _scoreLine('Multiplier', '${_resultMul(widget.result.type)}x', textColor),
                      if (widget.result.cubeValue > 1)
                        _scoreLine('Cube', '${widget.result.cubeValue}x', textColor),
                      Divider(color: accentColor.withValues(alpha: 0.3), height: 24),
                      _scoreLine('Total Points', '${widget.result.points}', textColor, bold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mikhail reaction.
              Opacity(
                opacity: _detailsFade.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: TavliColors.kafeneioBrown,
                        child: const Text('Μ', style: TextStyle(
                          color: textColor, fontSize: 18, fontWeight: FontWeight.bold,
                        )),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dialogue.currentLine ?? (_playerWon
                              ? 'You beat me! We play again?'
                              : 'Better luck next time, φίλε μου!'),
                          style: const TextStyle(
                            color: textColor, fontSize: 14, fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Buttons.
              Opacity(
                opacity: _detailsFade.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/game', extra: widget.difficulty),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: bgColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('PLAY AGAIN',
                            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/difficulty'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: const BorderSide(color: textColor, width: 1.5),
                              ),
                              child: const Text('Difficulty'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/home'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: const BorderSide(color: textColor, width: 1.5),
                              ),
                              child: const Text('Home'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreLine(String label, String value, Color textColor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
          Text(value, style: TextStyle(
            color: textColor, fontSize: bold ? 20 : 16,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          )),
        ],
      ),
    );
  }

  String _resultLabel(GameResultType t) => switch (t) {
        GameResultType.single => 'Single Game',
        GameResultType.gammon => 'Gammon!',
        GameResultType.backgammon => 'Backgammon!',
      };
  int _resultMul(GameResultType t) => switch (t) {
        GameResultType.single => 1,
        GameResultType.gammon => 2,
        GameResultType.backgammon => 3,
      };
}
