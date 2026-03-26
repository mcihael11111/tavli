import '../../../core/constants/tradition.dart';

/// Bot personality presets — each defines a unique opponent character.
///
/// Each tradition has ~5 culturally appropriate personalities.
enum BotPersonality {
  // ── Tavli (Greece) ────────────────────────────────────────
  /// Μιχαήλ — The kafeneio owner (original default).
  mikhail,

  /// Θείος Σπύρος — Extreme Greek, crazy uncle.
  spyrosUncle,

  /// Ξάδερφος Νίκος — Young Greek cousin.
  cousinNikos,

  /// Παππούς Γιώργος — Wholesome grandfather.
  pappoosYiorgos,

  /// Θεία Ελένη — Sassy Greek aunt.
  theiaEleni,

  // ── Tavla (Turkey) ────────────────────────────────────────
  /// Mehmet Abi — The kahvehane owner (default).
  mehmetAbi,

  /// Teyze Fatma — The neighborhood matriarch.
  teyzeFatma,

  /// Emre — University student, fast and impulsive.
  emre,

  /// Dede Hasan — Retired teacher, patient, uses proverbs.
  dedeHasan,

  /// Ayşe Abla — The shopkeeper, friendly trash-talker.
  ayseAbla,

  // ── Nardy (Russia / Caucasus) ─────────────────────────────
  /// Armen — The coffeehouse regular (default). Calculative, dry humor.
  armen,

  /// Babushka Vera — Grandmother. Deceptively strong player.
  babushkaVera,

  /// Giorgi — Georgian friend. Boisterous, celebratory.
  giorgi,

  /// Dyadya Sasha — Uncle from Baku. Stories from the old days.
  dyadyaSasha,

  /// Leyla — Young professional. Competitive, modern.
  leyla,

  // ── Shesh Besh (Israel / Arab World) ──────────────────────
  /// Abu Yusuf — The coffeehouse elder (default). Philosophical.
  abuYusuf,

  /// Dod Moshe — Uncle figure. Loud, animated, heart of gold.
  dodMoshe,

  /// Samira — Neighbor. Quick wit, no mercy.
  samira,

  /// Saba Eli — Grandfather. Slow, deliberate, always wins.
  sabaEli,

  /// Hana — Cousin. College-aged, teaches slang.
  hana;

  /// The tradition this personality belongs to.
  Tradition get tradition => switch (this) {
        mikhail || spyrosUncle || cousinNikos || pappoosYiorgos || theiaEleni =>
          Tradition.tavli,
        mehmetAbi || teyzeFatma || emre || dedeHasan || ayseAbla =>
          Tradition.tavla,
        armen || babushkaVera || giorgi || dyadyaSasha || leyla =>
          Tradition.nardy,
        abuYusuf || dodMoshe || samira || sabaEli || hana =>
          Tradition.sheshBesh,
      };

  /// Get all personalities for a given tradition.
  static List<BotPersonality> forTradition(Tradition t) =>
      values.where((p) => p.tradition == t).toList();

  /// The default personality for each tradition.
  static BotPersonality defaultFor(Tradition t) => switch (t) {
        Tradition.tavli => mikhail,
        Tradition.tavla => mehmetAbi,
        Tradition.nardy => armen,
        Tradition.sheshBesh => abuYusuf,
      };

  /// English display name.
  String get displayName => switch (this) {
        mikhail => 'Mikhail',
        spyrosUncle => 'Uncle Spyros',
        cousinNikos => 'Cousin Nikos',
        pappoosYiorgos => 'Grandpa Giorgos',
        theiaEleni => 'Aunt Eleni',
        mehmetAbi => 'Mehmet Abi',
        teyzeFatma => 'Teyze Fatma',
        emre => 'Emre',
        dedeHasan => 'Dede Hasan',
        ayseAbla => 'Ayşe Abla',
        armen => 'Armen',
        babushkaVera => 'Babushka Vera',
        giorgi => 'Giorgi',
        dyadyaSasha => 'Dyadya Sasha',
        leyla => 'Leyla',
        abuYusuf => 'Abu Yusuf',
        dodMoshe => 'Dod Moshe',
        samira => 'Samira',
        sabaEli => 'Saba Eli',
        hana => 'Hana',
      };

