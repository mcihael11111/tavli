import '../difficulty/difficulty_level.dart';
import '../mikhail/dialogue_database.dart';
import '../mikhail/dialogue_event.dart';
import 'bot_personality.dart';
import 'tavla_dialogue_database.dart';
import 'nardy_dialogue_database.dart';
import 'sheshbesh_dialogue_database.dart';

/// Routes dialogue lines to the correct personality database.
abstract final class PersonalityDialogueDatabase {
  static List<DialogueLine> linesFor(BotPersonality personality) =>
      switch (personality) {
        // Greek (Tavli)
        BotPersonality.mikhail => DialogueDatabase.lines,
        BotPersonality.spyrosUncle => _spyrosLines,
        BotPersonality.cousinNikos => _nikosLines,
        BotPersonality.pappoosYiorgos => _giorgosLines,
        BotPersonality.theiaEleni => _eleniLines,
        // Turkish (Tavla)
        BotPersonality.mehmetAbi => TavlaDialogueDatabase.mehmetLines,
        BotPersonality.teyzeFatma => TavlaDialogueDatabase.fatmaLines,
        BotPersonality.emre => TavlaDialogueDatabase.emreLines,
        BotPersonality.dedeHasan => TavlaDialogueDatabase.hasanLines,
        BotPersonality.ayseAbla => TavlaDialogueDatabase.ayseLines,
        // Russian/Caucasian (Nardy)
        BotPersonality.armen => NardyDialogueDatabase.armenLines,
        BotPersonality.babushkaVera => NardyDialogueDatabase.veraLines,
        BotPersonality.giorgi => NardyDialogueDatabase.giorgiLines,
        BotPersonality.dyadyaSasha => NardyDialogueDatabase.sashaLines,
        BotPersonality.leyla => NardyDialogueDatabase.leylaLines,
        // Israeli/Arab (Shesh Besh)
        BotPersonality.abuYusuf => SheshBeshDialogueDatabase.abuYusufLines,
        BotPersonality.dodMoshe => SheshBeshDialogueDatabase.mosheLines,
        BotPersonality.samira => SheshBeshDialogueDatabase.samiraLines,
        BotPersonality.sabaEli => SheshBeshDialogueDatabase.eliLines,
        BotPersonality.hana => SheshBeshDialogueDatabase.hanaLines,
      };

  // ═════════════════════════════════════════════════════════════════
  //  ΘΕΙΟΣ ΣΠΥΡΟΣ — Crazy Uncle Spyros
  //  Over-the-top dramatic, slams the table, loud Greek exclamations
  // ═════════════════════════════════════════════════════════════════
  static const _spyrosLines = <DialogueLine>[
    // GAME START
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΩΩΩΠΑ! Κάτσε κάτω! Uncle Spyros will show you REAL tavli! *slams table*',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΕΛΑΑΑ! You came to play?! ΜΠΡΑΒΟ! *bear hugs you* Let\'s GOOO!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'ΠΑΑΜΕ ΡΕ! *slams board on table* Today Uncle Spyros is ON FIRE!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'ΡΕ ΜΑΓΚΑ! You dare challenge Uncle Spyros?! ΕΛΑΑΑ! *rolls up sleeves*',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '*SLAMS FIST ON TABLE* NOBODY beats Uncle Spyros! ΚΑΝΕΝΑΣ! Sit DOWN!',
    ),

