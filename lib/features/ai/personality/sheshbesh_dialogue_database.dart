import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';

/// Dialogue lines for Israeli (Shesh Besh) tradition personalities.
abstract final class SheshBeshDialogueDatabase {
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
  //  YAEL — Young professional. Sharp, competitive.
  // ═══════════════════════════════════════════════════════════════
  static const yaelLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hey! Let\'s do this. I don\'t have all day — yalla!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Okay, respect. !יפה — that was sharp.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Really? That\'s your move? Think again next time.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'I win! !כל הכבוד לי Better luck next time.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Okay, you got me. !מזל טוב — but I want a rematch.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hit! You left it open — that\'s on you.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  AVI — Retiree park player. Chatty, street-smart.
  // ═══════════════════════════════════════════════════════════════
  static const aviLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Shalom shalom! Sit, sit. The bench is warm and the dice are ready.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '!נחמד Very nice! You remind me of the guy I beat yesterday.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Oy vey... I\'ve seen better moves from the pigeons in the park!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Avi wins! As always! Come tomorrow, I\'m here every day.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You beat me?! ...Don\'t tell the others. !מזל טוב',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Boom! To the bar! Avi doesn\'t miss a blot!',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Take your time, take your time. The park isn\'t closing.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  RINA — Mother figure. Warm but ruthless at the board.
  // ═══════════════════════════════════════════════════════════════
  static const rinaLines = <DialogueLine>[
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Come, motek. Sit down. Did you eat? Never mind — let\'s play.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '!יופי My child plays well! I taught you everything you know.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Oy... that was not your best moment. But I still love you.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'I win! Don\'t make that face. Here, have some rugelach.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'You beat your ima?! I\'m so proud! ...Now let me win the next one.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*sweetly* To the bar, motek. A mother shows no mercy on the board.',
    ),
  ];
}
