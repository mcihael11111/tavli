import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';

/// Dialogue lines for Israeli/Arab (Shesh Besh) tradition personalities.
abstract final class SheshBeshDialogueDatabase {
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
  //  DOD MOSHE — Uncle. Loud, animated, heart of gold.
  // ═══════════════════════════════════════════════════════════════
  static const mosheLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '!שלום! Yalla, sit down already! Dod Moshe is READY!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '!יופי! BEAUTIFUL move! You learned from the best — ME! Hahaha!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Nu?! WHAT was that?! My cat plays better shesh besh! YALLA, think!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '!כל הכבוד לי! Dod Moshe WINS! I told you! Now come, eat something.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '...You beat me?! IMPOSSIBLE! ...Okay fine, !מזל טוב. But REMATCH!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'BOOM! To the bar! *slaps table* Dod Moshe shows NO mercy!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'DOUBLES! !יש! NOW we\'re talking!',
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
  //  SABA ELI — Grandfather. Slow, deliberate, always wins.
  // ═══════════════════════════════════════════════════════════════
  static const eliLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Shalom. Sit. Let the dice speak.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*nods slowly* ...Good.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*sighs* Think again, neshomeleh.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*quiet smile* Saba wins. As it should be.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You beat Saba? ...I\'m proud of you. Truly.',
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
}
