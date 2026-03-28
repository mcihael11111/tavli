import '../../core/constants/tradition.dart';
import 'settings_service.dart';

/// Centralized bilingual copy service.
///
/// Returns the right string for the user's [Tradition] and [languageLevel].
/// The language level slider (0.0 = English, 1.0 = Fluent) maps to 5 tiers:
///
///  Level 1 (0.0–0.15): English only
///  Level 2 (0.15–0.35): Light native (game terms, greetings)
///  Level 3 (0.35–0.65): Mixed — native headings, English body
///  Level 4 (0.65–0.85): Mostly native
///  Level 5 (0.85–1.0): Fluent
///
/// Each string belongs to a category (A–D) that determines the threshold
/// at which it switches from English to native.
class TavliCopy {
  TavliCopy._();

  static Tradition get _tradition => SettingsService.instance.tradition;
  static double get _level => SettingsService.instance.languageLevel;

  /// Category A: native at level >= 0.15 (game terms, cultural words).
  static String _a(Map<Tradition, String> native, String english) =>
      _level >= 0.15 ? (native[_tradition] ?? english) : english;

  /// Category B: native at level >= 0.35 (headings, navigation).
  static String _b(Map<Tradition, String> native, String english) =>
      _level >= 0.35 ? (native[_tradition] ?? english) : english;

  /// Category C: native at level >= 0.65 (action labels, body text).
  static String _c(Map<Tradition, String> native, String english) =>
      _level >= 0.65 ? (native[_tradition] ?? english) : english;

  /// Category D: native at level >= 0.85 (full immersion).
  static String _d(Map<Tradition, String> native, String english) =>
      _level >= 0.85 ? (native[_tradition] ?? english) : english;

  // ─── Screen Titles (Category B) ──────────────────────────

  static String get settings => _b(const {
        Tradition.tavli: 'Ρυθμίσεις',
        Tradition.tavla: 'Ayarlar',
        Tradition.nardy: 'Настройки',
        Tradition.sheshBesh: 'הגדרות',
      }, 'Settings');

  static String get profile => _b(const {
        Tradition.tavli: 'Προφίλ',
        Tradition.tavla: 'Profil',
        Tradition.nardy: 'Профиль',
        Tradition.sheshBesh: 'פרופיל',
      }, 'Profile');

  static String get myCollection => _b(const {
        Tradition.tavli: 'Η Συλλογή Μου',
        Tradition.tavla: 'Koleksiyonum',
        Tradition.nardy: 'Моя коллекция',
        Tradition.sheshBesh: 'האוסף שלי',
      }, 'My Collection');

  static String get shop => _b(const {
        Tradition.tavli: 'Κατάστημα',
        Tradition.tavla: 'Mağaza',
        Tradition.nardy: 'Магазин',
        Tradition.sheshBesh: 'חנות',
      }, 'Shop');

  static String get matchHistory => _b(const {
        Tradition.tavli: 'Ιστορικό Αγώνων',
        Tradition.tavla: 'Maç Geçmişi',
        Tradition.nardy: 'История матчей',
        Tradition.sheshBesh: 'היסטוריית משחקים',
      }, 'Match History');

  static String get achievements => _b(const {
        Tradition.tavli: 'Επιτεύγματα',
        Tradition.tavla: 'Başarılar',
        Tradition.nardy: 'Достижения',
        Tradition.sheshBesh: 'הישגים',
      }, 'Achievements');

  static String get chooseDifficulty => _b(const {
        Tradition.tavli: 'Επίλεξε Δυσκολία',
        Tradition.tavla: 'Zorluk Seç',
        Tradition.nardy: 'Выберите сложность',
        Tradition.sheshBesh: 'בחר רמת קושי',
      }, 'Choose Difficulty');

  static String get weeklyChallenges => _b(const {
        Tradition.tavli: 'Εβδομαδιαίες Προκλήσεις',
        Tradition.tavla: 'Haftalık Görevler',
        Tradition.nardy: 'Еженедельные задания',
        Tradition.sheshBesh: 'אתגרים שבועיים',
      }, 'Weekly Challenges');

  // ─── Home Screen Cards (Category B titles, C subtitles) ──

  static String get playVsBot => _b(const {
        Tradition.tavli: 'Παίξε με Bot',
        Tradition.tavla: "Bot'a Karşı Oyna",
        Tradition.nardy: 'Играть с ботом',
        Tradition.sheshBesh: 'שחק נגד בוט',
      }, 'Play vs Bot');

