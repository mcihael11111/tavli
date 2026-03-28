import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../data/shop_items.dart';

/// In-app cosmetic shop screen.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedIndex = 0;

  static const _categories = [
    (ShopCategory.board, 'Boards', Icons.grid_on),
    (ShopCategory.checkers, 'Checkers', Icons.circle),
    (ShopCategory.dice, 'Dice', Icons.casino),
    (ShopCategory.table, 'Tables', Icons.table_restaurant),
    (ShopCategory.avatar, 'Avatars', Icons.face),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = ShopService.instance;
    final items = ShopItems.byCategory(_categories[_selectedIndex].$1);

    return GradientScaffold(
      appBar: AppBar(
        title: Text(TavliCopy.shop),
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
                    const SizedBox(width: TavliSpacing.xxs),
                    Text(
                      '${shop.coins}',
                      style: theme.textTheme.labelLarge?.copyWith(
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
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Spacer to clear the AppBar
            const SizedBox(height: kToolbarHeight + TavliSpacing.md),

            // Category tab segments (design spec §2.4)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
              child: _ShopTabBar(
                categories: _categories,
                selectedIndex: _selectedIndex,
                onChanged: (i) => setState(() => _selectedIndex = i),
              ),
            ),

            const SizedBox(height: TavliSpacing.md),

            // Grid content
            Expanded(
              child: _buildItemGrid(theme, items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(ThemeData theme, List<ShopItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Coming soon!',
          style: theme.textTheme.titleMedium?.copyWith(
            color: TavliColors.light,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        TavliSpacing.md,
        0,
        TavliSpacing.md,
        140, // Clear floating bottom nav
      ),
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
      useRootNavigator: true,
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

// ── Custom Tab Bar (design spec §2.4 Tab/Segment Card) ──────────────

class _ShopTabBar extends StatelessWidget {
  final List<(ShopCategory, String, IconData)> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ShopTabBar({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: TavliSpacing.xs),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final cat = categories[index];
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: TavliSpacing.md,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected ? TavliColors.primary : TavliColors.surface,
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: isSelected ? TavliColors.background : TavliColors.primary,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? TavliShadows.xsmall : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.$3,
                    size: 16,
                    color: isSelected
                        ? TavliColors.light
                        : TavliColors.light.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: TavliSpacing.xxs),
                  Text(
                    cat.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: TavliTheme.serifFamily,
                      color: isSelected
                          ? TavliColors.light
                          : TavliColors.light.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shop Item Card (ContentModule-aligned) ──────────────────────────

class _ShopItemCard extends StatefulWidget {
  final ShopItem item;
  final VoidCallback onPurchase;

  const _ShopItemCard({required this.item, required this.onPurchase});

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shop = ShopService.instance;
    final isOwned = shop.isOwned(widget.item.id);
    final canAfford = shop.canAfford(widget.item);

    final decoration = TavliModule.decoration(isDark: isDark).copyWith(
      border: Border.all(
        color: isOwned
            ? TavliColors.success.withValues(alpha: 0.5)
            : TavliModule.border,
        width: isOwned ? 2 : 1,
      ),
      color: _pressed
          ? TavliColors.background.withValues(alpha: 0.22)
          : (isDark ? TavliModule.fillDark : TavliModule.fill),
    );

    return GestureDetector(
      onTap: isOwned ? null : widget.onPurchase,
      onTapDown: isOwned ? null : (_) => setState(() => _pressed = true),
      onTapUp: isOwned ? null : (_) => setState(() => _pressed = false),
      onTapCancel: isOwned ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        transform: _pressed
            ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: decoration,
        padding: const EdgeInsets.all(TavliSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category icon + badge
            Row(
              children: [
                Icon(
                  _categoryIcon(widget.item.category),
                  color: TavliColors.light,
                  size: 20,
                ),
                const Spacer(),
                if (widget.item.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TavliSpacing.xs,
                      vertical: TavliSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: TavliColors.warning,
                      borderRadius:
                          BorderRadius.circular(TavliRadius.xs),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
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

            // Name (serif, matching ContentModule title style)
            Text(
              widget.item.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: TavliTheme.serifFamily,
                color: TavliColors.light,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Greek name
            Text(
              widget.item.nameGreek,
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
              widget.item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: TavliColors.light.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Price / Owned
            if (!isOwned)
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      size: 14, color: TavliColors.warning),
                  const SizedBox(width: TavliSpacing.xxs),
                  Text(
                    '${widget.item.priceCoins}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: canAfford
                          ? TavliColors.light
                          : TavliColors.error,
                    ),
                  ),
                ],
              )
            else
              Text(
                'OWNED',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TavliColors.success,
                  letterSpacing: 1,
                ),
              ),
          ],
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
