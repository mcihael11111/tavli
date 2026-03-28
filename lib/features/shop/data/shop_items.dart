import 'package:shared_preferences/shared_preferences.dart';

/// Category of a shop item.
enum ShopCategory {
  board,
  checkers,
  dice,
  table,
  avatar,
}

/// A purchasable cosmetic item.
class ShopItem {
  final String id;
  final String name;
  final String nameGreek;
  final String description;
  final ShopCategory category;
  final int priceCoins;
  final String? iapProductId; // null = coins only, non-null = real money IAP
  final bool isPremium;

  const ShopItem({
    required this.id,
    required this.name,
    required this.nameGreek,
    required this.description,
    required this.category,
    required this.priceCoins,
    this.iapProductId,
    this.isPremium = false,
  });
}

/// All shop items available in the game.
abstract final class ShopItems {
  static const List<ShopItem> all = [
    // ── Earnable Board Sets (unlockable with coins) ───────────
    ShopItem(
      id: 'board_set_2',
      name: 'Teal Board',
      nameGreek: 'Σμαραγδί',
      description: 'Mahogany & Teal board set.',
      category: ShopCategory.board,
      priceCoins: 300,
    ),
    ShopItem(
      id: 'board_set_3',
      name: 'Night Board',
      nameGreek: 'Νυχτερινό',
      description: 'Dark Walnut & Navy board set.',
      category: ShopCategory.board,
      priceCoins: 300,
    ),

    // ── Earnable Checker Sets ─────────────────────────────────
    ShopItem(
      id: 'checker_set_2',
      name: 'Ruby Checkers',
      nameGreek: 'Ρουμπίνι',
      description: 'Ivory & deep red checker set.',
      category: ShopCategory.checkers,
      priceCoins: 250,
    ),
    ShopItem(
      id: 'checker_set_3',
      name: 'Olive Checkers',
      nameGreek: 'Ελιά',
      description: 'Warm gray & olive green checker set.',
      category: ShopCategory.checkers,
      priceCoins: 250,
    ),

    // ── Earnable Dice Sets ────────────────────────────────────
    ShopItem(
      id: 'dice_set_2',
      name: 'Ruby Dice',
      nameGreek: 'Ρουμπίνι',
      description: 'Classic dice with ruby-red pips.',
      category: ShopCategory.dice,
      priceCoins: 200,
    ),
    ShopItem(
      id: 'dice_set_3',
      name: 'Olive Dice',
      nameGreek: 'Ελιά',
      description: 'Subtle dice with gray pips.',
      category: ShopCategory.dice,
      priceCoins: 200,
    ),

    // ── Premium Board Sets ────────────────────────────────────
    ShopItem(
      id: 'board_marble',
      name: 'Marble Palace',
      nameGreek: 'Μαρμάρινο Παλάτι',
      description: 'White Thassos marble with gold inlay.',
      category: ShopCategory.board,
      priceCoins: 500,
    ),
    ShopItem(
      id: 'board_aegean',
      name: 'Aegean Blue',
      nameGreek: 'Αιγαιοπελαγίτικο',
      description: 'Blue and white, inspired by Santorini.',
      category: ShopCategory.board,
      priceCoins: 500,
    ),
    ShopItem(
      id: 'board_olive_grove',
      name: 'Olive Grove',
      nameGreek: 'Ελαιώνας',
      description: 'Hand-carved olive wood from Kalamata.',
      category: ShopCategory.board,
      priceCoins: 750,
    ),
    ShopItem(
      id: 'board_byzantine',
      name: 'Byzantine Gold',
      nameGreek: 'Βυζαντινό Χρυσό',
      description: 'Ornate gold and purple Byzantine motifs.',
      category: ShopCategory.board,
      priceCoins: 1000,
      isPremium: true,
      iapProductId: 'com.tavli.board.byzantine',
    ),

    // ── Premium Checker Sets ──────────────────────────────────
    ShopItem(
      id: 'checker_onyx',
      name: 'Onyx & Pearl',
      nameGreek: 'Όνυχας & Μαργαριτάρι',
      description: 'Polished onyx and mother-of-pearl checkers.',
      category: ShopCategory.checkers,
      priceCoins: 400,
    ),
    ShopItem(
      id: 'checker_coral',
      name: 'Coral Reef',
      nameGreek: 'Κοραλλί',
      description: 'Mediterranean coral and turquoise.',
      category: ShopCategory.checkers,
      priceCoins: 400,
    ),
    ShopItem(
      id: 'checker_gold',
      name: 'Gold & Silver',
      nameGreek: 'Χρυσό & Ασήμι',
      description: 'Metallic gold and silver checkers.',
      category: ShopCategory.checkers,
      priceCoins: 600,
      isPremium: true,
      iapProductId: 'com.tavli.checker.gold',
    ),

    // ── Premium Dice Sets ─────────────────────────────────────
    ShopItem(
      id: 'dice_crystal',
      name: 'Crystal',
      nameGreek: 'Κρύσταλλο',
      description: 'Translucent crystal dice with gold pips.',
      category: ShopCategory.dice,
      priceCoins: 300,
    ),
    ShopItem(
      id: 'dice_obsidian',
      name: 'Obsidian',
      nameGreek: 'Οψιδιανός',
      description: 'Black volcanic glass with silver pips.',
      category: ShopCategory.dice,
      priceCoins: 300,
    ),

    // ── Table Surfaces ────────────────────────────────────────
    ShopItem(
      id: 'table_kafeneio',
      name: 'Kafeneio Table',
      nameGreek: 'Τραπέζι Καφενείου',
      description: 'Worn wooden table from a Greek kafeneio.',
      category: ShopCategory.table,
      priceCoins: 200,
    ),
    ShopItem(
      id: 'table_yacht',
      name: 'Yacht Deck',
      nameGreek: 'Κατάστρωμα Θαλαμηγού',
      description: 'Polished teak on the Aegean Sea.',
      category: ShopCategory.table,
      priceCoins: 400,
    ),
    ShopItem(
      id: 'table_palace',
      name: 'Palace Floor',
      nameGreek: 'Δάπεδο Ανακτόρου',
      description: 'Marble floor of a neoclassical mansion.',
      category: ShopCategory.table,
      priceCoins: 600,
      isPremium: true,
      iapProductId: 'com.tavli.table.palace',
    ),

    // ── Avatar Frames ─────────────────────────────────────────
    ShopItem(
      id: 'avatar_laurel',
      name: 'Laurel Wreath',
      nameGreek: 'Δάφνινο Στεφάνι',
      description: 'Golden laurel wreath border.',
      category: ShopCategory.avatar,
      priceCoins: 250,
    ),
    ShopItem(
      id: 'avatar_meander',
      name: 'Greek Key',
      nameGreek: 'Μαίανδρος',
      description: 'Ancient Greek meander pattern frame.',
      category: ShopCategory.avatar,
      priceCoins: 250,
    ),
  ];