  /// Native-script display name.
  String get nativeName => switch (this) {
        mikhail => 'Μιχαήλ',
        spyrosUncle => 'Θείος Σπύρος',
        cousinNikos => 'Ξάδερφος Νίκος',
        pappoosYiorgos => 'Παππούς Γιώργος',
        theiaEleni => 'Θεία Ελένη',
        mehmetAbi => 'Mehmet Abi',
        teyzeFatma => 'Teyze Fatma',
        emre => 'Emre',
        dedeHasan => 'Dede Hasan',
        ayseAbla => 'Ayşe Abla',
        armen => 'Армен',
        babushkaVera => 'Бабушка Вера',
        giorgi => 'გიორგი',
        dyadyaSasha => 'Дядя Саша',
        leyla => 'Лейла',
        abuYusuf => 'أبو يوسف',
        dodMoshe => 'דוד משה',
        samira => 'سميرة',
        sabaEli => 'סבא אלי',
        hana => 'هنا',
      };

  /// Greek display name (kept for backward compatibility).
  String get greekName => nativeName;

  /// Single character for the avatar circle.
  String get avatarInitial => switch (this) {
        mikhail => 'Μ',
        spyrosUncle => 'Σ',
        cousinNikos => 'Ν',
        pappoosYiorgos => 'Γ',
        theiaEleni => 'Ε',
        mehmetAbi => 'M',
        teyzeFatma => 'F',
        emre => 'E',
        dedeHasan => 'H',
        ayseAbla => 'A',
        armen => 'А',
        babushkaVera => 'В',
        giorgi => 'გ',
        dyadyaSasha => 'С',
        leyla => 'Л',
        abuYusuf => 'ي',
        dodMoshe => 'מ',
        samira => 'س',
        sabaEli => 'א',
        hana => 'ه',
      };

  /// Short personality description (English).
  String get subtitle => switch (this) {
        mikhail => 'The kafeneio owner. Warm but competitive.',
        spyrosUncle => 'Over-the-top dramatic. Slams the table.',
        cousinNikos => 'Casual and chill. Loves to tease.',
        pappoosYiorgos => 'Wise and patient. Tells stories.',
        theiaEleni => 'Sassy and proud. Feeds you while playing.',
        mehmetAbi => 'The kahvehane owner. Strategic and warm.',
        teyzeFatma => 'The neighborhood matriarch. Sharp and competitive.',
        emre => 'University student. Fast and impulsive.',
        dedeHasan => 'Retired teacher. Patient, speaks in proverbs.',
        ayseAbla => 'The shopkeeper. Friendly trash-talker.',
        armen => 'Coffeehouse regular. Calculative, dry humor.',
        babushkaVera => 'Grandmother. Deceptively strong player.',
        giorgi => 'Georgian friend. Boisterous and celebratory.',
        dyadyaSasha => 'Uncle from Baku. Stories from the old days.',
        leyla => 'Young professional. Competitive and modern.',
        abuYusuf => 'The coffeehouse elder. Respected, philosophical.',
        dodMoshe => 'Uncle figure. Loud, animated, heart of gold.',
        samira => 'Neighbor. Quick wit, no mercy.',
        sabaEli => 'Grandfather. Slow, deliberate, always wins.',
        hana => 'Cousin. College-aged, teaches you slang.',
      };

  /// Short personality description (native language).
  String get nativeSubtitle => switch (this) {
        mikhail => 'Ο καφετζής. Ζεστός αλλά ανταγωνιστικός.',
        spyrosUncle => 'Δραματικός στο φουλ. Χτυπάει το τραπέζι.',
        cousinNikos => 'Χαλαρός και cool. Σε πειράζει συνέχεια.',
        pappoosYiorgos => 'Σοφός και υπομονετικός. Λέει ιστορίες.',
        theiaEleni => 'Σπαρταριστή και περήφανη. Σε ταΐζει ενώ παίζεις.',
        mehmetAbi => 'Kahvehane sahibi. Stratejik ve sıcak.',
        teyzeFatma => 'Mahalle anası. Keskin ve rekabetçi.',
        emre => 'Üniversiteli. Hızlı ve dürtüsel.',
        dedeHasan => 'Emekli öğretmen. Sabırlı, atasözleriyle konuşur.',
        ayseAbla => 'Bakkalcı. Güler yüzlü laf atıcı.',
        armen => 'Завсегдатай кофейни. Расчётливый, сухой юмор.',
        babushkaVera => 'Бабушка. Обманчиво сильный игрок.',
        giorgi => 'Грузинский друг. Шумный и радостный.',
        dyadyaSasha => 'Дядя из Баку. Рассказывает истории.',
        leyla => 'Молодой профессионал. Конкурентная и современная.',
        abuYusuf => 'شيخ المقهى. محترم وفيلسوف.',
        dodMoshe => 'הדוד. רועש, חי, לב של זהב.',
        samira => 'الجارة. سريعة البديهة، بلا رحمة.',
        sabaEli => 'הסבא. איטי, מחושב, תמיד מנצח.',
        hana => 'بنت العم. جامعية، تعلّمك عامية.',
      };