  static String get playVsBotSub => _c(const {
        Tradition.tavli: 'Πρόκληση εναντίον AI',
        Tradition.tavla: 'Yapay zekaya meydan oku',
        Tradition.nardy: 'Бросьте вызов ИИ',
        Tradition.sheshBesh: 'אתגר את הבינה המלאכותית',
      }, 'Challenge the AI opponent');

  static String get playOnline => _b(const {
        Tradition.tavli: 'Παίξε Online',
        Tradition.tavla: 'Online Oyna',
        Tradition.nardy: 'Играть онлайн',
        Tradition.sheshBesh: 'שחק אונליין',
      }, 'Play Online');

  static String get playOnlineSub => _c(const {
        Tradition.tavli: 'Γρήγορο παιχνίδι ή πρόσκληση',
        Tradition.tavla: 'Hızlı maç veya arkadaş davet et',
        Tradition.nardy: 'Быстрый матч или пригласить друга',
        Tradition.sheshBesh: 'משחק מהיר או הזמן חבר',
      }, 'Quick match or invite a friend');

  static String get passAndPlay => _b(const {
        Tradition.tavli: 'Πάσα & Παίξε',
        Tradition.tavla: 'Pas Ver & Oyna',
        Tradition.nardy: 'По очереди',
        Tradition.sheshBesh: 'העבר ושחק',
      }, 'Pass & Play');

  static String get passAndPlaySub => _c(const {
        Tradition.tavli: 'Δύο παίκτες, μία συσκευή',
        Tradition.tavla: 'İki oyuncu, bir cihaz',
        Tradition.nardy: 'Два игрока, одно устройство',
        Tradition.sheshBesh: 'שני שחקנים, מכשיר אחד',
      }, 'Two players, one device');

  static String get learnToPlay => _b(const {
        Tradition.tavli: 'Μάθε να Παίζεις',
        Tradition.tavla: 'Oynamayı Öğren',
        Tradition.nardy: 'Учитесь играть',
        Tradition.sheshBesh: 'למד לשחק',
      }, 'Learn to Play');

  static String get learnToPlaySub => _d(const {
        Tradition.tavli: 'Διαδραστικό μάθημα',
        Tradition.tavla: 'Etkileşimli eğitim',
        Tradition.nardy: 'Интерактивное обучение',
        Tradition.sheshBesh: 'הדרכה אינטראקטיבית',
      }, 'Interactive tutorial');

  static String get shopSub => _c(const {
        Tradition.tavli: 'Ταμπλιά, πούλια και ζάρια',
        Tradition.tavla: 'Tahtalar, pullar ve zarlar',
        Tradition.nardy: 'Доски, шашки и кости',
        Tradition.sheshBesh: 'לוחות, כלים וקוביות',
      }, 'Boards, checkers, and dice sets');

  static String get challengesSub => _c(const {
        Tradition.tavli: 'Ολοκλήρωσε αποστολές, κέρδισε κέρματα',
        Tradition.tavla: 'Görevleri tamamla, ödül kazan',
        Tradition.nardy: 'Выполняйте задания, получайте монеты',
        Tradition.sheshBesh: 'השלם משימות, הרוויח מטבעות',
      }, 'Complete tasks and earn rewards');

  static String get replay => _b(const {
        Tradition.tavli: 'Επανάληψη',
        Tradition.tavla: 'Tekrar İzle',
        Tradition.nardy: 'Повтор',
        Tradition.sheshBesh: 'הקרנה חוזרת',
      }, 'Replay');

  static String get replaySub => _c(const {
        Tradition.tavli: 'Δες τα προηγούμενα παιχνίδια σου',
        Tradition.tavla: 'Önceki oyunlarını izle',
        Tradition.nardy: 'Просмотрите прошлые игры',
        Tradition.sheshBesh: 'צפה במשחקים קודמים',
      }, 'Watch your previous games');

  // ─── Game Screen (Category C) ────────────────────────────

  static String get roll => _c(const {
        Tradition.tavli: 'ΖΑΡΙΑ',
        Tradition.tavla: 'ZAR AT',
        Tradition.nardy: 'КОСТИ',
        Tradition.sheshBesh: 'הטל',
      }, 'ROLL');

