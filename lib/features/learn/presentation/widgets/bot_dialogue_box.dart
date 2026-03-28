import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/services/settings_service.dart';
import '../../../../core/constants/tradition.dart';
import '../../../ai/personality/bot_personality.dart';

/// Bot-narrated dialogue box for lessons.
///
/// Shows the tradition-appropriate bot avatar and italicized dialogue text.
/// When viewing another tradition's lesson, uses that tradition's default bot.
class BotDialogueBox extends StatelessWidget {
  final String text;
  final Tradition? tradition;

  const BotDialogueBox({
    super.key,
    required this.text,
    this.tradition,
  });

  @override
  Widget build(BuildContext context) {
    final personality = _personality;

    return Container(
      padding: const EdgeInsets.all(TavliSpacing.md),
      decoration: BoxDecoration(
        color: TavliColors.primary,
        borderRadius: BorderRadius.circular(TavliRadius.lg),
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
                personality.avatarInitial,
                style: const TextStyle(
                  color: TavliColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: TavliSpacing.sm),
          Expanded(
            child: Text(
              text,
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
    );
  }

  BotPersonality get _personality {
    final playerTradition = SettingsService.instance.tradition;
    if (tradition == null || tradition == playerTradition) {
      return SettingsService.instance.botPersonality;
    }
    return BotPersonality.defaultFor(tradition!);
  }
}