  /// Backward compat alias.
  String get greekSubtitle => nativeSubtitle;

  /// Welcome greeting shown in onboarding.
  String get onboardingGreeting => switch (this) {
        mikhail => "I'm Mikhail. Welcome to Tavli.",
        spyrosUncle => 'ΩΩΩΠΑ! Uncle Spyros is here! Let\'s PLAY!',
        cousinNikos => 'Γεια ρε! I\'m Nikos. Ready to lose?',
        pappoosYiorgos =>
          'Καλώς ήρθες, παιδί μου. Sit. Let me teach you.',
        theiaEleni =>
          'Ah, finally someone to play with! Sit, I made κουλουράκια.',
        mehmetAbi => "Hoş geldin! I'm Mehmet. Shall we play?",
        teyzeFatma => 'Buyrun, oturun! Fatma Teyze is ready.',
        emre => "Hey! I'm Emre. Quick game?",
        dedeHasan => 'Sabır taşı bile çatlar. Come, learn patience with me.',
        ayseAbla => 'Gel gel! Ayşe Abla never turns down a game.',
        armen => 'Привет. I\'m Armen. Let\'s see what you\'ve got.',
        babushkaVera => 'Садись, внучок. Babushka will teach you.',
        giorgi => 'გამარჯობა! Giorgi is here — let\'s celebrate with a game!',
        dyadyaSasha => 'Ah, finally! Sit, I\'ll tell you a story between moves.',
        leyla => 'Привет! Ready for a real challenge?',
        abuYusuf => 'Ahlan wa sahlan. Come, let us play.',
        dodMoshe => '!שלום! Dod Moshe is ready — yalla',
        samira => 'أهلاً! Think you can beat me? Try.',
        sabaEli => 'Shalom. Sit. Let the dice speak.',
        hana => 'Hey! Hana here. I\'ll go easy on you... maybe.',
      };

  /// Time-of-day greetings.
  String morningGreeting(double languageLevel) => switch (tradition) {
        Tradition.tavli => languageLevel > 0.5
            ? 'Καλημέρα! Ready for coffee and tavli?'
            : 'Good morning! Ready for coffee and tavli?',
        Tradition.tavla => languageLevel > 0.5
            ? 'Günaydın! Bir kahve, bir tavla?'
            : 'Good morning! Coffee and tavla?',
        Tradition.nardy => languageLevel > 0.5
            ? 'Доброе утро! Партию в нарды?'
            : 'Good morning! A round of nardy?',
        Tradition.sheshBesh => languageLevel > 0.5
            ? '!בוקר טוב! שש בש'
            : 'Good morning! Shesh besh?',
      };

  String afternoonGreeting(double languageLevel) => switch (tradition) {
        Tradition.tavli => languageLevel > 0.5
            ? 'Μεσημέρι... perfect time for a game, ρε!'
            : 'Afternoon... perfect time for a game!',
        Tradition.tavla => languageLevel > 0.5
            ? 'Öğleden sonra... tam oyun zamanı!'
            : 'Afternoon... perfect time for a game!',
        Tradition.nardy => languageLevel > 0.5
            ? 'Добрый день! Самое время для партии!'
            : 'Good afternoon! Perfect time for a game!',
        Tradition.sheshBesh => languageLevel > 0.5
            ? '!צהריים טובים! בוא נשחק'
            : 'Good afternoon! Let\'s play!',
      };

  String eveningGreeting(double languageLevel) => switch (tradition) {
        Tradition.tavli => languageLevel > 0.5
            ? 'Καληνύχτα soon... one more game?'
            : 'Getting late... one more game?',
        Tradition.tavla => languageLevel > 0.5
            ? 'İyi akşamlar! Son bir oyun?'
            : 'Good evening! One last game?',
        Tradition.nardy => languageLevel > 0.5
            ? 'Добрый вечер! Ещё партию?'
            : 'Good evening! One more round?',
        Tradition.sheshBesh => languageLevel > 0.5
            ? '?ערב טוב! עוד סיבוב'
            : 'Good evening! Another round?',
      };

  /// Serialize to string for SharedPreferences.
  String toStorageKey() => name;

  /// Deserialize from SharedPreferences string.
  static BotPersonality fromStorageKey(String? key) {
    if (key == null) return mikhail;
    return BotPersonality.values.where((p) => p.name == key).firstOrNull ??
        mikhail;
  }
}
