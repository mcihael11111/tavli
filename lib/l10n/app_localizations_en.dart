// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tavli';

  @override
  String get subtitle => 'Greek Backgammon';

  @override
  String get homeGreetingMorning => 'Good morning! Ready for coffee and tavli?';

  @override
  String get homeGreetingAfternoon => 'Afternoon... perfect time for a game!';

  @override
  String get homeGreetingEvening => 'Getting late... one more game?';

  @override
  String get playVsBot => 'Play vs Bot';

  @override
  String get playVsBotSub => 'Challenge the AI opponent';

  @override
  String get playOnline => 'Play Online';

  @override
  String get playOnlineSub => 'Quick match or invite a friend';

  @override
  String get passAndPlay => 'Pass & Play';

  @override
  String get passAndPlaySub => 'Two players, one device';

  @override
  String get learnToPlay => 'Learn to Play';

  @override
  String get learnToPlaySub => 'Interactive tutorial with the bot';

  @override
  String get chooseDifficulty => 'Choose Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyEasyGreek => 'Εύκολο';

  @override
  String get difficultyEasyHelp => 'Easy + Help';

  @override
  String get difficultyEasyHelpGreek => 'Εύκολο με Βοήθεια';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyMediumGreek => 'Μέτριο';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyHardGreek => 'Δύσκολο';

  @override
  String get difficultyPappous => 'Extra Hard';

  @override
  String get difficultyPappousGreek => 'Παππούς';

  @override
  String get victory => 'Victory!';

  @override
  String get victoryGreek => 'ΝΙΚΗ!';

  @override
  String get defeat => 'Defeat';

  @override
  String get defeatGreek => 'ΗΤΤΑ';

  @override
  String get playAgain => 'Play Again';

  @override
  String get changeDifficulty => 'Change Difficulty';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get rating => 'Rating';

  @override
  String get games => 'Games';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get winRate => 'Win Rate';

  @override
  String get streak => 'Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get gammons => 'Gammons';

  @override
  String get recordByDifficulty => 'Record by Difficulty';

  @override
  String get customize => 'Customize';

  @override
  String get board => 'Board';

  @override
  String get checkers => 'Checkers';

  @override
  String get dice => 'Dice';

  @override
  String get customizationNote =>
      'Your selections will be applied in the next game.';

  @override
  String get settings => 'Settings';

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get showPipCount => 'Show Pip Count';

  @override
  String get showPipCountSub => 'Display remaining pip count during games';

  @override
  String get moveConfirmation => 'Move Confirmation';

  @override
  String get moveConfirmationSub => 'Require tap to confirm each move';

  @override
  String get optionalRules => 'Optional Rules';

  @override
  String get autoDoubles => 'Automatic Doubles';

  @override
  String get autoDoublesSub => 'Matching first rolls double the stakes';

  @override
  String get beavers => 'Beavers';

  @override
  String get beaversSub => 'Immediate redouble after being doubled';

  @override
  String get jacobyRule => 'Jacoby Rule';

  @override
  String get jacobyRuleSub => 'Gammons only count if cube was offered';

  @override
  String get audio => 'Audio';

  @override
  String get music => 'Music';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get mikhailVoice => 'Bot Voice';

  @override
  String get mikhailLanguage => 'Bot Language';

  @override
  String get langGreek => 'Greek';

  @override
  String get langEnglish => 'English';

  @override
  String get langMix => 'Mix (Default)';

  @override
  String get display => 'Display';

  @override
  String get theme => 'Theme';

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get themeAuto => 'Auto';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get tutorial => 'Learn';

  @override
  String get tutorialLessonBoard => 'The Board';

  @override
  String get tutorialLessonMoving => 'Moving Checkers';

  @override
  String get tutorialLessonHitting => 'Hitting & The Bar';

  @override
  String get tutorialLessonBearOff => 'Bearing Off';

  @override
  String get tutorialLessonStrategy => 'Strategy Tips';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get startPlaying => 'Start Playing!';

  @override
  String get matchHistory => 'Match History';

  @override
  String get noGamesYet => 'No games yet';

  @override
  String get achievements => 'Achievements';

  @override
  String get tapToRoll => 'Tap to Roll';

  @override
  String get pips => 'Pips';

  @override
  String get undo => 'Undo';

  @override
  String get resume => 'Resume';

  @override
  String get newGame => 'New Game';

  @override
  String get exitToHome => 'Exit to Home';

  @override
  String get pause => 'Pause';

  @override
  String passToPlayer(int player) {
    return 'Pass to Player $player';
  }

  @override
  String get soon => 'Soon';

  @override
  String get locked => 'Locked';

  @override
  String get noGamesPlayed => 'No games played';

  @override
  String get variantPortes => 'Portes';

  @override
  String get variantPortesSub => 'Standard backgammon';

  @override
  String get variantPlakoto => 'Plakoto';

  @override
  String get variantPlakotoSub => 'Pinning variant — trap your opponent';

  @override
  String get variantFevga => 'Fevga';

  @override
  String get variantFevgaSub => 'Running variant — no hitting';

  @override
  String get onlineLobby => 'Play Online';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get quickMatchSub => 'Find an opponent near your rating';

  @override
  String get createRoom => 'Create Room';

  @override
  String get createRoomSub => 'Invite a friend with a code or QR';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get joinRoomSub => 'Enter a room code or scan QR';

  @override
  String get roomCode => 'Room Code';

  @override
  String get waitingForOpponent => 'Waiting for opponent...';

  @override
  String get searchingForOpponent => 'Searching for opponent...';

  @override
  String get shareInvite => 'Share Invite';

  @override
  String get signIn => 'Sign In';

  @override
  String get playAsGuest => 'Play as Guest';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get resign => 'Resign';

  @override
  String get resignConfirm => 'Are you sure you want to resign?';

  @override
  String get cancel => 'Cancel';

  @override
  String get backToLobby => 'Back to Lobby';

  @override
  String get ratingChange => 'Rating';

  @override
  String get vs => 'vs';

  @override
  String get tutorialLessonCube => 'The Doubling Cube';

  @override
  String get achievementUnlocked => 'Achievement Unlocked';

  @override
  String get doubleOffer => 'Double!';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get greekLevelTitle => 'How Greek Should I Be?';

  @override
  String get greekLevelSubtitle =>
      'We can adjust the amount of Greek I use depending on your comfort level.';

  @override
  String get greekLevelEnglishOnly => 'English Only';

  @override
  String get greekLevelCantRead => 'Can\'t read Greek';

  @override
  String get greekLevelFluent => 'Fluent';

  @override
  String get greekLevelCanRead => 'Can read and write';

  @override
  String get greekLevelExample => 'Example';
}