  static ShopItem? byId(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ShopItem> byCategory(ShopCategory category) {
    return all.where((item) => item.category == category).toList();
  }
}

/// Maps shop item IDs to the set index used by SettingsService.
abstract final class ShopItemSets {
  /// Board shop-item-id → boardSet index.
  static const boardSetIndex = {
    'board_set_2': 2,
    'board_set_3': 3,
  };

  /// Checker shop-item-id → checkerSet index.
  static const checkerSetIndex = {
    'checker_set_2': 2,
    'checker_set_3': 3,
  };

  /// Dice shop-item-id → diceSet index.
  static const diceSetIndex = {
    'dice_set_2': 2,
    'dice_set_3': 3,
  };

  /// Returns the shop item ID for a given board set index, or null for the default.
  static String? boardIdForSet(int setIndex) =>
      boardSetIndex.entries
          .where((e) => e.value == setIndex)
          .map((e) => e.key)
          .firstOrNull;

  /// Returns the shop item ID for a given checker set index, or null for the default.
  static String? checkerIdForSet(int setIndex) =>
      checkerSetIndex.entries
          .where((e) => e.value == setIndex)
          .map((e) => e.key)
          .firstOrNull;

  /// Returns the shop item ID for a given dice set index, or null for the default.
  static String? diceIdForSet(int setIndex) =>
      diceSetIndex.entries
          .where((e) => e.value == setIndex)
          .map((e) => e.key)
          .firstOrNull;
}

/// Tracks player's coin balance and purchased items.
class ShopService {
  static const _coinsKey = 'tavli_coins';
  static const _purchasedKey = 'tavli_purchased_items';
  static const _initializedKey = 'tavli_shop_initialized';

