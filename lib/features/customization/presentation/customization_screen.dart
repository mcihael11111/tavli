import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/providers/accessibility_providers.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../shop/data/shop_items.dart';

// Providers read initial values from persisted settings.
final selectedBoardProvider = StateProvider<int>((ref) {
  return SettingsService.instance.boardSet;
});
final selectedCheckersProvider = StateProvider<int>((ref) {
  return SettingsService.instance.checkerSet;
});
final selectedDiceProvider = StateProvider<int>((ref) {
  return SettingsService.instance.diceSet;
});

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() =>
      _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen> {
  void _selectBoard(WidgetRef ref, int index) {
    final shop = ShopService.instance;
    if (!shop.isBoardSetOwned(index)) {
      _showLockedSnackBar(context);
      return;
    }
    ref.read(selectedBoardProvider.notifier).state = index;
    SettingsService.instance.boardSet = index;
  }

  void _selectCheckers(WidgetRef ref, int index) {
    final shop = ShopService.instance;
    if (!shop.isCheckerSetOwned(index)) {
      _showLockedSnackBar(context);
      return;
    }
    ref.read(selectedCheckersProvider.notifier).state = index;
    SettingsService.instance.checkerSet = index;
  }

  void _selectDice(WidgetRef ref, int index) {
    final shop = ShopService.instance;
    if (!shop.isDiceSetOwned(index)) {
      _showLockedSnackBar(context);
      return;
    }
    ref.read(selectedDiceProvider.notifier).state = index;
    SettingsService.instance.diceSet = index;
  }

  void _showLockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Visit the Shop to unlock this item.'),
        action: SnackBarAction(
          label: 'Shop',
          onPressed: () => context.push('/shop'),
        ),
      ),
    );
  }

  static const double _cardWidth = 140;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = ShopService.instance;

    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
          children: [
            const SizedBox(height: TavliSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
              child: Text(
                TavliCopy.myCollection,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: TavliColors.light,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // Coin balance + shop link.
            Center(
              child: Semantics(
                button: true,
                label: 'Open shop',
                child: GestureDetector(
                  onTap: () => context.push('/shop'),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TavliSpacing.md,
                      vertical: TavliSpacing.xs,
                    ),
                  decoration: BoxDecoration(
                    color: TavliColors.primary,
                    borderRadius: BorderRadius.circular(TavliRadius.full),
                    border: Border.all(color: TavliColors.background.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 16, color: TavliColors.warning),
                      const SizedBox(width: TavliSpacing.xxs),
                      Text(
                        '${shop.coins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TavliColors.warning,
                        ),
                      ),
                      const SizedBox(width: TavliSpacing.sm),
                      const Icon(Icons.storefront,
                          size: 16, color: TavliColors.light),
                      const SizedBox(width: TavliSpacing.xxs),
                      Text(
                        'Shop',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: TavliColors.light,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),

            const SizedBox(height: TavliSpacing.lg),

            // ── Board section ──────────────────────────
            const _SectionHeader(icon: Icons.grid_on, title: 'Board'),
            const SizedBox(height: TavliSpacing.sm),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
                children: [
                  _BoardOption(
                    name: 'Μαόνι',
                    subtitle: 'Mahogany & Olive',
                    colors: const [TavliColors.mahoganyDark, TavliColors.oliveWoodLight],
                    selected: ref.watch(selectedBoardProvider) == 1,
                    owned: true,
                    onTap: () => _selectBoard(ref, 1),
                  ),
                  _BoardOption(
                    name: 'Σμαραγδί',
                    subtitle: 'Mahogany & Teal',
                    colors: const [TavliColors.tealFrameDark, TavliColors.tealPointLight],
                    selected: ref.watch(selectedBoardProvider) == 2,
                    owned: shop.isBoardSetOwned(2),
                    onTap: () => _selectBoard(ref, 2),
                  ),
                  _BoardOption(
                    name: 'Νυχτερινό',
                    subtitle: 'Walnut & Navy',
                    colors: const [TavliColors.darkWalnutDark, TavliColors.navyDark],
                    selected: ref.watch(selectedBoardProvider) == 3,
                    owned: shop.isBoardSetOwned(3),
                    onTap: () => _selectBoard(ref, 3),
                  ),
                  _BoardOption(
                    name: 'Ελληνικό',
                    subtitle: 'Greek Key',
                    colors: const [Color(0xFF3B5998), Color(0xFFC9A96E)],
                    selected: ref.watch(selectedBoardProvider) == 4,
                    owned: shop.isBoardSetOwned(4),
                    onTap: () => _selectBoard(ref, 4),
                  ),
                  _BoardOption(
                    name: 'Κεραμικό',
                    subtitle: 'Ceramic & Clay',
                    colors: const [Color(0xFFB85C38), Color(0xFFE0C097)],
                    selected: ref.watch(selectedBoardProvider) == 5,
                    owned: shop.isBoardSetOwned(5),
                    onTap: () => _selectBoard(ref, 5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.lg),

            // ── Checkers section ───────────────────────
            const _SectionHeader(icon: Icons.circle, title: 'Checkers'),
            const SizedBox(height: TavliSpacing.sm),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
                children: [
                  _CheckerOption(
                    name: 'Κλασικό',
                    subtitle: 'Classic',
                    darkColor: TavliColors.checkerDark,
                    lightColor: TavliColors.checkerLight,
                    selected: ref.watch(selectedCheckersProvider) == 1,
                    owned: true,
                    onTap: () => _selectCheckers(ref, 1),
                  ),
                  _CheckerOption(
                    name: 'Ρουμπίνι',
                    subtitle: 'Ruby',
                    darkColor: const Color(0xFF8B1A1A),
                    lightColor: TavliColors.checkerLight,
                    selected: ref.watch(selectedCheckersProvider) == 2,
                    owned: shop.isCheckerSetOwned(2),
                    onTap: () => _selectCheckers(ref, 2),
                  ),
                  _CheckerOption(
                    name: 'Ελιά',
                    subtitle: 'Olive',
                    darkColor: const Color(0xFF4A4A4A),
                    lightColor: const Color(0xFF8B9A6B),
                    selected: ref.watch(selectedCheckersProvider) == 3,
                    owned: shop.isCheckerSetOwned(3),
                    onTap: () => _selectCheckers(ref, 3),
                  ),
                  _CheckerOption(
                    name: 'Χαλκός',
                    subtitle: 'Copper',
                    darkColor: const Color(0xFF6B3A2A),
                    lightColor: const Color(0xFFB87333),
                    selected: ref.watch(selectedCheckersProvider) == 4,
                    owned: shop.isCheckerSetOwned(4),
                    onTap: () => _selectCheckers(ref, 4),
                  ),
                  _CheckerOption(
                    name: 'Μάρμαρο',
                    subtitle: 'Marble',
                    darkColor: const Color(0xFF2F2F2F),
                    lightColor: const Color(0xFFE8E4DE),
                    selected: ref.watch(selectedCheckersProvider) == 5,
                    owned: shop.isCheckerSetOwned(5),
                    onTap: () => _selectCheckers(ref, 5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.lg),

            // ── Dice section ───────────────────────────
            const _SectionHeader(icon: Icons.casino, title: 'Dice'),
            const SizedBox(height: TavliSpacing.sm),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
                children: [
                  _DiceOption(
                    name: 'Κλασικό',
                    color: const Color(0xFFFAF8F0),
                    pipColor: TavliColors.checkerDark,
                    selected: ref.watch(selectedDiceProvider) == 1,
                    owned: true,
                    onTap: () => _selectDice(ref, 1),
                  ),
                  _DiceOption(
                    name: 'Ρουμπίνι',
                    color: const Color(0xFFFAF8F0),
                    pipColor: const Color(0xFF8B1A1A),
                    selected: ref.watch(selectedDiceProvider) == 2,
                    owned: shop.isDiceSetOwned(2),
                    onTap: () => _selectDice(ref, 2),
                  ),
                  _DiceOption(
                    name: 'Ελιά',
                    color: const Color(0xFFF0EDE0),
                    pipColor: const Color(0xFF4A4A4A),
                    selected: ref.watch(selectedDiceProvider) == 3,
                    owned: shop.isDiceSetOwned(3),
                    onTap: () => _selectDice(ref, 3),
                  ),
                  _DiceOption(
                    name: 'Χαλκός',
                    color: const Color(0xFFD4A574),
                    pipColor: const Color(0xFF3D2415),
                    selected: ref.watch(selectedDiceProvider) == 4,
                    owned: shop.isDiceSetOwned(4),
                    onTap: () => _selectDice(ref, 4),
                  ),
                  _DiceOption(
                    name: 'Μάρμαρο',
                    color: const Color(0xFFE8E4DE),
                    pipColor: const Color(0xFF2F2F2F),
                    selected: ref.watch(selectedDiceProvider) == 5,
                    owned: shop.isDiceSetOwned(5),
                    onTap: () => _selectDice(ref, 5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.xl),

            // Info module.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: TavliSpacing.md),
              child: ContentModule(
                icon: Icons.info_outline,
                title: 'Note',
                body: 'Your selections will be applied in the next game.',
              ),
            ),

            // Extra padding for bottom nav gradient.
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

/// Section header with icon + title, matching ContentModule header style.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: TavliColors.light, size: 22),
          const SizedBox(width: TavliSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleLarge!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardOption extends StatelessWidget {
  final String name;
  final String subtitle;
  final List<Color> colors;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  const _BoardOption({
    required this.name,
    required this.subtitle,
    required this.colors,
    required this.selected,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _OptionCard(
      selected: selected,
      owned: owned,
      onTap: onTap,
      label: '$name board set, $subtitle${owned ? '' : ', locked'}',
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TavliRadius.sm),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              if (!owned)
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, color: TavliColors.light, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TavliSpacing.xs),
          Text(
            name,
            style: theme.textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w600,
              color: owned ? TavliColors.light : TavliColors.disabledOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall!.copyWith(
              color: TavliColors.disabledOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (selected && owned)
            const Padding(
              padding: EdgeInsets.only(top: TavliSpacing.xxs),
              child: Icon(Icons.check_circle, size: 22, color: TavliColors.light),
            ),
        ],
      ),
    );
  }
}

class _CheckerOption extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color darkColor;
  final Color lightColor;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  const _CheckerOption({
    required this.name,
    required this.subtitle,
    required this.darkColor,
    required this.lightColor,
    required this.selected,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _OptionCard(
      selected: selected,
      owned: owned,
      onTap: onTap,
      label: '$name checker set, $subtitle${owned ? '' : ', locked'}',
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 20, backgroundColor: darkColor),
                  const SizedBox(width: TavliSpacing.xs),
                  CircleAvatar(radius: 20, backgroundColor: lightColor),
                ],
              ),
              if (!owned)
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.lock,
                        color: TavliColors.light.withValues(alpha: 0.9),
                        size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TavliSpacing.xs),
          Text(
            name,
            style: theme.textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w600,
              color: owned ? TavliColors.light : TavliColors.disabledOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall!.copyWith(
              color: TavliColors.disabledOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (selected && owned)
            const Padding(
              padding: EdgeInsets.only(top: TavliSpacing.xxs),
              child: Icon(Icons.check_circle, size: 22, color: TavliColors.light),
            ),
        ],
      ),
    );
  }
}

class _DiceOption extends StatelessWidget {
  final String name;
  final Color color;
  final Color pipColor;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  const _DiceOption({
    required this.name,
    required this.color,
    required this.pipColor,
    required this.selected,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _OptionCard(
      selected: selected,
      owned: owned,
      onTap: onTap,
      label: '$name dice set${owned ? '' : ', locked'}',
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(TavliRadius.sm),
                  border: Border.all(
                    color: pipColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              if (!owned)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, color: TavliColors.light, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TavliSpacing.xs),
          Text(
            name,
            style: theme.textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w600,
              color: owned ? TavliColors.light : TavliColors.disabledOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (selected && owned)
            const Padding(
              padding: EdgeInsets.only(top: TavliSpacing.xxs),
              child: Icon(Icons.check_circle, size: 22, color: TavliColors.light),
            ),
        ],
      ),
    );
  }
}

/// Shared card container for all option types.
class _OptionCard extends StatefulWidget {
  final bool selected;
  final bool owned;
  final VoidCallback onTap;
  final String label;
  final Widget child;

  const _OptionCard({
    required this.selected,
    required this.owned,
    required this.onTap,
    required this.label,
    required this.child,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = _pressed
        ? (selected ? TavliColors.primaryActive : TavliColors.surfaceActive)
        : (selected ? TavliColors.primary : TavliColors.surface);

    return Padding(
      padding: const EdgeInsets.only(right: TavliSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: SizedBox(
            width: _CustomizationScreenState._cardWidth,
            child: AnimatedContainer(
              duration: ReducedMotion.duration(context, const Duration(milliseconds: 150)),
              curve: Curves.easeInOut,
              transform: _pressed
                  ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: selected ? TavliColors.background : TavliColors.primary,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected ? TavliShadows.xsmall : null,
              ),
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
