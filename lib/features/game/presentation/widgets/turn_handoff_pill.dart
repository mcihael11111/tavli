import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact label that announces whose turn it is and what they're doing.
///
/// Replaces the avatar border-color swap as the primary turn signal. Three
/// states with a 120ms cross-fade between them:
/// - `Your turn` (player's turn)
/// - `{BotName} thinking…` (bot is selecting a move)
/// - `{BotName} moving…` (bot is animating its committed move)
class TurnHandoffPill extends StatelessWidget {
  final bool isPlayerTurn;
  final bool isBotMoving;
  final String botName;

  const TurnHandoffPill({
    super.key,
    required this.isPlayerTurn,
    required this.isBotMoving,
    required this.botName,
  });

  String _label(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (l == null) {
      // Fallback to English literals when localization isn't wired (e.g. raw
      // widget tests that omit the AppLocalizations delegate).
      if (isPlayerTurn) return 'Your turn';
      return isBotMoving ? '$botName moving…' : '$botName thinking…';
    }
    if (isPlayerTurn) return l.playerTurn;
    return isBotMoving ? l.botMoving(botName) : l.botThinking(botName);
  }

  @override
  Widget build(BuildContext context) {
    final label = _label(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(label),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TavliColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: TavliColors.text,
          ),
        ),
      ),
    );
  }
}