  static String get complete => _c(const {
        Tradition.tavli: 'ΟΛΟΚΛΗΡΩΣΗ',
        Tradition.tavla: 'TAMAMLA',
        Tradition.nardy: 'ГОТОВО',
        Tradition.sheshBesh: 'סיים',
      }, 'COMPLETE');

  static String get pause => _c(const {
        Tradition.tavli: 'ΠΑΥΣΗ',
        Tradition.tavla: 'DURAKLAT',
        Tradition.nardy: 'ПАУЗА',
        Tradition.sheshBesh: 'השהיה',
      }, 'PAUSE');

  static String get resume => _c(const {
        Tradition.tavli: 'Συνέχεια',
        Tradition.tavla: 'Devam Et',
        Tradition.nardy: 'Продолжить',
        Tradition.sheshBesh: 'המשך',
      }, 'Resume');

  static String get resign => _c(const {
        Tradition.tavli: 'Παραίτηση',
        Tradition.tavla: 'Pes Et',
        Tradition.nardy: 'Сдаться',
        Tradition.sheshBesh: 'כניעה',
      }, 'Resign');

  static String get newGame => _c(const {
        Tradition.tavli: 'Νέο Παιχνίδι',
        Tradition.tavla: 'Yeni Oyun',
        Tradition.nardy: 'Новая игра',
        Tradition.sheshBesh: 'משחק חדש',
      }, 'New Game');

  static String get exitToHome => _c(const {
        Tradition.tavli: 'Αρχική',
        Tradition.tavla: 'Ana Sayfa',
        Tradition.nardy: 'Главная',
        Tradition.sheshBesh: 'דף הבית',
      }, 'Exit to Home');

  static String get botThinking => _c(const {
        Tradition.tavli: 'Σκέφτεται...',
        Tradition.tavla: 'Düşünüyor...',
        Tradition.nardy: 'Думает...',
        Tradition.sheshBesh: '...חושב',
      }, 'Bot thinking');

  static String get accept => _c(const {
        Tradition.tavli: 'Δέχομαι',
        Tradition.tavla: 'Kabul Et',
        Tradition.nardy: 'Принять',
        Tradition.sheshBesh: 'קבל',
      }, 'Accept');

  static String get decline => _c(const {
        Tradition.tavli: 'Αρνούμαι',
        Tradition.tavla: 'Reddet',
        Tradition.nardy: 'Отклонить',
        Tradition.sheshBesh: 'דחה',
      }, 'Decline');

  static String get double_ => _c(const {
        Tradition.tavli: 'Διπλασιασμός',
        Tradition.tavla: 'İkiye Katla',
        Tradition.nardy: 'Удвоить',
        Tradition.sheshBesh: 'הכפל',
      }, 'Double');

  // ─── Victory Screen (Category A for victory/defeat) ──────

  static String get victory => _a(const {
        Tradition.tavli: 'Νίκη!',
        Tradition.tavla: 'Zafer!',
        Tradition.nardy: 'Победа!',
        Tradition.sheshBesh: '!ניצחון',
      }, 'Victory!');

  static String get defeat => _a(const {
        Tradition.tavli: 'Ήττα',
        Tradition.tavla: 'Yenilgi',
        Tradition.nardy: 'Поражение',
        Tradition.sheshBesh: 'הפסד',
      }, 'Defeat');

  static String get victoryBanner => _a(const {
        Tradition.tavli: 'ΝΙΚΗ!',
        Tradition.tavla: 'ZAFER!',
        Tradition.nardy: 'ПОБЕДА!',
        Tradition.sheshBesh: '!ניצחון',
      }, 'VICTORY!');

  static String get defeatBanner => _a(const {
        Tradition.tavli: 'ΗΤΤΑ',
        Tradition.tavla: 'YENİLGİ',
        Tradition.nardy: 'ПОРАЖЕНИЕ',
        Tradition.sheshBesh: 'הפסד',
      }, 'DEFEAT');

  static String get playAgain => _c(const {
        Tradition.tavli: 'ΠΑΙΞΕ ΞΑΝΑ',
        Tradition.tavla: 'TEKRAR OYNA',
        Tradition.nardy: 'ИГРАТЬ СНОВА',
        Tradition.sheshBesh: 'שחק שוב',
      }, 'PLAY AGAIN');

