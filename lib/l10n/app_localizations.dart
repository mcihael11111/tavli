import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tavli'**
  String get appTitle;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Greek Backgammon'**
  String get subtitle;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Ready for coffee and tavli?'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon... perfect time for a game!'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Getting late... one more game?'**
  String get homeGreetingEvening;

  /// No description provided for @playVsBot.
  ///
  /// In en, this message translates to:
  /// **'Play vs Bot'**
  String get playVsBot;

  /// No description provided for @playVsBotSub.
  ///
  /// In en, this message translates to:
  /// **'Challenge the AI opponent'**
  String get playVsBotSub;

  /// No description provided for @playOnline.
  ///
  /// In en, this message translates to:
  /// **'Play Online'**
  String get playOnline;

  /// No description provided for @playOnlineSub.
  ///
  /// In en, this message translates to:
  /// **'Quick match or invite a friend'**
  String get playOnlineSub;

  /// No description provided for @passAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass & Play'**
  String get passAndPlay;

  /// No description provided for @passAndPlaySub.
  ///
  /// In en, this message translates to:
  /// **'Two players, one device'**
  String get passAndPlaySub;

  /// No description provided for @learnToPlay.
  ///
  /// In en, this message translates to:
  /// **'Learn to Play'**
  String get learnToPlay;

  /// No description provided for @learnToPlaySub.
  ///
  /// In en, this message translates to:
  /// **'Interactive tutorial with the bot'**
  String get learnToPlaySub;

  /// No description provided for @chooseDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Choose Difficulty'**
  String get chooseDifficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyEasyGreek.
  ///
  /// In en, this message translates to:
  /// **'Εύκολο'**
  String get difficultyEasyGreek;

  /// No description provided for @difficultyEasyHelp.
  ///
  /// In en, this message translates to:
  /// **'Easy + Help'**
  String get difficultyEasyHelp;

  /// No description provided for @difficultyEasyHelpGreek.
  ///
  /// In en, this message translates to:
  /// **'Εύκολο με Βοήθεια'**
  String get difficultyEasyHelpGreek;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyMediumGreek.
  ///
  /// In en, this message translates to:
  /// **'Μέτριο'**
  String get difficultyMediumGreek;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyHardGreek.
  ///
  /// In en, this message translates to:
  /// **'Δύσκολο'**
  String get difficultyHardGreek;

  /// No description provided for @difficultyPappous.
  ///
  /// In en, this message translates to:
  /// **'Extra Hard'**
  String get difficultyPappous;

  /// No description provided for @difficultyPappousGreek.
  ///
  /// In en, this message translates to:
  /// **'Παππούς'**
  String get difficultyPappousGreek;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @victoryGreek.
  ///
  /// In en, this message translates to:
  /// **'ΝΙΚΗ!'**
  String get victoryGreek;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @defeatGreek.
  ///
  /// In en, this message translates to:
  /// **'ΗΤΤΑ'**
  String get defeatGreek;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @changeDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Change Difficulty'**
  String get changeDifficulty;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @gammons.
  ///
  /// In en, this message translates to:
  /// **'Gammons'**
  String get gammons;

  /// No description provided for @recordByDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Record by Difficulty'**
  String get recordByDifficulty;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @checkers.
  ///
  /// In en, this message translates to:
  /// **'Checkers'**
  String get checkers;

  /// No description provided for @dice.
  ///
  /// In en, this message translates to:
  /// **'Dice'**
  String get dice;

  /// No description provided for @customizationNote.
  ///
  /// In en, this message translates to:
  /// **'Your selections will be applied in the next game.'**
  String get customizationNote;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettings;

  /// No description provided for @showPipCount.
  ///
  /// In en, this message translates to:
  /// **'Show Pip Count'**
  String get showPipCount;

  /// No description provided for @showPipCountSub.
  ///
  /// In en, this message translates to:
  /// **'Display remaining pip count during games'**
  String get showPipCountSub;

  /// No description provided for @moveConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Move Confirmation'**
  String get moveConfirmation;

  /// No description provided for @moveConfirmationSub.
  ///
  /// In en, this message translates to:
  /// **'Require tap to confirm each move'**
  String get moveConfirmationSub;

  /// No description provided for @optionalRules.
  ///
  /// In en, this message translates to:
  /// **'Optional Rules'**
  String get optionalRules;

  /// No description provided for @autoDoubles.
  ///
  /// In en, this message translates to:
  /// **'Automatic Doubles'**
  String get autoDoubles;

  /// No description provided for @autoDoublesSub.
  ///
  /// In en, this message translates to:
  /// **'Matching first rolls double the stakes'**
  String get autoDoublesSub;

  /// No description provided for @beavers.
  ///
  /// In en, this message translates to:
  /// **'Beavers'**
  String get beavers;

  /// No description provided for @beaversSub.
  ///
  /// In en, this message translates to:
  /// **'Immediate redouble after being doubled'**
  String get beaversSub;

  /// No description provided for @jacobyRule.
  ///
  /// In en, this message translates to:
  /// **'Jacoby Rule'**
  String get jacobyRule;

  /// No description provided for @jacobyRuleSub.
  ///
  /// In en, this message translates to:
  /// **'Gammons only count if cube was offered'**
  String get jacobyRuleSub;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @mikhailVoice.
  ///
  /// In en, this message translates to:
  /// **'Bot Voice'**
  String get mikhailVoice;

  /// No description provided for @mikhailLanguage.
  ///
  /// In en, this message translates to:
  /// **'Bot Language'**
  String get mikhailLanguage;

  /// No description provided for @langGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get langGreek;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langMix.
  ///
  /// In en, this message translates to:
  /// **'Mix (Default)'**
  String get langMix;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get tutorial;

  /// No description provided for @tutorialLessonBoard.
  ///
  /// In en, this message translates to:
  /// **'The Board'**
  String get tutorialLessonBoard;

  /// No description provided for @tutorialLessonMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving Checkers'**
  String get tutorialLessonMoving;

  /// No description provided for @tutorialLessonHitting.
  ///
  /// In en, this message translates to:
  /// **'Hitting & The Bar'**
  String get tutorialLessonHitting;

  /// No description provided for @tutorialLessonBearOff.
  ///
  /// In en, this message translates to:
  /// **'Bearing Off'**
  String get tutorialLessonBearOff;

  /// No description provided for @tutorialLessonStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy Tips'**
  String get tutorialLessonStrategy;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start Playing!'**
  String get startPlaying;

  /// No description provided for @matchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get matchHistory;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get noGamesYet;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @tapToRoll.
  ///
  /// In en, this message translates to:
  /// **'Tap to Roll'**
  String get tapToRoll;

  /// No description provided for @pips.
  ///
  /// In en, this message translates to:
  /// **'Pips'**
  String get pips;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @exitToHome.
  ///
  /// In en, this message translates to:
  /// **'Exit to Home'**
  String get exitToHome;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @passToPlayer.
  ///
  /// In en, this message translates to:
  /// **'Pass to Player {player}'**
  String passToPlayer(int player);

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @noGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'No games played'**
  String get noGamesPlayed;

  /// No description provided for @variantPortes.
  ///
  /// In en, this message translates to:
  /// **'Portes'**
  String get variantPortes;

  /// No description provided for @variantPortesSub.
  ///
  /// In en, this message translates to:
  /// **'Standard backgammon'**
  String get variantPortesSub;

  /// No description provided for @variantPlakoto.
  ///
  /// In en, this message translates to:
  /// **'Plakoto'**
  String get variantPlakoto;

  /// No description provided for @variantPlakotoSub.
  ///
  /// In en, this message translates to:
  /// **'Pinning variant — trap your opponent'**
  String get variantPlakotoSub;

  /// No description provided for @variantFevga.
  ///
  /// In en, this message translates to:
  /// **'Fevga'**
  String get variantFevga;

  /// No description provided for @variantFevgaSub.
  ///
  /// In en, this message translates to:
  /// **'Running variant — no hitting'**
  String get variantFevgaSub;

  /// No description provided for @onlineLobby.
  ///
  /// In en, this message translates to:
  /// **'Play Online'**
  String get onlineLobby;

  /// No description provided for @quickMatch.
  ///
  /// In en, this message translates to:
  /// **'Quick Match'**
  String get quickMatch;

  /// No description provided for @quickMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Find an opponent near your rating'**
  String get quickMatchSub;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// No description provided for @createRoomSub.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend with a code or QR'**
  String get createRoomSub;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// No description provided for @joinRoomSub.
  ///
  /// In en, this message translates to:
  /// **'Enter a room code or scan QR'**
  String get joinRoomSub;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get roomCode;

  /// No description provided for @waitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent...'**
  String get waitingForOpponent;

  /// No description provided for @searchingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Searching for opponent...'**
  String get searchingForOpponent;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @playAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Play as Guest'**
  String get playAsGuest;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @resign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// No description provided for @resignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resign?'**
  String get resignConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @backToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to Lobby'**
  String get backToLobby;

  /// No description provided for @ratingChange.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingChange;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get vs;

  /// No description provided for @tutorialLessonCube.
  ///
  /// In en, this message translates to:
  /// **'The Doubling Cube'**
  String get tutorialLessonCube;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked'**
  String get achievementUnlocked;

  /// No description provided for @doubleOffer.
  ///
  /// In en, this message translates to:
  /// **'Double!'**
  String get doubleOffer;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @greekLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'How Greek Should I Be?'**
  String get greekLevelTitle;

  /// No description provided for @greekLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We can adjust the amount of Greek I use depending on your comfort level.'**
  String get greekLevelSubtitle;

  /// No description provided for @greekLevelEnglishOnly.
  ///
  /// In en, this message translates to:
  /// **'English Only'**
  String get greekLevelEnglishOnly;

  /// No description provided for @greekLevelCantRead.
  ///
  /// In en, this message translates to:
  /// **'Can\'t read Greek'**
  String get greekLevelCantRead;

  /// No description provided for @greekLevelFluent.
  ///
  /// In en, this message translates to:
  /// **'Fluent'**
  String get greekLevelFluent;

  /// No description provided for @greekLevelCanRead.
  ///
  /// In en, this message translates to:
  /// **'Can read and write'**
  String get greekLevelCanRead;

  /// No description provided for @greekLevelExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get greekLevelExample;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
