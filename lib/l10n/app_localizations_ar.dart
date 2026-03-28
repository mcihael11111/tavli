// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Tables';

  @override
  String get subtitle => 'تقاليد الطاولة';

  @override
  String get homeGreetingMorning => 'صباح الخير! نلعب طاولة؟';

  @override
  String get homeGreetingAfternoon => 'بعد الظهر... وقت مثالي للعب!';

  @override
  String get homeGreetingEvening => 'مساء الخير! جولة أخيرة؟';

  @override
  String get playVsBot => 'العب ضد الروبوت';

  @override
  String get playVsBotSub => 'تحدَّ الخصم الذكي';

  @override
  String get playOnline => 'العب أونلاين';

  @override
  String get playOnlineSub => 'مباراة سريعة أو ادعُ صديقاً';

  @override
  String get passAndPlay => 'تبادل اللعب';

  @override
  String get passAndPlaySub => 'لاعبان، جهاز واحد';

  @override
  String get learnToPlay => 'تعلّم اللعب';

  @override
  String get learnToPlaySub => 'درس تفاعلي مع الروبوت';

  @override
  String get chooseDifficulty => 'اختر الصعوبة';

  @override
  String get difficultyEasy => 'سهل';

  @override
  String get difficultyEasyGreek => 'Εύκολο';

  @override
  String get difficultyEasyHelp => 'Easy + Help';

  @override
  String get difficultyEasyHelpGreek => 'Εύκολο με Βοήθεια';

  @override
  String get difficultyMedium => 'متوسط';

  @override
  String get difficultyMediumGreek => 'Μέτριο';

  @override
  String get difficultyHard => 'صعب';

  @override
  String get difficultyHardGreek => 'Δύσκολο';

  @override
  String get difficultyPappous => 'صعب جداً';

  @override
  String get difficultyPappousGreek => 'Παππούς';

  @override
  String get victory => '!فوز';

  @override
  String get victoryGreek => 'ΝΙΚΗ!';

  @override
  String get defeat => 'هزيمة';

  @override
  String get defeatGreek => 'ΗΤΤΑ';

  @override
  String get playAgain => 'العب مرة أخرى';

  @override
  String get changeDifficulty => 'Change Difficulty';

  @override
  String get home => 'الرئيسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get rating => 'التصنيف';

  @override
  String get games => 'المباريات';

  @override
  String get wins => 'الانتصارات';

  @override
  String get losses => 'الخسائر';

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
  String get customize => 'تخصيص';

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
  String get settings => 'الإعدادات';

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
  String get next => 'التالي';

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
  String get cancel => 'إلغاء';

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

  @override
  String get traditionTavli => 'تافلي';

  @override
  String get traditionTavla => 'طاولة';

  @override
  String get traditionNardy => 'نرد';

  @override
  String get traditionSheshBesh => 'شش بش';

  @override
  String get variantTavla => 'Tavla';

  @override
  String get variantTavlaSub => 'Turkish standard backgammon';

  @override
  String get variantTapa => 'Tapa';

  @override
  String get variantTapaSub => 'Turkish pinning variant';

  @override
  String get variantMoultezim => 'Moultezim';

  @override
  String get variantMoultezimSub => 'Turkish running variant';

  @override
  String get variantLongNard => 'Long Nard';

  @override
  String get variantLongNardSub => 'Running variant with head rule';

  @override
  String get variantShortNard => 'Short Nard';

  @override
  String get variantShortNardSub => 'Standard backgammon with doubling cube';

  @override
  String get variantSheshBesh => 'Shesh Besh';

  @override
  String get variantSheshBeshSub => 'Standard hitting game';

  @override
  String get variantMahbusa => 'Mahbusa';

  @override
  String get variantMahbusaSub => 'Arabic pinning variant';

  @override
  String get poolTradition => 'تقليدي';

  @override
  String get poolInternational => 'دولي';

  @override
  String get internationalMatch => 'International Match';

  @override
  String get internationalMatchSub => 'Play across traditions by game mechanic';

  @override
  String get canonicalRules => 'Canonical Rules';

  @override
  String get traditionSwitcher => 'التقليد';

  @override
  String get changeTradition => 'تغيير التقليد';
}
