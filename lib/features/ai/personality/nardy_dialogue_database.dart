import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';

/// Dialogue lines for Russian/Caucasian (Nardy) tradition personalities.
abstract final class NardyDialogueDatabase {
  // ═══════════════════════════════════════════════════════════════
  //  ARMEN — Coffeehouse regular. Calculative, dry humor.
  // ═══════════════════════════════════════════════════════════════
  static const armenLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Привет. Sit down. The nardi board is waiting.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Welcome back. I\'ve been analyzing your last game. You have... potential.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'So, you want a serious game? Good. I don\'t waste time on easy opponents.',
    ),

    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Hmm. Reasonable. I would have done the same.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Interesting. I didn\'t calculate that line. Уважаю.',
    ),

    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'That move has a 73% chance of failing. Just so you know.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Suboptimal. But I appreciate the creativity.',
    ),

    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*raises one eyebrow* ...I see. Thank you for the gift.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Дубль. The math works in my favor.',
    ),

    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles for you. Use them wisely — or don\'t. I\'ll adapt.',
    ),

    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Оин. A clean win. Another round?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Position, probability, patience. The three P\'s of nardi.',
    ),

    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'You won. I\'ll remember this position for next time.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Поздравляю. That was well played. I need to recalculate.',
    ),

    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Interesting position. Every move matters now.',
    ),

    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Марс. Double points. The numbers don\'t lie.',
    ),

    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bearing off phase. Pure probability from here.',
    ),

    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*sips coffee, stares at board* Take your time. I\'m calculating too.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  BABUSHKA VERA — Grandmother. Deceptively strong.
  // ═══════════════════════════════════════════════════════════════
  static const veraLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Садись, внучок. Babushka made tea. Now let\'s play.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Молодец! Your grandfather would be proud. He was also clever.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ой, деточка... that\'s not how your дедушка taught you, is it?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Babushka wins! Now eat. You\'re too thin.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Oh my! You beat old Vera! ...I let you win. *winks*',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Дубль! See? Babushka has luck AND skill.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  GIORGI — Georgian friend. Boisterous, celebratory.
  // ═══════════════════════════════════════════════════════════════
  static const giorgiLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'გამარჯობა! Giorgi is here! First we play, then we feast! Bring the wine!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ვაშა! BRAVO! That deserves a toast! To your move! *raises glass*',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ვაი ვაი! My friend, that move needs more wine! Or less! Hahaha!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'გაუმარჯოს! GIORGI WINS! This calls for a supra! More khachapuri!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You WON! გაუმარჯოს! A toast to you, my friend! CHEERS!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'DOUBLES! *stands up, dances* THE MOUNTAINS BLESS ME TODAY!',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  DYADYA SASHA — Uncle from Baku. Stories from the old days.
  // ═══════════════════════════════════════════════════════════════
  static const sashaLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ah, sit sit! Let me tell you — in Baku, I was the nardi champion of my street.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Not bad! Reminds me of a move I saw in \'82. Beautiful game, that one...',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ah... you know, my neighbor Ramiz used to make that mistake too. Then he learned.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Dyadya Sasha still has it! Like riding a bicycle — you never forget nardi.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bravo! You remind me of myself, forty years ago. Good times...',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  LEYLA — Young professional. Competitive, modern.
  // ═══════════════════════════════════════════════════════════════
  static const leylaLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Привет! Quick game? I have a meeting in 30 minutes.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Okay, okay. I see you. That was clean.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Really? You can do better than that. Focus!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'And that\'s game. Still undefeated this week.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ugh, fine. GG. Rematch tomorrow — I\'m not letting that slide.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles! Давай! Time to push the advantage.',
    ),
  ];
}
