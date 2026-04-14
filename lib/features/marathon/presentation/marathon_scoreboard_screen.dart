import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../domain/marathon_state.dart';
import 'marathon_provider.dart';

/// Shown between marathon games to display the score and announce the next variant.
class MarathonScoreboardScreen extends ConsumerWidget {
  final DifficultyLevel difficulty;

  const MarathonScoreboardScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final marathon = ref.watch(marathonProvider);
    if (marathon == null) {
      // Marathon ended — go home.
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return const SizedBox.shrink();
    }

    final personality = SettingsService.instance.botPersonality;
    final isComplete = marathon.isComplete;
    final playerWon = marathon.winner == 1;

    final gradient = isComplete
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              playerWon ? TavliColors.primary : TavliColors.text,
              playerWon ? TavliColors.text : Colors.black,
            ],
          )
        : TavliGradients.warmScaffold;

    return GradientScaffold(
      gradient: gradient,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TavliSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // Title.
              Text(
                isComplete
                    ? (playerWon ? 'Marathon Victory!' : 'Marathon Defeat')
                    : '${marathon.tradition.displayName} Marathon',
                style: theme.textTheme.displaySmall!.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? TavliColors.light : TavliColors.text,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TavliSpacing.xl),

              // Score display.
              ContentModule(
                padding: const EdgeInsets.all(TavliSpacing.lg),
                child: Column(
                  children: [
                    // Player names and scores.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ScoreColumn(
                          label: 'You',
                          score: marathon.player1Score,
                          isLeading: marathon.player1Score > marathon.player2Score,
                          textColor: isComplete ? TavliColors.light : TavliColors.text,
                        ),
                        Text(
                          'vs',
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: isComplete
                                ? TavliColors.disabledOnPrimary
                                : TavliColors.primary,
                          ),
                        ),
                        _ScoreColumn(
                          label: personality.displayName,
                          score: marathon.player2Score,
                          isLeading: marathon.player2Score > marathon.player1Score,
                          textColor: isComplete ? TavliColors.light : TavliColors.text,
                        ),
                      ],
                    ),
                    const SizedBox(height: TavliSpacing.sm),
                    Text(
                      'First to ${marathon.targetScore} points',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 13,
                        color: isComplete
                            ? TavliColors.disabledOnPrimary
                            : TavliColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Game history.
              if (marathon.gameHistory.isNotEmpty)
                ContentModule(
                  child: Column(
                    children: [
                      for (int i = 0; i < marathon.gameHistory.length; i++)
                        _GameHistoryRow(
                          index: i + 1,
                          record: marathon.gameHistory[i],
                          textColor: isComplete ? TavliColors.light : TavliColors.text,
                        ),
                    ],
                  ),
                ),

              const Spacer(),

              // Next variant announcement or final buttons.
              if (!isComplete) ...[
                Text(
                  'Next game:',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: TavliColors.primary,
                  ),
                ),
                const SizedBox(height: TavliSpacing.xs),
                Text(
                  marathon.currentVariant.displayName,
                  style: theme.textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TavliColors.text,
                  ),
                ),
                Text(
                  marathon.currentVariant.nativeName,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: TavliColors.primary,
                  ),
                ),
                const SizedBox(height: TavliSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/game', extra: {
                      'difficulty': difficulty,
                      'variant': marathon.currentVariant,
                      'marathon': true,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TavliColors.primary,
                      foregroundColor: TavliColors.light,
                      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
                    ),
                    child: Text('Continue', style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                  ),
                ),
                const SizedBox(height: TavliSpacing.sm),
                TextButton(
                  onPressed: () {
                    ref.read(marathonProvider.notifier).endMarathon();
                    context.go('/home');
                  },
                  child: const Text('Abandon Marathon',
                      style: TextStyle(color: TavliColors.primary)),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(marathonProvider.notifier).endMarathon();
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TavliColors.light,
                      foregroundColor: TavliColors.text,
                      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
                    ),
                    child: const Text('Back to Home', style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                  ),
                ),
              ],

              const SizedBox(height: TavliSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int score;
  final bool isLeading;
  final Color textColor;

  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.isLeading,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium!.copyWith(color: textColor.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: TavliSpacing.xs),
        Text(
          '$score',
          style: theme.textTheme.displayLarge!.copyWith(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: isLeading ? TavliColors.success : textColor,
          ),
        ),
      ],
    );
  }
}

class _GameHistoryRow extends StatelessWidget {
  final int index;
  final MarathonGameRecord record;
  final Color textColor;

  const _GameHistoryRow({
    required this.index,
    required this.record,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerWon = record.result.winner == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index.',
              style: theme.textTheme.bodySmall!.copyWith(color: textColor.withValues(alpha: 0.5)),
            ),
          ),
          Expanded(
            child: Text(
              record.variant.displayName,
              style: theme.textTheme.bodySmall!.copyWith(fontSize: 13, color: textColor),
            ),
          ),
          Icon(
            playerWon ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: playerWon ? TavliColors.success : TavliColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            '+${record.result.points}',
            style: theme.textTheme.bodySmall!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: playerWon ? TavliColors.success : TavliColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
