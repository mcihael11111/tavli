import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../shop/data/shop_items.dart';
import '../data/challenge_service.dart';

/// Weekly challenges screen.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ChallengeService.instance;
    final challenges = service.activeChallenges;

    // Calculate time until next rotation (Monday 00:00)
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = DateTime(now.year, now.month, now.day + daysUntilMonday);
    final timeLeft = nextMonday.difference(now);

    return GradientScaffold(
      appBar: AppBar(title: Text(TavliCopy.weeklyChallenges)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TavliSpacing.md, kToolbarHeight + TavliSpacing.xl, TavliSpacing.md, TavliSpacing.md,
          ),
          children: [
            // Timer module.
            ContentModule(
              icon: Icons.timer,
              title: 'Resets in ${timeLeft.inDays}d ${timeLeft.inHours % 24}h',
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Streak',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: TavliColors.disabledOnPrimary,
                    ),
                  ),
                  Text(
                    '${service.currentStreak}',
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TavliColors.warning,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.lg),

            // Challenge cards.
            if (challenges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(TavliSpacing.xl),
                  child: Text(
                    'No challenges available.\nCheck back next week!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: TavliColors.disabledOnPrimary,
                    ),
                  ),
                ),
              )
            else
              ...challenges.map((challenge) {
                final progress = service.progressFor(challenge.id);
                return _ChallengeCard(
                  challenge: challenge,
                  progress: progress,
                  onClaim: () => _claimReward(challenge),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _claimReward(Challenge challenge) {
    final service = ChallengeService.instance;
    final claimed = service.claimReward(challenge.id);
    if (claimed) {
      ShopService.instance.addCoins(challenge.rewardCoins);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${challenge.rewardCoins} coins!')),
      );
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ChallengeProgress? progress;
  final VoidCallback onClaim;

  const _ChallengeCard({
    required this.challenge,
    required this.progress,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prog = progress;
    final isComplete = prog?.completed ?? false;
    final isClaimed = prog?.rewardClaimed ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: TavliSpacing.sm),
      child: ContentModule(
        decoration: isComplete
            ? BoxDecoration(
                color: TavliModule.fill,
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: TavliColors.success.withValues(alpha: 0.5),
                  width: 2,
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TavliColors.light,
                        ),
                      ),
                      Text(
                        challenge.titleGreek,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontStyle: FontStyle.italic,
                          color: TavliColors.disabledOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Reward badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TavliSpacing.xs,
                    vertical: TavliSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: TavliColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 14, color: TavliColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.rewardCoins}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TavliColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TavliSpacing.xxs),

            Text(
              challenge.description,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: TavliColors.disabledOnPrimary,
              ),
            ),

            const SizedBox(height: TavliSpacing.sm),

            // Progress bar.
            if (prog != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TavliRadius.full),
                      child: LinearProgressIndicator(
                        value: prog.fraction,
                        minHeight: 8,
                        backgroundColor: TavliColors.light.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                          isComplete ? TavliColors.success : TavliColors.light,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TavliSpacing.sm),
                  Text(
                    '${prog.current}/${prog.target}',
                    style: theme.textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TavliColors.disabledOnPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TavliSpacing.xs),
            ],

            // Claim button.
            if (isComplete && !isClaimed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onClaim,
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: Text('Claim ${challenge.rewardCoins} coins'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TavliColors.success,
                  ),
                ),
              )
            else if (isClaimed)
              Center(
                child: Text(
                  'Claimed!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TavliColors.success.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
