import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/providers/accessibility_providers.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/services/settings_service.dart';
import '../data/models/game_result.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../ai/mikhail/dialogue_system.dart';
import '../../ai/mikhail/dialogue_event.dart';
import '../../profile/data/achievements.dart';
import '../../profile/presentation/match_history_screen.dart';
import '../../shop/data/shop_items.dart';
import '../../../shared/services/copy_service.dart';

/// Victory/defeat screen with score breakdown and bot's reaction.
class VictoryScreen extends StatefulWidget {
  final GameResult result;
  final DifficultyLevel difficulty;
  final bool isOnline;
  final String? opponentName;
  final int? ratingDelta;

  const VictoryScreen({
    super.key,
    required this.result,
    required this.difficulty,
    this.isOnline = false,
    this.opponentName,
    this.ratingDelta,
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
  int _coinsEarned = 0;

  bool get _playerWon => widget.result.winner == 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _bannerScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _detailsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.duration = ReducedMotion.duration(context, const Duration(milliseconds: 1000));
      _controller.forward();
    });
    _dialogue.trigger(
      _playerWon ? DialogueEvent.playerWin : DialogueEvent.mikhailWin,
      widget.difficulty,
      personality: SettingsService.instance.botPersonality,
    );

    // Record results, achievements, and coins. Wrapped in try/catch so
    // the victory screen never crashes — these are fire-and-forget saves.
    try {
      if (!widget.isOnline) {
        ProgressionService.instance.recordGame(widget.difficulty, widget.result);
      }

      MatchHistoryService.record(MatchRecord(
        timestamp: DateTime.now(),
        difficulty: widget.isOnline ? null : widget.difficulty,
        opponentName: widget.isOnline
            ? (widget.opponentName ?? 'Opponent')
            : '${SettingsService.instance.botPersonality.greekName} (${widget.difficulty.greekName})',
        playerWon: _playerWon,
        resultType: widget.result.type,
        cubeValue: widget.result.cubeValue,
        mode: widget.isOnline ? 'online' : 'bot',
      ));

      if (!widget.isOnline) {
        final newlyUnlocked = AchievementService.instance.checkAndUnlock(
          result: widget.result,
          difficulty: widget.difficulty,
        );
        for (final a in newlyUnlocked) {
          if (a.rewardCoins > 0) {
            ShopService.instance.addCoins(a.rewardCoins);
            _coinsEarned += a.rewardCoins;
          }
        }
        if (newlyUnlocked.isNotEmpty) {
          _showAchievementToast(newlyUnlocked.first);
        }
      }

      if (_playerWon) {
        final winReward = _coinReward(widget.difficulty, widget.isOnline);
        _coinsEarned += winReward;
        if (winReward > 0) {
          ShopService.instance.addCoins(winReward);
        }
      }
    } catch (e) {
      debugPrint('Victory save error: $e');
    }
  }

  /// Coin reward by difficulty.
  static int _coinReward(DifficultyLevel difficulty, bool isOnline) {
    if (isOnline) return 15;
    return switch (difficulty) {
      DifficultyLevel.easy || DifficultyLevel.easyWithHelp => 5,
      DifficultyLevel.medium => 10,
      DifficultyLevel.hard => 20,
      DifficultyLevel.pappous => 30,
    };
  }

  void _showAchievementToast(Achievement achievement) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: TavliSpacing.xs),
              Expanded(
                child: Text(
                  'Achievement Unlocked: ${achievement.name}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: TavliColors.primary,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Victory screen always uses the dark palette for drama.
    final bgColor = _playerWon
        ? TavliColors.primary
        : TavliColors.text;
    const textColor = TavliColors.light;
    final accentColor = _playerWon ? TavliColors.surface : TavliColors.error;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, _playerWon ? TavliColors.text : Colors.black],
          ),
        ),
        child: SafeArea(
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
                    const SizedBox(height: TavliSpacing.sm),
                    Text(
                      _playerWon ? TavliCopy.victoryBanner : TavliCopy.defeatBanner,
                      style: theme.textTheme.displayLarge!.copyWith(
                        color: accentColor,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xxs),
                    Text(
                      _playerWon ? TavliCopy.victory : TavliCopy.defeat,
                      style: theme.textTheme.titleLarge!.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TavliSpacing.xl),

              // Score details.
              Opacity(
                opacity: _detailsFade.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: TavliSpacing.xl),
                  padding: const EdgeInsets.all(TavliSpacing.md),
                  decoration: BoxDecoration(
                    color: TavliColors.light.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(TavliRadius.md),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _scoreLine(TavliCopy.result, _resultLabel(widget.result.type), textColor, theme),
                      _scoreLine(TavliCopy.multiplier, '${_resultMul(widget.result.type)}x', textColor, theme),
                      if (widget.result.cubeValue > 1)
                        _scoreLine('Cube', '${widget.result.cubeValue}x', textColor, theme),
                      Divider(color: accentColor.withValues(alpha: 0.3), height: TavliSpacing.lg),
                      _scoreLine(TavliCopy.totalPoints, '${widget.result.points}', textColor, theme, bold: true),
                      if (_coinsEarned > 0) ...[
                        const SizedBox(height: TavliSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    size: 16, color: TavliColors.warning),
                                const SizedBox(width: 4),
                                Text(TavliCopy.coinsEarned,
                                    style: theme.textTheme.bodyMedium!.copyWith(color: TavliColors.light)),
                              ],
                            ),
                            Text('+$_coinsEarned',
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  color: TavliColors.warning,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Online rating change.
              if (widget.isOnline && widget.ratingDelta != null)
                Opacity(
                  opacity: _detailsFade.value,
                  child: Padding(
                    padding: const EdgeInsets.only(top: TavliSpacing.sm, bottom: TavliSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.opponentName != null)
                          Text(
                            'vs ${widget.opponentName}  ·  ',
                            style: theme.textTheme.bodyMedium!.copyWith(color: textColor.withValues(alpha: 0.7)),
                          ),
                        Text(
                          'Rating: ${widget.ratingDelta! >= 0 ? '+' : ''}${widget.ratingDelta}',
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: widget.ratingDelta! >= 0
                                ? TavliColors.success
                                : TavliColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: TavliSpacing.sm),

              // Mikhail reaction (AI games only).
              if (!widget.isOnline) Opacity(
                opacity: _detailsFade.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: TavliSpacing.xl),
                  padding: const EdgeInsets.all(TavliSpacing.sm),
                  decoration: BoxDecoration(
                    color: TavliColors.light.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: TavliColors.surface,
                        child: Text('Μ', style: theme.textTheme.headlineSmall!.copyWith(
                          color: TavliColors.primary, fontWeight: FontWeight.bold,
                        )),
                      ),
                      const SizedBox(width: TavliSpacing.sm),
                      Expanded(
                        child: Text(
                          _dialogue.currentLine ?? (_playerWon
                              ? 'You beat me! We play again?'
                              : 'Better luck next time, φίλε μου!'),
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: textColor, fontStyle: FontStyle.italic,
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
                  padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.xl),
                  child: widget.isOnline
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/online-lobby'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: bgColor,
                                  padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
                                ),
                                child: Text(TavliCopy.backToLobby,
                                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
                              ),
                            ),
                            const SizedBox(height: TavliSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.go('/home'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: const BorderSide(color: textColor, width: 1.5),
                                ),
                                child: Text(TavliCopy.home),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/game', extra: widget.difficulty),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: bgColor,
                                  padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
                                ),
                                child: Text(TavliCopy.playAgain,
                                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
                              ),
                            ),
                            const SizedBox(height: TavliSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.go('/difficulty'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textColor,
                                      side: const BorderSide(color: textColor, width: 1.5),
                                    ),
                                    child: Text(TavliCopy.difficulty),
                                  ),
                                ),
                                const SizedBox(width: TavliSpacing.sm),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.go('/home'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textColor,
                                      side: const BorderSide(color: textColor, width: 1.5),
                                    ),
                                    child: Text(TavliCopy.home),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: TavliSpacing.xl),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _scoreLine(String label, String value, Color textColor, ThemeData theme, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: textColor)),
          Text(value, style: bold
              ? theme.textTheme.headlineMedium!.copyWith(
                  color: textColor, fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodyLarge!.copyWith(color: textColor)),
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