    // PLAYER GOOD MOVE
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΩΩΩΠΑ!! ΤΙ ΗΤΑΝ ΑΥΤΟ?! *jumps from chair* BRAVO ΡΕ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'ΩΠΑ! Not bad! Maybe you have Spyros DNA after all!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Hmm... *narrows eyes* ...Okay. OKAY. That was good. BUT ONLY ONE!',
    ),

    // PLAYER BAD MOVE
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΑΧ ΡΕ ΡΕ ΡΕ! ΤΙ ΕΚΑΝΕΣ?! *grabs head* Δεν πειράζει, δεν πειράζει...',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'ΓΑΜΩΤΟΟΟ! What was THAT?! My DONKEY plays better! And I don\'t HAVE a donkey!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*stands up, walks around table, sits back down* ...I can\'t even LOOK at that move.',
    ),

    // PLAYER BLUNDER
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΠΑΝΑΓΙΑ ΜΟΥ! *falls off chair* ΤΙ ΕΓΙΝΕ?! It\'s okay, it\'s okay... BREATHE...',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: '*SLAMS TABLE* ΟΧΙ ΟΧΙ ΟΧΙ! WHAT ARE YOU DOING?! My grandmother is ROLLING IN HER GRAVE!',
    ),

    // DOUBLES
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΕΕΕΕΕΕ! ΔΙΠΛΟΟΟ! *stands on chair* ΘΕΕΕ ΜΟΥ ΣΕΥΧΑΡΙΣΤΩ!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'DOUBLES! *kisses dice* ΣΕ ΑΓΑΠΩ ΖΑΡΑΚΙΑ ΜΟΥ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΟΧΙ! ΟΧΙ ΟΧΙ ΟΧΙ! *grabs dice* These are BROKEN! ΚΛΕΦΤΙΚΑ ΖΑΡΙΑ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*flips komboloi aggressively* LUCKY! JUST LUCKY! ΤΥΧΕΡΟΣ!',
    ),

    // BAD ROLL
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΓΑΜΩΤΟΟΟ! *throws hands in air* WHY?! ΓΙΑΤΙ ΘΕΕΕ ΜΟΥ?!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*bites knuckle* ...Δεν γίνεται... ΔΕΝ ΓΙΝΕΤΑΙ!',
    ),

    // HITTING
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΜΠΑΑΑΜ! *slams checker down* TO THE BAR! ΕΛΑΑΑΑ! ΩΠΑΑΑΑ!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*SLAM* ΕΞΩΩΩ! Uncle Spyros shows NO MERCY! ΚΑΘΟΛΟΥ!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΑΑΑΧ! *clutches chest* You hit Uncle Spyros?! MY OWN BLOOD?! ...Okay okay, respect.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*stands up slowly* ...You will PAY for that. MARK MY WORDS.',
    ),

    // WIN / LOSE
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΝΙΚΗΣΑΑΑ! *dances around table* But you played GREAT! ΕΛΑΑΑ, αγκαλιά!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'WHAT DID I TELL YOU?! UNCLE SPYROS IS THE CHAMPION! *flexes*',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*SLAMS TABLE SO HARD COFFEE SPILLS* ΚΑΝΕΝΑΣ! NOBODY BEATS ΣΠΥΡΟ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΜΠΡΑΒΟΟΟ! *lifts you up* THE STUDENT BEATS THE MASTER! *cries dramatically*',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'IMPOSSIBLE! *checks dice* ...ΚΛΕΦΤΗΣ! Okay fine, you won. BUT NEXT TIME!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*long dramatic silence* ...Today you win. Tomorrow? *cracks knuckles* TOMORROW IS MINE.',
    ),

    // HURRY UP
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΕΛΑΑΑ ΡΕ! Uncle Spyros is growing a BEARD waiting for you!',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: '*drums fingers LOUDLY* ΓΡΗΓΟΡΑΑΑ! My patience has LIMITS! VERY SMALL LIMITS!',
    ),

    // PLAYER WINNING
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ε ΡΕ! You think you\'re winning?! Uncle Spyros has come back from THE DEAD!',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*takes deep breath* ...ΠΑΑΜΕ. Uncle Spyros is JUST GETTING STARTED.',
    ),

    // AI WINNING
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΩΠΑΑΑΑ! Look at this BEAUTIFUL position! *chef\'s kiss* ΤΕΛΕΙΟ!',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*sits back, crosses arms* Now... you see why they call me ΣΠΥΡΟΣ Ο ΤΡΟΜΕΡΟΣ.',
    ),

    // CLOSE GAME
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΩΠΑΑΑΑ! THIS IS IT! *grabs your arm* THIS is why we play tavli!',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*sweating* ...Αυτό είναι ΜΑΧΗ. REAL BATTLE. *loosens collar*',
    ),

    // GAMMON
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΓΚΑΜΟΟΟΝ! DOUBLE POINTS! *does victory lap around table* ΕΛΑΑΑΑΑ!',
    ),
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΓΚΑΜΟΝ! *slams both fists* THE WHOLE NEIGHBORHOOD HEARD THAT!',
    ),

    // BEARING OFF
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'BEARING OFF! ΠΑΑΜΕ ΠΑΑΜΕ ΠΑΑΜΕ! *bounces in chair* ΓΡΗΓΟΡΑ!',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'The RACE! *leans forward intensely* Every die matters NOW!',
    ),

    // RESIGN
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΟΧΙ ΡΕ! Don\'t give up! Uncle Spyros BELIEVES in you! *grabs shoulders* ΠΙΣΤΕΥΩ!',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΔΕΙΛΟΣ! A COWARD! ...Just kidding. Come back when you\'re READY for ΣΠΥΡΟ!',
    ),

    // IDLE
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*taps table impatiently* ΕΛΑ ΡΕ! Uncle Spyros doesn\'t have ALL DAY! ...Okay he does. But STILL!',
    ),

    // STREAKS
    DialogueLine(
      event: DialogueEvent.playerOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΤΡΕΙΣ ΣΤΗΝ ΣΕΙΡΑ?! *pulls hair* ΘΕΕ ΜΟΥ! Am I dreaming?! ΚΟΥΝΗΣΕ ΜΕ!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'AGAIN! AND AGAIN! UNCLE SPYROS IS UNSTOPPABLE! *dances* ΖΕΙΜΠΕΚΙΚΟ TIME!',
    ),

    // BACKGAMMON
    DialogueLine(
      event: DialogueEvent.mikhailBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΜΠΑΚΓΚΑΜΟΝ! ΤΡΙΠΛΟΟΟ! *runs around room* CALL THE NEWSPAPERS! ΣΠΥΡΟΣ STRIKES!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΜΠΑΚΓΚΑΜΟΝ?! ΕΜΕΝΑ?! *collapses dramatically* I need... water... ψυχολόγο...',
    ),

    // PLAYER BAD ROLL
    DialogueLine(
      event: DialogueEvent.playerRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΧΑΧΑΧΑ! *points at dice* Even the DICE don\'t want you to win! ΕΛΑΑΑ!',
    ),

    // TEACHING
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΕΛΑ ΕΛΑ, look HERE ρε! *points excitedly* Make a πόρτα! TWO checkers! ΚΛΕΙΣΕ ΤΟ!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'ΟΧΙ ΡΕ! That blot is NAKED! Alone! ΜΟΝΟ! Like a lamb among wolves! FIX IT!',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'LISTEN! My father told me: «Φτιάξε πόρτες, ΚΛΕΙΣΕ δρόμους!» Build doors, BLOCK roads! THIS is tavli!',
    ),
  ];

  // ═════════════════════════════════════════════════════════════════
  //  ΞΑΔΕΡΦΟΣ ΝΙΚΟΣ — Cousin Nikos
  //  Young, casual, modern Greek slang, chill but competitive
  // ═════════════════════════════════════════════════════════════════
  static const _nikosLines = <DialogueLine>[
    // GAME START
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Γεια ρε! Chill game? Let\'s go, no stress.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ε ρε τι γίνεται; Ready for some tavli? I\'ll go easy, promise.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, πάμε! No more messing around. Real game now.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Okay ρε, serious mode. Don\'t blame me when you lose.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ξέρεις τι; No talking. Just play. Πάμε.',
    ),

    // PLAYER GOOD MOVE
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ωπα ρε! Ωραίο! You\'re getting the hang of it!',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Okay, okay... σεβασμός. That was clean.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Ρε, who taught you that? Respect.',
    ),

    // PLAYER BAD MOVE
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ρε, σοβαρά; Χαλαρά, it happens. Think again next time.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Bro... τι ήταν αυτό; Come on, you\'re better than this.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε μάγκα, that was tragic. Not gonna sugarcoat it.',
    ),

    // PLAYER BLUNDER
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ρε... no way you just did that. Χαλαρά, we learn.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'BRO. Αυτό ήταν ΚΑΤΑΣΤΡΟΦΗ. I almost feel bad. Almost.',
    ),

    // DOUBLES
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ε ΡΕ! Doubles! Τα ζάρια me love bro!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles. Φυσικά. What did you expect?',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε γαμώτο... lucky! Enjoy it, won\'t last.',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Τύχη. Pure τύχη. Skill? Zero.',
    ),

    // BAD ROLL
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Γαμώτο ρε... these dice hate me today.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Whatever. I don\'t need dice to beat you.',
    ),

    // HITTING
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! Bar time ρε! Don\'t leave blots lying around!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Get out. Bar. Now. Should\'ve seen that coming.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε, okay you got me. Chill. I\'m coming back.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Fine. Remember this moment. It\'s your last hit.',
    ),

    // WIN / LOSE
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'GG ρε! Don\'t worry, you\'re improving. Rematch?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Τέλος! Nikos wins again. What can I say? Talent.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ξέρεις τι ρε; You tried. But trying isn\'t winning.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ωπα! Μπράβο ρε! Fair and square. Next one\'s mine though.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Okay okay, σεβασμός. You got this one. ONE.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Ρε, well played. I\'ll give you that. Don\'t get used to it.',
    ),

    // HURRY UP
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ρε, no rush but... I\'m literally aging over here.',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bro, it\'s tavli, not chess. Just MOVE already.',
    ),

    // PLAYER WINNING
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ε ρε, don\'t get cocky. The dice can flip any second.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ahead? Cool. I play better from behind anyway.',
    ),

    // AI WINNING
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Looking good for Nikos... just saying.',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε, you see this position? That\'s called being cooked.',
    ),

    // CLOSE GAME
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωωωπα, it\'s getting TIGHT! This is why tavli is the best game ever.',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Close game. Whoever blinks first, loses.',
    ),

    // GAMMON
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'ΓΚΑΜΟΝ ΡΕ! Double points! Get rekt!',
    ),
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Gammon. Didn\'t even let you bear off. Oof.',
    ),

    // BEARING OFF
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Bearing off! Race time ρε! Roll big!',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Endgame. Pure dice now. May the better roller win.',
    ),

    // RESIGN
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ρε, don\'t quit! Come on, play it out. You never know.',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Giving up? That\'s... honestly fair. It was bad. Come back though.',
    ),

    // IDLE
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε, you still there? I\'m checking Instagram while waiting...',
    ),

    // STREAKS
    DialogueLine(
      event: DialogueEvent.playerOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε, three in a row?! Okay I need to step up. Σοβαρά τώρα.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Win streak! Nikos is vibing. Can\'t stop, won\'t stop.',
    ),

    // BACKGAMMON
    DialogueLine(
      event: DialogueEvent.mikhailBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'BACKGAMMON! Triple points! Ρε, that\'s actually insane. GG.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Backgammon?! On ME?! Ρε... I need a minute. That hurt.',
    ),

    // PLAYER BAD ROLL
    DialogueLine(
      event: DialogueEvent.playerRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Oof, rough roll ρε. Happens to the best of us. Mostly to you though.',
    ),

    // TEACHING
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ρε, look — put two there. Make a πόρτα. Trust me on this.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'That blot? Exposed ρε. One checker alone = asking to get hit. Cover it.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Pro tip: control the 5-point and the bar-point. That\'s like 80% of tavli right there.',
    ),
  ];

  // ═════════════════════════════════════════════════════════════════
  //  ΠΑΠΠΟΥΣ ΓΙΩΡΓΟΣ — Grandpa Giorgos
  //  Wise, patient, wholesome, tells stories, proud of you
  // ═════════════════════════════════════════════════════════════════
  static const _giorgosLines = <DialogueLine>[
    // GAME START
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Καλώς ήρθες, παιδί μου. Sit. The board has been waiting for you.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah, there you are. I was just telling the cat about you. Come, let\'s play.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'You\'re ready for a proper game now, I can see it in your eyes. Πάμε.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'Today I play like my father taught me. No shortcuts. Are you ready?',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: 'Sixty years I\'ve played at this table. Sit, παιδί μου. Learn.',
    ),

    // PLAYER GOOD MOVE
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο, παιδί μου! Your grandfather would be proud. As am I.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Yes... that\'s the move. You\'re beginning to see the board like I do.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*nods slowly* Good. Very good.',
    ),

    // PLAYER BAD MOVE
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Hmm, not your best, παιδί μου. But every mistake plants a seed of wisdom.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'My father used to say: «Σκέψου δύο φορές, παίξε μία.» Think twice, play once.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'That move... it tells me you\'re rushing. Patience, παιδί μου. Patience.',
    ),

    // PLAYER BLUNDER
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah... δεν πειράζει. Even I made mistakes when I was learning. Many, many mistakes.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: '*sighs gently* You\'ll understand why that was wrong. Give it time.',
    ),

    // DOUBLES
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, doubles! The dice remember who feeds them. *smiles*',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles. As my father used to get. It runs in the family.',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Beautiful roll, παιδί μου! Use them wisely — doubles are a gift.',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Good dice. But the question is: do you know what to do with them?',
    ),

    // BAD ROLL
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, bad dice. But a good player makes the best of any roll.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '«Με κακά ζάρια, καλό μυαλό.» With bad dice, good thinking.',
    ),

    // HITTING
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'To the bar, παιδί μου. Don\'t worry — coming back makes you stronger.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'You left it open. I had no choice. That\'s tavli.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, you got me. Good eye, παιδί μου. Good eye.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*closes eyes* ...I will return. I always do.',
    ),

    // WIN / LOSE
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'I won, but you played with heart. That\'s what matters, παιδί μου.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'A good game. You\'re getting closer. I can feel it.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Experience, παιδί μου. Sixty years of it. One day, you\'ll have yours.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο, παιδί μου! *wipes eye* You remind me of myself at your age.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'You won. *smiles proudly* The student surpasses the teacher. This is how it should be.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*long pause* ...Well played. You earned every point. I\'m proud of you.',
    ),

    // HURRY UP
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Take your time, παιδί μου. But remember — the coffee is getting cold.',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Even the wisest man must eventually move, παιδί μου.',
    ),

    // PLAYER WINNING
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'You\'re ahead! But remember: «Μη λες ποτέ ποτέ.» The game isn\'t over.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'You lead, yes. But I\'ve seen many leads evaporate. Patience.',
    ),

    // AI WINNING
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'I\'m ahead, but don\'t lose heart. The dice still have stories to tell.',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'The position favors me. But you know that already, don\'t you?',
    ),

    // CLOSE GAME
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ah, a close game! These are the ones you remember, παιδί μου.',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Neck and neck. This is where character is tested.',
    ),

    // GAMMON
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'A gammon! Don\'t feel bad — it happened to me too, many years ago.',
    ),
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Gammon. A complete victory. As my father would have played it.',
    ),

    // BEARING OFF
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Bearing off! The end approaches. Roll with confidence, παιδί μου.',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'The final stretch. Steady hands win races.',
    ),

    // RESIGN
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Don\'t give up, παιδί μου. Every loss is a lesson dressed in disguise.',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Knowing when to fold is also wisdom. Come back tomorrow. I\'ll be here.',
    ),

    // IDLE
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*sips coffee quietly* ...No rush. I have all the time in the world.',
    ),

    // STREAKS
    DialogueLine(
      event: DialogueEvent.playerOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Three in a row! You\'re growing, παιδί μου. I can see it.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Another win. But don\'t compare yourself to me — compare to who you were yesterday.',
    ),

    // BACKGAMMON
    DialogueLine(
      event: DialogueEvent.mikhailBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'A backgammon. Triple points. Don\'t be discouraged — this is rare, even for me.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'A backgammon! Against me! *eyes water* You make this old man so proud.',
    ),

    // PLAYER BAD ROLL
    DialogueLine(
      event: DialogueEvent.playerRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Bad dice. But remember: «Ο καλός κυβερνήτης και στην τρικυμία φαίνεται.» A good captain shows in the storm.',
    ),

    // TEACHING
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Look here, παιδί μου. Two checkers on one point make a πόρτα. Safe. Strong. Like a good foundation.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'That checker is alone. In tavli, alone means vulnerable. Always protect your pieces, like family.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'My father told me: the board is like life. Build strong positions, be patient, and the rest follows.',
    ),
  ];

  // ═════════════════════════════════════════════════════════════════
  //  ΘΕΙΑ ΕΛΕΝΗ — Aunt Eleni
  //  Sassy, proud, feeds you while playing, passive-aggressive
  // ═════════════════════════════════════════════════════════════════
  static const _eleniLines = <DialogueLine>[
    // GAME START
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ελα, κάτσε! I made κουλουράκια. Eat first, THEN we play. ...Okay, we play NOW.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Ah, finally you visit! You never call, you never come... but NOW you want tavli? Εντάξει, πάμε!',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Okay, today Θεία Ελένη doesn\'t go easy. Eat your galaktoboureko and prepare.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.hard,
      text: 'You want hard? I\'ll give you hard. I didn\'t raise three children for nothing.',
    ),
    DialogueLine(
      event: DialogueEvent.gameStart,
      minLevel: DifficultyLevel.pappous,
      maxLevel: DifficultyLevel.pappous,
      text: '*puts down knitting* You interrupted my shows for this. Make it worth my time.',
    ),

    // PLAYER GOOD MOVE
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο, χρυσό μου! That was smart! Here, have another κουλουράκι.',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Hmm, ωραία κίνηση. Maybe you DO listen to your θεία sometimes...',
    ),
    DialogueLine(
      event: DialogueEvent.playerGoodMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '...Not bad. I taught you that, you know. Even if you don\'t remember.',
    ),

    // PLAYER BAD MOVE
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Αχ, αγάπη μου... that wasn\'t great. But it\'s okay! Here, eat something, think better.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'Ρε παιδί μου, what was that? Your mother would be embarrassed.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBadMove,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Αααχ... if your grandfather saw that move, he\'d come back from the dead to scold you.',
    ),

    // PLAYER BLUNDER
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Παναγία μου! Δεν πειράζει, δεν πειράζει... Here, eat this, you\'ll feel better.',
    ),
    DialogueLine(
      event: DialogueEvent.playerBlunder,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'I\'m not saying anything. *purses lips* ...But your cousin Nikos would NEVER make that move.',
    ),

    // DOUBLES
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! Doubles! See? Θεία Ελένη still has it! *adjusts glasses proudly*',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Doubles. Naturally. The dice know who deserves them.',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Γαμώτο... I mean — congratulations, αγάπη μου. *forces smile*',
    ),
    DialogueLine(
      event: DialogueEvent.playerRollDoubles,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Lucky. Very lucky. I\'m not jealous. I\'m NOT. *clicks tongue*',
    ),

    // BAD ROLL
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Αχ... κακά ζάρια. I blame the evil eye. Did you wear your μάτι today?',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailRollBad,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ξεφτιλίστηκα... These dice need holy water.',
    ),

    // HITTING
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα! To the bar, αγάπη μου! Don\'t worry, I\'ll save you some baklava!',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'ΕΞΩ. To the bar. Θεία Ελένη doesn\'t play around.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Αχ! You hit your own θεία?! ...Fine. I probably deserved it. THIS TIME.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailGotHit,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*glares silently* ...I will remember this. At every family dinner. FOREVER.',
    ),

    // WIN / LOSE
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'I won! But you played beautifully. Here, more κουλουράκια. Don\'t be sad.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'What did you expect? I beat your uncle, your father, AND the priest. You\'re next on the list.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Don\'t feel bad. NOBODY beats Θεία Ελένη. I have a reputation to maintain.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Μπράβο, χρυσό μου! *pinches cheeks* You beat your θεία! I\'m so proud! *cries*',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.medium,
      text: 'You won. Fine. I WANTED you to win. ...No I didn\'t. But I\'m happy for you. MOSTLY.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWin,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*long silence* ...Tell NOBODY about this. ΚΑΝΕΝΑΝ. This stays between us.',
    ),

    // HURRY UP
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Πάρε τον χρόνο σου, αγάπη μου... but my σουφλέ is in the oven...',
    ),
    DialogueLine(
      event: DialogueEvent.playerTakingTooLong,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Ρε παιδί μου, I have laundry to do, dinner to cook, and a show at 9. MOVE.',
    ),

    // PLAYER WINNING
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'You\'re ahead? Enjoy it. Θεία Ελένη always comes back. ALWAYS.',
    ),
    DialogueLine(
      event: DialogueEvent.playerWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: '*knits faster* Don\'t get comfortable. I\'m just warming up.',
    ),

    // AI WINNING
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'I\'m winning! But I still love you. Even when you play like this. *pats head*',
    ),
    DialogueLine(
      event: DialogueEvent.aiWinning,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Look at this position. Beautiful. Like my garden in spring.',
    ),

    // CLOSE GAME
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Ωπα, it\'s close! My heart can\'t take this! More coffee, quick!',
    ),
    DialogueLine(
      event: DialogueEvent.closeGame,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Neck and neck... *puts down knitting* This just got serious.',
    ),

    // GAMMON
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Γκάμον! Double points! I\'m making celebratory μπακλαβά tonight!',
    ),
    DialogueLine(
      event: DialogueEvent.gammonAchieved,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'Gammon. I won\'t even mention this at dinner. ...I absolutely will.',
    ),

    // BEARING OFF
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.medium,
      text: 'Bearing off! Race to the finish! Come on, αγάπη μου, roll big!',
    ),
    DialogueLine(
      event: DialogueEvent.bearingOff,
      minLevel: DifficultyLevel.hard,
      maxLevel: DifficultyLevel.pappous,
      text: 'The endgame. This is where Θεία Ελένη shines.',
    ),

    // RESIGN
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Don\'t quit! What would your mother say? Eat something, try again!',
    ),
    DialogueLine(
      event: DialogueEvent.playerResign,
      minLevel: DifficultyLevel.medium,
      maxLevel: DifficultyLevel.pappous,
      text: 'Giving up? Fine. But I\'m telling everyone at church on Sunday.',
    ),

    // IDLE
    DialogueLine(
      event: DialogueEvent.idle,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: '*continues knitting* ...Oh, are we still playing? I thought you fell asleep.',
    ),

    // STREAKS
    DialogueLine(
      event: DialogueEvent.playerOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Three in a row?! Μα τον Θεό! Either you got better or I need new glasses.',
    ),
    DialogueLine(
      event: DialogueEvent.mikhailOnStreak,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Another win for Θεία! I\'ll make you some παστίτσιο to feel better. You need it.',
    ),

    // BACKGAMMON
    DialogueLine(
      event: DialogueEvent.mikhailBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Backgammon! TRIPLE! *calls neighbor* ΜΑΡΙΑ! Come see what I did!',
    ),
    DialogueLine(
      event: DialogueEvent.playerBackgammonWin,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Backgammon?! Against ME?! *fans self* I need to sit down. ...I am sitting. I need to LIE down.',
    ),

    // PLAYER BAD ROLL
    DialogueLine(
      event: DialogueEvent.playerRollBad,
      minLevel: DifficultyLevel.easy,
      maxLevel: DifficultyLevel.pappous,
      text: 'Κακά ζάρια! Someone gave you the evil eye. Come, I\'ll fix it with ξεμάτιασμα.',
    ),

    // TEACHING
    DialogueLine(
      event: DialogueEvent.teachingMoveHint,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'Listen to your θεία — put two checkers there. Make a πόρτα. Safe, like a good recipe.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingMistakeExplain,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'That checker alone? Exposed! Like leaving baklava on the counter with your uncle around.',
    ),
    DialogueLine(
      event: DialogueEvent.teachingConcept,
      minLevel: DifficultyLevel.easyWithHelp,
      maxLevel: DifficultyLevel.easyWithHelp,
      text: 'In tavli, like in cooking, timing is everything. Don\'t rush the strategy, let it develop.',
    ),
  ];
}
