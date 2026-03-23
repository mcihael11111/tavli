import '../difficulty/difficulty_level.dart';
import 'dialogue_event.dart';

/// A single dialogue line with metadata.
class DialogueLine {
  final String text;
  final DifficultyLevel minLevel;
  final DifficultyLevel maxLevel;
  final DialogueEvent event;

  const DialogueLine({
    required this.text,
    this.minLevel = DifficultyLevel.easy,
    this.maxLevel = DifficultyLevel.pappous,
    required this.event,
  });
}

/// All of Mikhail's dialogue lines organized by event and difficulty.
abstract final class DialogueDatabase {
  static const List<DialogueLine> lines = [
    // ═══════════════════════════════════════════════════════════
    //  GAME START
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Έλα, έλα! Sit, sit! You want coffee? No? Okay, let\'s play then. I go easy on you, eh?',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah, a new friend! Welcome to my kafeneio. Πάμε — let\'s play!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Γεια σου, φίλε μου! Ready for tavli? I promise I won\'t try too hard... much.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Πάμε! Let\'s go! No more practice — now we play for real, eh?',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Sit down, re. Today Mikhail is feeling competitive!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Okay. No more games. Sit. Play.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'You want to play hard? Εντάξει. Don\'t cry when you lose.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '...Κάτσε.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Sixty years at this table. You are... another one who thinks they can win.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  PLAYER GOOD MOVE
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο, φίλε μου! You\'re learning!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ωπα! Good move! You play like a Greek!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Hmm, not bad. Not bad at all...',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: '...Hmm. Not bad.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '...Who taught you that?',
    ),