  static String get home => _c(const {
        Tradition.tavli: 'Αρχική',
        Tradition.tavla: 'Ana Sayfa',
        Tradition.nardy: 'Главная',
        Tradition.sheshBesh: 'בית',
      }, 'Home');

  static String get difficulty => _c(const {
        Tradition.tavli: 'Δυσκολία',
        Tradition.tavla: 'Zorluk',
        Tradition.nardy: 'Сложность',
        Tradition.sheshBesh: 'רמת קושי',
      }, 'Difficulty');

  // ─── Score Labels (Category C) ───────────────────────────

  static String get result => _c(const {
        Tradition.tavli: 'Αποτέλεσμα',
        Tradition.tavla: 'Sonuç',
        Tradition.nardy: 'Результат',
        Tradition.sheshBesh: 'תוצאה',
      }, 'Result');

  static String get multiplier => _c(const {
        Tradition.tavli: 'Πολλαπλασιαστής',
        Tradition.tavla: 'Çarpan',
        Tradition.nardy: 'Множитель',
        Tradition.sheshBesh: 'מכפיל',
      }, 'Multiplier');

  static String get totalPoints => _c(const {
        Tradition.tavli: 'Συνολικοί Πόντοι',
        Tradition.tavla: 'Toplam Puan',
        Tradition.nardy: 'Итого очков',
        Tradition.sheshBesh: 'סה"כ נקודות',
      }, 'Total Points');

  static String get coinsEarned => _c(const {
        Tradition.tavli: 'Κέρματα',
        Tradition.tavla: 'Kazanılan Jeton',
        Tradition.nardy: 'Монеты',
        Tradition.sheshBesh: 'מטבעות',
      }, 'Coins Earned');

  // ─── Opening Roll Overlay ────────────────────────────────

  static String get rollForFirstMove => _c(const {
        Tradition.tavli: 'Ρίξε για Πρώτη Κίνηση',
        Tradition.tavla: 'İlk Hamle İçin Zar At',
        Tradition.nardy: 'Бросок за первый ход',
        Tradition.sheshBesh: 'הטל לתנועה ראשונה',
      }, 'Roll for First Move');

  static String get rollForFirstMoveSub => _d(const {
        Tradition.tavli: 'Και οι δύο ρίχνουν ένα ζάρι.\nΟ μεγαλύτερος αριθμός ξεκινά.',
        Tradition.tavla: 'İki oyuncu birer zar atar.\nYüksek sayı başlar.',
        Tradition.nardy: 'Оба бросают по кубику.\nБольшее число начинает.',
        Tradition.sheshBesh: 'שני השחקנים מטילים קובייה.\nהמספר הגבוה מתחיל.',
      }, 'Both players roll one die.\nHigher number goes first.');

  static String get rollButton => _c(const {
        Tradition.tavli: 'Ρίξε!',
        Tradition.tavla: 'At!',
        Tradition.nardy: 'Бросай!',
        Tradition.sheshBesh: '!הטל',
      }, 'Roll!');

  // ─── Profile Screen ──────────────────────────────────────

  static String get player => _c(const {
        Tradition.tavli: 'Παίκτης',
        Tradition.tavla: 'Oyuncu',
        Tradition.nardy: 'Игрок',
        Tradition.sheshBesh: 'שחקן',
      }, 'Player');

  static String get statistics => _c(const {
        Tradition.tavli: 'Στατιστικά',
        Tradition.tavla: 'İstatistikler',
        Tradition.nardy: 'Статистика',
        Tradition.sheshBesh: 'סטטיסטיקות',
      }, 'Statistics');

  // ─── Double Offer ────────────────────────────────────────

  static String offersDouble(String name) => _c({
        Tradition.tavli: 'Ο $name προσφέρει διπλασιασμό!',
        Tradition.tavla: '$name ikiye katlamayı teklif ediyor!',
        Tradition.nardy: '$name предлагает удвоение!',
        Tradition.sheshBesh: '!$name מציע הכפלה',
      }, '$name offers a double!');

  // ─── Back to Lobby (Online) ──────────────────────────────

  static String get backToLobby => _c(const {
        Tradition.tavli: 'ΠΙΣΩ ΣΤΟ ΛΟΜΠΙ',
        Tradition.tavla: 'LOBİYE DÖN',
        Tradition.nardy: 'НАЗАД В ЛОББИ',
        Tradition.sheshBesh: 'חזרה ללובי',
      }, 'BACK TO LOBBY');
}
