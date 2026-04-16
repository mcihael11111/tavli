import '../../core/constants/tradition.dart';
import 'settings_service.dart';

/// Centralized bilingual copy service.
///
/// Returns the right string for the user's [Tradition] and [languageLevel].
/// The language level (0.0 = English, 0.5 = Mixed, 1.0 = Fluent) maps to 3 tiers:
///
///  English (0.0): Everything in English
///  Mixed   (0.5): Native headings + game terms, English body text
///  Fluent  (1.0): Everything in native language
///
/// Categories A–D define thresholds:
///   A >= 0.15: game terms, cultural words
///   B >= 0.35: headings, navigation
///   C >= 0.65: action labels, body text
///   D >= 0.85: full immersion (tutorial explanations)
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
        Tradition.tawla: 'إعدادات',
      }, 'Settings');

  static String get profile => _b(const {
        Tradition.tavli: 'Προφίλ',
        Tradition.tavla: 'Profil',
        Tradition.nardy: 'Профиль',
        Tradition.sheshBesh: 'פרופיל',
        Tradition.tawla: 'ملف شخصي',
      }, 'Profile');

  static String get myCollection => _b(const {
        Tradition.tavli: 'Η Συλλογή Μου',
        Tradition.tavla: 'Koleksiyonum',
        Tradition.nardy: 'Моя коллекция',
        Tradition.sheshBesh: 'האוסף שלי',
        Tradition.tawla: 'مجموعتي',
      }, 'My Collection');

  static String get shop => _b(const {
        Tradition.tavli: 'Κατάστημα',
        Tradition.tavla: 'Mağaza',
        Tradition.nardy: 'Магазин',
        Tradition.sheshBesh: 'חנות',
        Tradition.tawla: 'متجر',
      }, 'Shop');

  static String get matchHistory => _b(const {
        Tradition.tavli: 'Ιστορικό Αγώνων',
        Tradition.tavla: 'Maç Geçmişi',
        Tradition.nardy: 'История матчей',
        Tradition.sheshBesh: 'היסטוריית משחקים',
        Tradition.tawla: 'سجل المباريات',
      }, 'Match History');

  static String get achievements => _b(const {
        Tradition.tavli: 'Επιτεύγματα',
        Tradition.tavla: 'Başarılar',
        Tradition.nardy: 'Достижения',
        Tradition.sheshBesh: 'הישגים',
        Tradition.tawla: 'إنجازات',
      }, 'Achievements');

  static String get chooseDifficulty => _b(const {
        Tradition.tavli: 'Επίλεξε Δυσκολία',
        Tradition.tavla: 'Zorluk Seç',
        Tradition.nardy: 'Выберите сложность',
        Tradition.sheshBesh: 'בחר רמת קושי',
        Tradition.tawla: 'اختر الصعوبة',
      }, 'Choose Difficulty');

  static String get weeklyChallenges => _b(const {
        Tradition.tavli: 'Εβδομαδιαίες Προκλήσεις',
        Tradition.tavla: 'Haftalık Görevler',
        Tradition.nardy: 'Еженедельные задания',
        Tradition.sheshBesh: 'אתגרים שבועיים',
        Tradition.tawla: 'تحديات أسبوعية',
      }, 'Weekly Challenges');

  // ─── Home Screen Sections (Category B) ───────────────────

  static String get chooseYourGame => _b(const {
        Tradition.tavli: 'Διάλεξε Παιχνίδι',
        Tradition.tavla: 'Oyununu Seç',
        Tradition.nardy: 'Выберите игру',
        Tradition.sheshBesh: 'בחר משחק',
        Tradition.tawla: 'اختر لعبتك',
      }, 'Choose Your Game');

  static String get exploreOtherTraditions => _b(const {
        Tradition.tavli: 'Εξερεύνησε Άλλες Παραδόσεις',
        Tradition.tavla: 'Diğer Gelenekleri Keşfet',
        Tradition.nardy: 'Другие традиции',
        Tradition.sheshBesh: 'גלה מסורות אחרות',
        Tradition.tawla: 'اكتشف تقاليد أخرى',
      }, 'Explore Other Traditions');

  static String get exploreOtherTraditionsSub => _c(const {
        Tradition.tavli: 'Το τάβλι παίζεται διαφορετικά σε όλο τον κόσμο. Δοκίμασε κάτι νέο!',
        Tradition.tavla: 'Tavla dünyada farklı oynanır. Yeni bir stil dene!',
        Tradition.nardy: 'В мире играют по-разному. Попробуйте новый стиль!',
        Tradition.sheshBesh: 'שש-בש משוחק אחרת ברחבי העולם. נסה סגנון חדש!',
        Tradition.tawla: 'الطاولة تُلعب بشكل مختلف حول العالم. جرّب أسلوبًا جديدًا!',
      }, 'Backgammon is played differently around the world. Try another style!');

  static String get spectate => _b(const {
        Tradition.tavli: 'Παρακολούθηση',
        Tradition.tavla: 'İzle',
        Tradition.nardy: 'Наблюдать',
        Tradition.sheshBesh: 'צפייה',
        Tradition.tawla: 'مشاهدة',
      }, 'Spectate');

  // ─── Mechanic Labels (Category B) ───────────────────────

  static String get mechanicHitAndRun => _b(const {
        Tradition.tavli: 'Χτύπα & τρέχα',
        Tradition.tavla: 'Vur ve kaç',
        Tradition.nardy: 'Бей и беги',
        Tradition.sheshBesh: 'הכה וברח',
        Tradition.tawla: 'اضرب واهرب',
      }, 'Hit & run');

  static String get mechanicTrapAndPin => _b(const {
        Tradition.tavli: 'Παγίδευσε & κλείδωσε',
        Tradition.tavla: 'Yakala ve kilitle',
        Tradition.nardy: 'Лови и блокируй',
        Tradition.sheshBesh: 'לכוד ונעל',
        Tradition.tawla: 'اصطد وثبّت',
      }, 'Trap & pin');

  static String get mechanicRaceAndBlock => _b(const {
        Tradition.tavli: 'Τρέξε & μπλόκαρε',
        Tradition.tavla: 'Yarış ve engelle',
        Tradition.nardy: 'Беги и блокируй',
        Tradition.sheshBesh: 'רוץ וחסום',
        Tradition.tawla: 'سابق وامنع',
      }, 'Race & block');

  // ─── Home Screen Cards (Category B titles, C subtitles) ──

  static String get playVsBot => _b(const {
        Tradition.tavli: 'Παίξε με Bot',
        Tradition.tavla: "Bot'a Karşı Oyna",
        Tradition.nardy: 'Играть с ботом',
        Tradition.sheshBesh: 'שחק נגד בוט',
        Tradition.tawla: 'العب ضد البوت',
      }, 'Play vs Bot');

  static String get playVsBotSub => _c(const {
        Tradition.tavli: 'Πρόκληση εναντίον AI',
        Tradition.tavla: 'Yapay zekaya meydan oku',
        Tradition.nardy: 'Бросьте вызов ИИ',
        Tradition.sheshBesh: 'אתגר את הבינה המלאכותית',
        Tradition.tawla: 'تحدّى الذكاء الاصطناعي',
      }, 'Challenge the AI opponent');

  static String get playOnline => _b(const {
        Tradition.tavli: 'Παίξε Online',
        Tradition.tavla: 'Online Oyna',
        Tradition.nardy: 'Играть онлайн',
        Tradition.sheshBesh: 'שחק אונליין',
        Tradition.tawla: 'العب أونلاين',
      }, 'Play Online');

  static String get playOnlineSub => _c(const {
        Tradition.tavli: 'Γρήγορο παιχνίδι ή πρόσκληση',
        Tradition.tavla: 'Hızlı maç veya arkadaş davet et',
        Tradition.nardy: 'Быстрый матч или пригласить друга',
        Tradition.sheshBesh: 'משחק מהיר או הזמן חבר',
        Tradition.tawla: 'مباراة سريعة أو ادعُ صديق',
      }, 'Quick match or invite a friend');

  static String get passAndPlay => _b(const {
        Tradition.tavli: 'Πάσα & Παίξε',
        Tradition.tavla: 'Pas Ver & Oyna',
        Tradition.nardy: 'По очереди',
        Tradition.sheshBesh: 'העבר ושחק',
        Tradition.tawla: 'مرّر والعب',
      }, 'Pass & Play');

  static String get passAndPlaySub => _c(const {
        Tradition.tavli: 'Δύο παίκτες, μία συσκευή',
        Tradition.tavla: 'İki oyuncu, bir cihaz',
        Tradition.nardy: 'Два игрока, одно устройство',
        Tradition.sheshBesh: 'שני שחקנים, מכשיר אחד',
        Tradition.tawla: 'لاعبان، جهاز واحد',
      }, 'Two players, one device');

  static String get learnToPlay => _b(const {
        Tradition.tavli: 'Μάθε να Παίζεις',
        Tradition.tavla: 'Oynamayı Öğren',
        Tradition.nardy: 'Учитесь играть',
        Tradition.sheshBesh: 'למד לשחק',
        Tradition.tawla: 'تعلّم اللعب',
      }, 'Learn to Play');

  static String get learnToPlaySub => _d(const {
        Tradition.tavli: 'Διαδραστικό μάθημα',
        Tradition.tavla: 'Etkileşimli eğitim',
        Tradition.nardy: 'Интерактивное обучение',
        Tradition.sheshBesh: 'הדרכה אינטראקטיבית',
        Tradition.tawla: 'درس تفاعلي',
      }, 'Interactive tutorial');

  static String get shopSub => _c(const {
        Tradition.tavli: 'Ταμπλιά, πούλια και ζάρια',
        Tradition.tavla: 'Tahtalar, pullar ve zarlar',
        Tradition.nardy: 'Доски, шашки и кости',
        Tradition.sheshBesh: 'לוחות, כלים וקוביות',
        Tradition.tawla: 'طاولات وأحجار ونرد',
      }, 'Boards, checkers, and dice sets');

  static String get challengesSub => _c(const {
        Tradition.tavli: 'Ολοκλήρωσε αποστολές, κέρδισε κέρματα',
        Tradition.tavla: 'Görevleri tamamla, ödül kazan',
        Tradition.nardy: 'Выполняйте задания, получайте монеты',
        Tradition.sheshBesh: 'השלם משימות, הרוויח מטבעות',
        Tradition.tawla: 'أكمل المهام واكسب مكافآت',
      }, 'Complete tasks and earn rewards');

  static String get replay => _b(const {
        Tradition.tavli: 'Επανάληψη',
        Tradition.tavla: 'Tekrar İzle',
        Tradition.nardy: 'Повтор',
        Tradition.sheshBesh: 'הקרנה חוזרת',
        Tradition.tawla: 'إعادة',
      }, 'Replay');

  static String get replaySub => _c(const {
        Tradition.tavli: 'Δες τα προηγούμενα παιχνίδια σου',
        Tradition.tavla: 'Önceki oyunlarını izle',
        Tradition.nardy: 'Просмотрите прошлые игры',
        Tradition.sheshBesh: 'צפה במשחקים קודמים',
        Tradition.tawla: 'شاهد مبارياتك السابقة',
      }, 'Watch your previous games');

  // ─── Game Screen (Category C) ────────────────────────────

  static String get roll => _c(const {
        Tradition.tavli: 'ΖΑΡΙΑ',
        Tradition.tavla: 'ZAR AT',
        Tradition.nardy: 'КОСТИ',
        Tradition.sheshBesh: 'הטל',
        Tradition.tawla: 'ارمِ',
      }, 'ROLL');

  static String get complete => _c(const {
        Tradition.tavli: 'ΟΛΟΚΛΗΡΩΣΗ',
        Tradition.tavla: 'TAMAMLA',
        Tradition.nardy: 'ГОТОВО',
        Tradition.sheshBesh: 'סיים',
        Tradition.tawla: 'تم',
      }, 'COMPLETE');

  /// SnackBar shown when the player rolls but has no legal moves.
  static String get noLegalMovesSkipped => _c(const {
        Tradition.tavli: 'Καμία κίνηση — παραλείπεται',
        Tradition.tavla: 'Hamle yok — geçiliyor',
        Tradition.nardy: 'Нет ходов — пропуск',
        Tradition.sheshBesh: 'אין מהלכים — מדלגים',
        Tradition.tawla: 'لا حركات — تخطي',
      }, 'No legal moves — turn skipped');

  /// SnackBar shown when the opponent has no legal moves.
  /// `name` is the personality's display name (e.g. "Mikhail", "Yusuf").
  static String opponentNoMovesSkipped(String name) => _c({
        Tradition.tavli: '$name: καμία κίνηση — παραλείπεται',
        Tradition.tavla: '$name hamle yok — geçiliyor',
        Tradition.nardy: '$name: нет ходов — пропуск',
        Tradition.sheshBesh: 'ל$name אין מהלכים — מדלגים',
        Tradition.tawla: '$name بلا حركات — تخطي',
      }, '$name has no moves — turn skipped');

  /// Teaching-mode SnackBar: player made an excellent/best move.
  static String get teachingGoodMove => _c(const {
        Tradition.tavli: 'Εξαιρετική κίνηση!',
        Tradition.tavla: 'Harika hamle!',
        Tradition.nardy: 'Отличный ход!',
        Tradition.sheshBesh: 'מהלך מצוין!',
        Tradition.tawla: 'حركة رائعة!',
      }, 'Great move!');

  /// Teaching-mode SnackBar: player made a weak move, minor loss.
  static String get teachingBadMove => _c(const {
        Tradition.tavli: 'Υπήρχε καλύτερη κίνηση.',
        Tradition.tavla: 'Daha iyi bir hamle vardı.',
        Tradition.nardy: 'Был ход получше.',
        Tradition.sheshBesh: 'היה מהלך טוב יותר.',
        Tradition.tawla: 'كانت هناك حركة أفضل.',
      }, 'There was a better move.');

  /// Teaching-mode SnackBar: player made a serious mistake.
  static String get teachingMistake => _c(const {
        Tradition.tavli: 'Αυτή η κίνηση ήταν λάθος — δοκίμασε διαφορετικά.',
        Tradition.tavla: 'Bu hamle hataydı — farklı dene.',
        Tradition.nardy: 'Этот ход — ошибка. Попробуй иначе.',
        Tradition.sheshBesh: 'המהלך הזה היה טעות — נסה אחרת.',
        Tradition.tawla: 'كانت هذه الحركة خطأ — جرب بطريقة أخرى.',
      }, 'That move was a mistake — try differently.');

  static String get pause => _c(const {
        Tradition.tavli: 'ΠΑΥΣΗ',
        Tradition.tavla: 'DURAKLAT',
        Tradition.nardy: 'ПАУЗА',
        Tradition.sheshBesh: 'השהיה',
        Tradition.tawla: 'إيقاف',
      }, 'PAUSE');

  static String get resume => _c(const {
        Tradition.tavli: 'Συνέχεια',
        Tradition.tavla: 'Devam Et',
        Tradition.nardy: 'Продолжить',
        Tradition.sheshBesh: 'המשך',
        Tradition.tawla: 'استمر',
      }, 'Resume');

  static String get resign => _c(const {
        Tradition.tavli: 'Παραίτηση',
        Tradition.tavla: 'Pes Et',
        Tradition.nardy: 'Сдаться',
        Tradition.sheshBesh: 'כניעה',
        Tradition.tawla: 'استسلام',
      }, 'Resign');

  static String get newGame => _c(const {
        Tradition.tavli: 'Νέο Παιχνίδι',
        Tradition.tavla: 'Yeni Oyun',
        Tradition.nardy: 'Новая игра',
        Tradition.sheshBesh: 'משחק חדש',
        Tradition.tawla: 'لعبة جديدة',
      }, 'New Game');

  static String get exitToHome => _c(const {
        Tradition.tavli: 'Αρχική',
        Tradition.tavla: 'Ana Sayfa',
        Tradition.nardy: 'Главная',
        Tradition.sheshBesh: 'דף הבית',
        Tradition.tawla: 'الرئيسية',
      }, 'Exit to Home');

  static String get botThinking => _c(const {
        Tradition.tavli: 'Σκέφτεται...',
        Tradition.tavla: 'Düşünüyor...',
        Tradition.nardy: 'Думает...',
        Tradition.sheshBesh: '...חושב',
        Tradition.tawla: '...يفكر',
      }, 'Bot thinking');

  static String get accept => _c(const {
        Tradition.tavli: 'Δέχομαι',
        Tradition.tavla: 'Kabul Et',
        Tradition.nardy: 'Принять',
        Tradition.sheshBesh: 'קבל',
        Tradition.tawla: 'قبول',
      }, 'Accept');

  static String get decline => _c(const {
        Tradition.tavli: 'Αρνούμαι',
        Tradition.tavla: 'Reddet',
        Tradition.nardy: 'Отклонить',
        Tradition.sheshBesh: 'דחה',
        Tradition.tawla: 'رفض',
      }, 'Decline');

  static String get double_ => _c(const {
        Tradition.tavli: 'Διπλασιασμός',
        Tradition.tavla: 'İkiye Katla',
        Tradition.nardy: 'Удвоить',
        Tradition.sheshBesh: 'הכפל',
        Tradition.tawla: 'ضاعف',
      }, 'Double');

  // ─── Victory Screen (Category A for victory/defeat) ──────

  static String get victory => _a(const {
        Tradition.tavli: 'Νίκη!',
        Tradition.tavla: 'Zafer!',
        Tradition.nardy: 'Победа!',
        Tradition.sheshBesh: '!ניצחון',
        Tradition.tawla: '!فوز',
      }, 'Victory!');

  static String get defeat => _a(const {
        Tradition.tavli: 'Ήττα',
        Tradition.tavla: 'Yenilgi',
        Tradition.nardy: 'Поражение',
        Tradition.sheshBesh: 'הפסד',
        Tradition.tawla: 'هزيمة',
      }, 'Defeat');

  static String get victoryBanner => _a(const {
        Tradition.tavli: 'ΝΙΚΗ!',
        Tradition.tavla: 'ZAFER!',
        Tradition.nardy: 'ПОБЕДА!',
        Tradition.sheshBesh: '!ניצחון',
        Tradition.tawla: '!فوز',
      }, 'VICTORY!');

  static String get defeatBanner => _a(const {
        Tradition.tavli: 'ΗΤΤΑ',
        Tradition.tavla: 'YENİLGİ',
        Tradition.nardy: 'ПОРАЖЕНИЕ',
        Tradition.sheshBesh: 'הפסד',
        Tradition.tawla: 'هزيمة',
      }, 'DEFEAT');

  static String get playAgain => _c(const {
        Tradition.tavli: 'ΠΑΙΞΕ ΞΑΝΑ',
        Tradition.tavla: 'TEKRAR OYNA',
        Tradition.nardy: 'ИГРАТЬ СНОВА',
        Tradition.sheshBesh: 'שחק שוב',
        Tradition.tawla: 'العب مجدداً',
      }, 'PLAY AGAIN');

  static String get home => _c(const {
        Tradition.tavli: 'Αρχική',
        Tradition.tavla: 'Ana Sayfa',
        Tradition.nardy: 'Главная',
        Tradition.sheshBesh: 'בית',
        Tradition.tawla: 'الرئيسية',
      }, 'Home');

  static String get difficulty => _c(const {
        Tradition.tavli: 'Δυσκολία',
        Tradition.tavla: 'Zorluk',
        Tradition.nardy: 'Сложность',
        Tradition.sheshBesh: 'רמת קושי',
        Tradition.tawla: 'الصعوبة',
      }, 'Difficulty');

  // ─── Score Labels (Category C) ───────────────────────────

  static String get result => _c(const {
        Tradition.tavli: 'Αποτέλεσμα',
        Tradition.tavla: 'Sonuç',
        Tradition.nardy: 'Результат',
        Tradition.sheshBesh: 'תוצאה',
        Tradition.tawla: 'النتيجة',
      }, 'Result');

  static String get multiplier => _c(const {
        Tradition.tavli: 'Πολλαπλασιαστής',
        Tradition.tavla: 'Çarpan',
        Tradition.nardy: 'Множитель',
        Tradition.sheshBesh: 'מכפיל',
        Tradition.tawla: 'المضاعف',
      }, 'Multiplier');

  static String get totalPoints => _c(const {
        Tradition.tavli: 'Συνολικοί Πόντοι',
        Tradition.tavla: 'Toplam Puan',
        Tradition.nardy: 'Итого очков',
        Tradition.sheshBesh: 'סה"כ נקודות',
        Tradition.tawla: 'مجموع النقاط',
      }, 'Total Points');

  static String get coinsEarned => _c(const {
        Tradition.tavli: 'Κέρματα',
        Tradition.tavla: 'Kazanılan Jeton',
        Tradition.nardy: 'Монеты',
        Tradition.sheshBesh: 'מטבעות',
        Tradition.tawla: 'عملات',
      }, 'Coins Earned');

  // ─── Opening Roll Overlay ────────────────────────────────

  static String get rollForFirstMove => _c(const {
        Tradition.tavli: 'Ρίξε για Πρώτη Κίνηση',
        Tradition.tavla: 'İlk Hamle İçin Zar At',
        Tradition.nardy: 'Бросок за первый ход',
        Tradition.sheshBesh: 'הטל לתנועה ראשונה',
        Tradition.tawla: 'ارمِ للحركة الأولى',
      }, 'Roll for First Move');

  static String get rollForFirstMoveSub => _d(const {
        Tradition.tavli: 'Και οι δύο ρίχνουν ένα ζάρι.\nΟ μεγαλύτερος αριθμός ξεκινά.',
        Tradition.tavla: 'İki oyuncu birer zar atar.\nYüksek sayı başlar.',
        Tradition.nardy: 'Оба бросают по кубику.\nБольшее число начинает.',
        Tradition.sheshBesh: 'שני השחקנים מטילים קובייה.\nהמספר הגבוה מתחיל.',
        Tradition.tawla: 'كل لاعب يرمي نرد.\nالرقم الأعلى يبدأ.',
      }, 'Both players roll one die.\nHigher number goes first.');

  static String get rollButton => _c(const {
        Tradition.tavli: 'Ρίξε!',
        Tradition.tavla: 'At!',
        Tradition.nardy: 'Бросай!',
        Tradition.sheshBesh: '!הטל',
        Tradition.tawla: '!ارمِ',
      }, 'Roll!');

  // ─── Profile Screen ──────────────────────────────────────

  static String get player => _c(const {
        Tradition.tavli: 'Παίκτης',
        Tradition.tavla: 'Oyuncu',
        Tradition.nardy: 'Игрок',
        Tradition.sheshBesh: 'שחקן',
        Tradition.tawla: 'لاعب',
      }, 'Player');

  static String get statistics => _c(const {
        Tradition.tavli: 'Στατιστικά',
        Tradition.tavla: 'İstatistikler',
        Tradition.nardy: 'Статистика',
        Tradition.sheshBesh: 'סטטיסטיקות',
        Tradition.tawla: 'إحصائيات',
      }, 'Statistics');

  // ─── Double Offer ────────────────────────────────────────

  static String offersDouble(String name) => _c({
        Tradition.tavli: 'Ο $name προσφέρει διπλασιασμό!',
        Tradition.tavla: '$name ikiye katlamayı teklif ediyor!',
        Tradition.nardy: '$name предлагает удвоение!',
        Tradition.sheshBesh: '!$name מציע הכפלה',
        Tradition.tawla: '!$name يعرض المضاعفة',
      }, '$name offers a double!');

  // ─── Back to Lobby (Online) ──────────────────────────────

  static String get backToLobby => _c(const {
        Tradition.tavli: 'ΠΙΣΩ ΣΤΟ ΛΟΜΠΙ',
        Tradition.tavla: 'LOBİYE DÖN',
        Tradition.nardy: 'НАЗАД В ЛОББИ',
        Tradition.sheshBesh: 'חזרה ללובי',
        Tradition.tawla: 'العودة للردهة',
      }, 'BACK TO LOBBY');
}
