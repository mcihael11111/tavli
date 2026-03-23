import 'package:flutter/material.dart';

/// Pre-defined quick chat messages for multiplayer.
///
/// Greek-themed, friendly, no toxicity risk since they're pre-set.
class QuickChatMessage {
  final String text;
  final String? emoji;
  final String category;

  const QuickChatMessage({
    required this.text,
    this.emoji,
    required this.category,
  });
}

/// All available quick chat messages.
abstract final class QuickChatMessages {
  static const List<QuickChatMessage> all = [
    // Greetings.
    QuickChatMessage(text: 'Γεια σου! Hi!', emoji: '👋', category: 'greeting'),
    QuickChatMessage(text: 'Καλό παιχνίδι! Good game!', emoji: '🤝', category: 'greeting'),
    QuickChatMessage(text: 'Πάμε! Let\'s go!', emoji: '🎲', category: 'greeting'),

    // Reactions.
    QuickChatMessage(text: 'Μπράβο! Well played!', emoji: '👏', category: 'reaction'),
    QuickChatMessage(text: 'Ωπα! Wow!', emoji: '😮', category: 'reaction'),
    QuickChatMessage(text: 'Τυχερός! Lucky!', emoji: '🍀', category: 'reaction'),
    QuickChatMessage(text: 'Γαμώτο! Damn!', emoji: '😤', category: 'reaction'),

    // Game.
    QuickChatMessage(text: 'Σκέφτομαι... Thinking...', emoji: '🤔', category: 'game'),
    QuickChatMessage(text: 'Ένα λεπτό... One moment...', emoji: '⏳', category: 'game'),
    QuickChatMessage(text: 'Διπλό! Double!', emoji: '🎯', category: 'game'),

    // Farewell.
    QuickChatMessage(text: 'Ευχαριστώ! Thanks!', emoji: '🙏', category: 'farewell'),
    QuickChatMessage(text: 'Ρεβάνς? Rematch?', emoji: '🔄', category: 'farewell'),
    QuickChatMessage(text: 'Αντίο! Bye!', emoji: '👋', category: 'farewell'),
  ];
}

/// Quick chat overlay widget for multiplayer games.
class QuickChatPanel extends StatelessWidget {
  final void Function(QuickChatMessage message)? onSend;
  final List<ChatEntry> history;

  const QuickChatPanel({
    super.key,
    this.onSend,
    this.history = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar.
          Container(
            width: 32, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Chat history.
          if (history.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final entry = history[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${entry.senderName}: ${entry.message.text}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // Quick chat grid.
          Flexible(
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.8,
              children: QuickChatMessages.all.map((msg) {
                return Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSend?.call(msg),
                    child: Center(
                      child: Text(
                        '${msg.emoji ?? ''} ${msg.text.split('!').first}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatEntry {
  final String senderName;
  final QuickChatMessage message;
  final DateTime timestamp;

  const ChatEntry({
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}
