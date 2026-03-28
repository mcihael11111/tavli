import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';

/// Dialogue lines for Turkish (Tavla) tradition personalities.
abstract final class TavlaDialogueDatabase {
  // ═══════════════════════════════════════════════════════════════
  //  MEHMET ABI — The kahvehane owner. Warm, strategic, uses proverbs.
  // ═══════════════════════════════════════════════════════════════
  static const mehmetLines = <DialogueLine>[
    // GAME START
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Hoş geldin! Sit, I\'ll pour you some çay. Let\'s play a friendly game.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Buyrun, buyrun! Welcome to the kahvehane. Ready for some tavla?',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, you\'re back. Good — the çay is hot and so am I. Başlayalım!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'You want a real game? As we say: "Sabır acıdır, meyvesi tatlıdır." Patience is bitter, but its fruit is sweet.',
    ),

    // PLAYER GOOD MOVE
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Aferin! That was a wise move. You have a good eye.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hmm... maşallah. I didn\'t expect that. Well played.',
    ),

    // PLAYER BAD MOVE
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Mmm, are you sure about that? Think carefully, arkadaşım.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'As we say: "Acele işe şeytan karışır." The devil gets into rushed work!',
    ),

    // PLAYER BLUNDER
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Eyvah! That was not your best, my friend. But the game is long.',
    ),

    // MIKHAIL/BOT ROLLS DOUBLES
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Çift! Kismet is with me today!',
    ),

    // PLAYER ROLLS DOUBLES
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Çift for you! Make the most of it — fortune doesn\'t knock twice.',
    ),

    // BOT HITS
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Vurdum! To the bar with you! *sips çay*',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'That blot was calling my name. Git bara!',
    ),

    // BOT GOT HIT
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah! You hit me! No matter — I\'ll be back stronger.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*sets down çay glass carefully* ...You will pay for that.',
    ),

    // BOT WINS
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Tebrikler bana! Good game, arkadaşım. More çay?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '"Sabreden derviş muradına ermiş." The patient dervish reaches his goal.',
    ),

    // PLAYER WINS
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Tebrikler! You beat old Mehmet! This calls for a fresh glass of çay.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bravo... I tip my glass to you. That was well earned.',
    ),

    // CLOSE GAME
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'This game is tight... like Turkish coffee — strong and intense!',
    ),

    // GAMMON
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Mars! Double points! That\'s how we play in the kahvehane.',
    ),

    // BEARING OFF
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'The race to bear off begins... may the dice favor the deserving!',
    ),

    // IDLE
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Take your time. As we say: "Acele gelin tez boşanır." — patience, my friend.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  TEYZE FATMA — The neighborhood matriarch. Sharp, competitive.
  // ═══════════════════════════════════════════════════════════════
  static const fatmaLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Otur bakalım! Fatma Teyze doesn\'t lose at her own table.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hmm, not bad. But I\'ve been playing since before your parents met!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ayy, yavrum! What was that? Come, I\'ll show you how it\'s done.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Tabii ki! Of course I won. Now eat this börek I brought.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ayyy! Tebrikler! ...but next time, no mercy!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hoop! Off to the bar! That\'ll teach you to leave blots near Fatma!',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  EMRE — University student. Fast, impulsive, modern slang.
  // ═══════════════════════════════════════════════════════════════
  static const emreLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hadi hadi! Quick game before my next class. Let\'s go!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Oha! Nice one abi! Respect.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yok artık! Bro, what was that? Delete that move!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'GG! Too fast for you, hehe. Rematch?',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Yaa be, you got me! Okay one more, I swear I\'ll win this time.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ÇİFT! Let\'s GOOO!',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  DEDE HASAN — Retired teacher. Patient, proverbs.
  // ═══════════════════════════════════════════════════════════════
  static const hasanLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Haydi evladım, otur. A game of tavla teaches more than any textbook.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Aferin! "Damlaya damlaya göl olur." Drop by drop, a lake forms.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Patience, my student. "Acele ile mani, hamamda söylenir." Haste makes waste.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Experience wins today. But you\'re learning — I can see it.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'The student surpasses the teacher! This is as it should be.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  AYŞE ABLA — The shopkeeper. Friendly trash-talker.
  // ═══════════════════════════════════════════════════════════════
  static const ayseLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Gel gel! Ayşe Abla is closing the shop early for this!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ooo güzel! You\'re not as hopeless as you look! Hehe.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ayyy! Was that a move or did your cat walk on the board?!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Kazandım! Don\'t be sad — come back tomorrow and I\'ll beat you again!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Çok şanslısın! Lucky! Okay, double or nothing next game!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Vuuuş! Right to the bar! Ayşe Abla shows no mercy!',
    ),
  ];
}
