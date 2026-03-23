import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../data/shop_items.dart';

/// In-app cosmetic shop screen.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = [
    (ShopCategory.board, 'Boards', Icons.grid_on),
    (ShopCategory.checkers, 'Checkers', Icons.circle),
    (ShopCategory.dice, 'Dice', Icons.casino),
    (ShopCategory.table, 'Tables', Icons.table_restaurant),
    (ShopCategory.avatar, 'Avatars', Icons.face),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = ShopService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: TavliSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TavliSpacing.sm,
                  vertical: TavliSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: TavliColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(TavliRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: TavliColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: TavliColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: TavliColors.primary,
          unselectedLabelColor: TavliColors.light.withValues(alpha: 0.5),
          indicatorColor: TavliColors.primary,
          tabs: _categories
              .map((c) => Tab(icon: Icon(c.$3, size: 20), text: c.$2))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((c) {
          final items = ShopItems.byCategory(c.$1);
          return _buildItemGrid(theme, items);
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid(ThemeData theme, List<ShopItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Coming soon!'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(TavliSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: TavliSpacing.sm,
        mainAxisSpacing: TavliSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ShopItemCard(
          item: items[index],
          onPurchase: () => _purchase(items[index]),
        );
      },
    );
  }

  void _purchase(ShopItem item) {
    final shop = ShopService.instance;

    if (shop.isOwned(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already own this item!')),
      );
      return;
    }

    if (item.iapProductId != null) {
      // TODO: Integrate with platform IAP (StoreKit / Google Play Billing)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium purchases coming soon!')),
      );
      return;
    }

    if (!shop.canAfford(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins! You need ${item.priceCoins - shop.coins} more.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text('This will cost ${item.priceCoins} coins.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              shop.purchaseWithCoins(item);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} purchased!')),
              );
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onPurchase;

  const _ShopItemCard({required this.item, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = ShopService.instance;
    final isOwned = shop.isOwned(item.id);
    final canAfford = shop.canAfford(item);

    return GestureDetector(
      onTap: isOwned ? null : onPurchase,
      child: Container(
        decoration: BoxDecoration(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(
            color: isOwned ? TavliColors.success : TavliColors.background,
            width: isOwned ? 2 : 1,
          ),
          boxShadow: TavliShadows.xsmall,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TavliSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Row(
                children: [
                  Icon(
                    _categoryIcon(item.category),
                    color: TavliColors.primary,
                    size: 20,
                  ),
                  const Spacer(),
                  if (item.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TavliColors.warning,
                        borderRadius: BorderRadius.circular(TavliRadius.xs),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: TavliColors.text,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (isOwned)
                    const Icon(Icons.check_circle,
                        color: TavliColors.success, size: 20),
                ],
              ),

              const Spacer(),

              // Name
              Text(
                item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.nameGreek,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: TavliColors.light.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: TavliSpacing.xxs),

              // Description
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: TavliColors.light.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Price
              if (!isOwned)
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 14, color: TavliColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${item.priceCoins}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: canAfford
                            ? TavliColors.light
                            : TavliColors.error,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'OWNED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TavliColors.success,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(ShopCategory cat) => switch (cat) {
        ShopCategory.board => Icons.grid_on,
        ShopCategory.checkers => Icons.circle,
        ShopCategory.dice => Icons.casino,
        ShopCategory.table => Icons.table_restaurant,
        ShopCategory.avatar => Icons.face,
      };
}