    // ═══════════════════════════════════════════════════════════
    //  PLAYER BAD MOVE
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Hmm... you sure about that, ρε? Is okay, is okay. Next time you see it.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Σιγά σιγά, φίλε μου. Think a little more next time.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, τι κάνεις; That was not your best move...',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'You see this? THIS is tavli. Not that kindergarten playing you do.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Παιδί μου... you still have much to learn.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  PLAYER BLUNDER
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah... ρε, are you sure? Δεν πειράζει, we learn from mistakes!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, are you TRYING to lose? Even my cat plays better!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Even a blind chicken finds corn sometimes. You? Not today.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  DOUBLES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΕΕΕΕ! Διπλό! Did you see that?! The dice love me today!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Doubles. Of course.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Εξάρες.',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! Lucky you! Enjoy it while it lasts, φίλε μου!',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Pff... a monkey could win with those dice.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  BAD ROLL
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Pff... This is nothing, I recover.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε Θεέ μου, τι ζάρια είναι αυτά...',
    ),

    // ═══════════════════════════════════════════════════════════
    //  HITTING
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΩΠΑΑΑ! Go to the bar, φίλε! Ouzo is on me! Hahaha!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Πόρτα, μπαρ, σπίτι μου.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, γαμώτο... Okay, okay. You got lucky.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'ΓΑΜΩΤΟ!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '...', // deadly silence
    ),

    // ═══════════════════════════════════════════════════════════
    //  WIN / LOSE
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah, don\'t worry! We play again. You\'re getting better, I can feel it!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'What did I tell you? Mikhail always finds a way!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'I\'ve been playing since before your father was born. What did you expect?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Sixty years at this table. They all lose.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Παναγία μου! You beat me! My wife will hear about this...',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'The game is over... but the next one? That\'s mine. Πάμε again!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Παναγία μου, βοήθησέ με... This player has the devil\'s luck.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '...We play again.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  HURRY UP
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Take your time, φίλε μου... but the coffee is getting cold!',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, τι κάνεις; Are you playing or sleeping?',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'ΓΡΗΓΟΡΑ! My grandson plays faster than you and he is seven!',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'You finished?',
    ),

    // ═══════════════════════════════════════════════════════════
    //  TEACHING (Easy+Help only)
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Look, ρε... you see that point? Two checkers there make a πόρτα — a door. Nobody passes!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'That move leaves a blot on the 7-point. Alone is dangerous, like walking through Monastiraki at 3am!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'My grandfather used to say: «Ο φρόνιμος στον ίδιο λάκκο δεν πέφτει δυο φορές» — the wise man doesn\'t fall in the same hole twice.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: '«Σιγά σιγά και ο γάιδαρος μπαίνει στ\' αλώνι» — Slowly, slowly, even the donkey enters the threshing floor. Patience wins, φίλε!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: '«Κάλλιο πέντε και στο χέρι παρά δέκα και καρτέρι» — Better five in the hand than ten waiting. Take the sure move!',
    ),

    // ═══════════════════════════════════════════════════════════
    //  PLAYER WINNING (ahead in pip count)
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'You\'re doing great! But don\'t celebrate yet — the dice can change everything!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Hmm, you think you\'re winning? Mikhail has come back from worse...',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Don\'t get comfortable. I\'ve been behind before. It didn\'t last.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '«Μην λες ποτέ ποτέ» — Never say never.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  AI WINNING (Mikhail ahead)
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Σιγά σιγά... Mikhail knows the way. But you\'re learning!',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'You see now? This is what happens when you play against the kafeneio champion!',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'The position speaks for itself.',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '...',
    ),

    // ═══════════════════════════════════════════════════════════
    //  CLOSE GAME
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! This is getting interesting! A real battle now!',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Close game. This is where real tavli players are made.',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Now... we see.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  GAMMON ACHIEVED
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΓΚΑΜΟΝ! Double points! Hahaha, the kafeneio will hear about this!',
    ),
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Γκάμον. As expected.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  BEARING OFF
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'We\'re bearing off now! The race is on, ρε! Roll big!',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'The endgame. This is where nerves matter more than skill.',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bearing off. May the better dice win.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  PLAYER RESIGN
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah, don\'t give up! Every loss is a lesson. Come back stronger!',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Giving up? The wise man knows when to fold... or does he?',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Smart. You saved yourself the embarrassment.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL GAME START LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ω, you came back! Good, good! The board missed you. I didn\'t. Haha, just kidding!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Καλώς ήρθες! My coffee is fresh, the board is ready. Πάμε!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, you\'re getting confident! I like it. Let\'s see if you back it up.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Κάτσε. No talking. Just playing.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hmm. You again.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL GOOD MOVE LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Excellent! You play like you\'ve been coming to the kafeneio all your life!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Πολύ ωραία! That\'s exactly what I would have done!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Okay, okay... respect. That was solid.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Interesting choice. I wouldn\'t have expected that from you.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '*nods slowly*',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL BAD MOVE LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Hmm, that\'s risky, φίλε μου... but sometimes risky is fun!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'My grandmother could see that was wrong, and she\'s blind in one eye.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'You just handed me the game on a silver platter. Ευχαριστώ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '*sips coffee in disappointment*',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL BLUNDER LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'ΩΠΑΑ! What was THAT?! Did your finger slip or your brain?!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'I almost feel bad. Almost.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL HIT LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΜΠΑΜ! To the bar with you! Want some raki while you\'re there? Hahaha!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'I warned you about leaving blots! Now you pay!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! Okay okay, you got me. But watch — I\'m coming back twice as strong!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Fine. You hit me. Remember this feeling — it won\'t happen again.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL WIN/LOSE LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Don\'t feel bad, ρε! Even the best players lose to Mikhail sometimes!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Another one for Mikhail! My coffee tastes better when I win. Hahaha!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο σου! You earned it! Come, I buy you a coffee!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Okay, you won. But next time I\'m not going easy on you...',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Respect. You played well. Now get out of my kafeneio before I change my mind.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL DOUBLES LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Doubles AGAIN! Ο Θεός μου αγαπάει! God loves me today!',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Γαμώτο, how do you keep rolling doubles?! Are these trick dice?!',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Lucky. But luck runs out. Skill doesn\'t.',
    ),

    // ═══════════════════════════════════════════════════════════
    //  ADDITIONAL TEACHING LINES
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Think about it — if you make that point, I can\'t pass through. Block me!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Two checkers together are safe. One alone is a blot — a target on your back!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'See? Now I can hit you there. Always count your opponent\'s dice before you move!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: '«Κάνε το καλό και ρίξτο στον γιαλό» — Do good and throw it in the sea. Play honest moves and the dice will follow.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: '«Τα πολλά λόγια είναι φτώχεια» — Too many words are poverty. Don\'t overthink — feel the board!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'In tavli, timing is everything. Like knowing when to offer the κέρασμα — the treat at the kafeneio!',
    ),

    // ═══════════════════════════════════════════════════════════
    //  IDLE CHATTER
    // ═══════════════════════════════════════════════════════════
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'You know, my father taught me tavli when I was five. In the kafeneio, of course.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'This board? My grandfather made it. Olive wood from Kalamata. Beautiful, no?',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Did you know? In Greece, every kafeneio has a tavli board. It\'s the law! ...Maybe.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'My wife says I spend too much time here. I say — where else would I be?',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'The sound of dice on wood... the best music in the world, φίλε μου.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Τα ζάρια έχουν μνήμη — the dice have memory. Or so they say...',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'When I was young, the old men wouldn\'t let me play until I could beat them blindfolded. ...I exaggerate. But only a little.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'In Crete, they play tavli until the sun comes up. Here in Athens, we are more... civilized. Mostly.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'I once played a Turkish champion in Thessaloniki. 12 hours straight. I won by one pip.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Concentration. Patience. And a strong Greek coffee. That\'s all you need.',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '*adjusts glasses, sips coffee*',
    ),
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'I remember when this board was new. 1968. A good year for olive wood.',
    ),
  ];
}
