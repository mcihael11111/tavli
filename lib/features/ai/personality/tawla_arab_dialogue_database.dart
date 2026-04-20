import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';

/// Dialogue lines for Arab World (Tawla) tradition personalities.
abstract final class TawlaArabDialogueDatabase {
  // ═══════════════════════════════════════════════════════════════
  //  ABU YUSUF — The coffeehouse elder. Philosophical, respected.
  // ═══════════════════════════════════════════════════════════════
  static const abuYusufLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ahlan wa sahlan. Sit, have some coffee. The board is set.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Welcome, habibi. Today the dice will tell our story.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'In this coffeehouse, we play for honor. May the best mind prevail.',
    ),

    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ahsant! Well done. The wise player sees three moves ahead.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mabrook. That was the move of a master.',
    ),

    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Patience, young one. "Al-ajala min ash-shaytan." Haste is from the devil.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hmm. The dice forgive, but the board remembers.',
    ),

    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*strokes beard* As I always say... think first, move second.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles! Inshallah, the path is clear.',
    ),

    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles for you! Mabrook — but it\'s not the dice, it\'s the plan.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yalla, to the bar! A blot is an invitation, habibi.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ah! You hit me. No matter — the river always finds its way back.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Alhamdulillah. A good game. The coffeehouse elder prevails.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '"Sabr miftah al-faraj." Patience is the key to relief. GG.',
    ),

    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mabrook! You\'ve earned your place at this table. Come back anytime.',
    ),

    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'A tight game... like the old souk at midday. Every step matters.',
    ),

    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mars! A decisive victory. The board has spoken.',
    ),

    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*sips Arabic coffee* Take your time. The coffeehouse has no clock.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  SAMIRA — Neighbor. Quick wit, no mercy.
  // ═══════════════════════════════════════════════════════════════
  static const samiraLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'أهلاً! Think you can beat me? I play every day after work.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mmm, not bad. But don\'t get cocky — the game isn\'t over.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yii! What was THAT? Are you playing with your eyes closed?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'I win! كالعادة — as usual. Want to try again?',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Fine, you won. Don\'t let it go to your head — tomorrow is mine.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yalla, to the bar! You left that blot wide open — what did you expect?',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  HANA — College-aged cousin. Modern slang, teaches you.
  // ═══════════════════════════════════════════════════════════════
  static const hanaLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hey! Yalla, quick game? I\'ll teach you some new tricks.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ooh, nice! You\'re learning! That\'s what we call a "maka" move.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Nooo why?! Okay okay, next time think about the pip count first.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'GG! Don\'t worry, I\'ll give you tips. Same time tomorrow?',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Wait WHAT? You beat me?! Okay respect, respect. Rematch tho.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'DOUBLES! Yesss let\'s go!',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  KHALED — Young man. Enthusiastic, boisterous.
  // ═══════════════════════════════════════════════════════════════
  static const khaledLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yalla habibi! Sit down, let\'s play! I\'ve been waiting all day.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Wallah, nice move! You\'re not bad... but I\'m better!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hahaha! What was that?! My little brother plays better than this!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'YESSS! Khaled wins! *claps* Another one? I\'m just warming up!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You beat me?! La la la... okay, mabrook. But next time — no mercy!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'BOOM! To the bar! *slams piece* That\'s how we play in the maqha!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'DOUBLES! Alhamdulillah! Watch and learn, habibi!',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  UMM AHMAD — Grandmother. Wise, warm, unbeatable.
  // ═══════════════════════════════════════════════════════════════
  static const ummAhmadLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Come, habibti. Sit. I\'ll pour you tea while we play.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mashallah! You remind me of your grandfather. He played the same way.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*shakes head gently* No no, habibi. Think before you move. Patience.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'I win, alhamdulillah. Don\'t feel bad — Umm Ahmad has been playing for fifty years.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You beat me! *smiles* I\'m so proud. Come, have some knafeh to celebrate.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*quietly moves piece to bar* An open blot is a gift, habibti.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*pours more tea* Take your time. The board isn\'t going anywhere.',
    ),
  ];
}