  static ShopService? _instance;
  final SharedPreferences _prefs;

  int _coins;
  final Set<String> _purchased;

  ShopService._(this._prefs, this._coins, this._purchased);

  static Future<ShopService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();

    // First-time initialization: 50 starting coins.
    // For existing users who already had 100, leave their balance.
    final isNew = !(prefs.containsKey(_initializedKey));
    final coins = isNew ? 50 : (prefs.getInt(_coinsKey) ?? 50);
    if (isNew) {
      await prefs.setBool(_initializedKey, true);
      await prefs.setInt(_coinsKey, coins);
    }

    final purchased = prefs.getStringList(_purchasedKey)?.toSet() ?? {};

    // Grandfather existing users: if they had board/checker/dice set != 1
    // before the shop existed, grant those items for free.
    _grandfatherExistingSelections(prefs, purchased);

    _instance = ShopService._(prefs, coins, purchased);
    return _instance!;
  }

  static void _grandfatherExistingSelections(
    SharedPreferences prefs,
    Set<String> purchased,
  ) {
    final boardSet = prefs.getInt('tavli_board_set') ?? 1;
    final checkerSet = prefs.getInt('tavli_checker_set') ?? 1;
    final diceSet = prefs.getInt('tavli_dice_set') ?? 1;

    final boardId = ShopItemSets.boardIdForSet(boardSet);
    if (boardId != null) purchased.add(boardId);

    final checkerId = ShopItemSets.checkerIdForSet(checkerSet);
    if (checkerId != null) purchased.add(checkerId);

    final diceId = ShopItemSets.diceIdForSet(diceSet);
    if (diceId != null) purchased.add(diceId);

    if (purchased.isNotEmpty) {
      prefs.setStringList(_purchasedKey, purchased.toList());
    }
  }

  static ShopService get instance {
    if (_instance == null) throw StateError('ShopService not initialized.');
    return _instance!;
  }

  int get coins => _coins;
  Set<String> get purchasedItems => Set.unmodifiable(_purchased);

  bool isOwned(String itemId) => _purchased.contains(itemId);

  bool canAfford(ShopItem item) => _coins >= item.priceCoins;

  /// Whether a board set index is owned (set 1 is always free).
  bool isBoardSetOwned(int setIndex) {
    if (setIndex == 1) return true;
    final id = ShopItemSets.boardIdForSet(setIndex);
    return id != null && _purchased.contains(id);
  }

  /// Whether a checker set index is owned (set 1 is always free).
  bool isCheckerSetOwned(int setIndex) {
    if (setIndex == 1) return true;
    final id = ShopItemSets.checkerIdForSet(setIndex);
    return id != null && _purchased.contains(id);
  }

  /// Whether a dice set index is owned (set 1 is always free).
  bool isDiceSetOwned(int setIndex) {
    if (setIndex == 1) return true;
    final id = ShopItemSets.diceIdForSet(setIndex);
    return id != null && _purchased.contains(id);
  }

  /// Purchase an item with coins. Returns true if successful.
  bool purchaseWithCoins(ShopItem item) {
    if (_purchased.contains(item.id)) return false;
    if (_coins < item.priceCoins) return false;

    _coins -= item.priceCoins;
    _purchased.add(item.id);
    _save();
    return true;
  }

  /// Grant coins (from winning games, achievements, etc.).
  void addCoins(int amount) {
    _coins += amount;
    _save();
  }

  /// Grant an item directly (from IAP or achievement reward).
  void grantItem(String itemId) {
    _purchased.add(itemId);
    _save();
  }

  void _save() {
    _prefs.setInt(_coinsKey, _coins);
    _prefs.setStringList(_purchasedKey, _purchased.toList());
  }
}
