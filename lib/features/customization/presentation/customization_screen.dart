import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/settings_service.dart';

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

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  void _selectBoard(WidgetRef ref, int index) {
    ref.read(selectedBoardProvider.notifier).state = index;
    SettingsService.instance.boardSet = index;
  }

  void _selectCheckers(WidgetRef ref, int index) {
    ref.read(selectedCheckersProvider.notifier).state = index;
    SettingsService.instance.checkerSet = index;
  }

  void _selectDice(WidgetRef ref, int index) {
    ref.read(selectedDiceProvider.notifier).state = index;
    SettingsService.instance.diceSet = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(TavliSpacing.md),
          children: [
            const SizedBox(height: TavliSpacing.xl),
            Text(
              'Customize',
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TavliSpacing.lg),
            const _SectionTitle('Board'),
            const SizedBox(height: TavliSpacing.sm),
            Row(
              children: [
                _BoardOption(
                  index: 1,
                  name: 'Μαόνι',
                  subtitle: 'Mahogany & Olive',
                  colors: const [TavliColors.mahoganyDark, TavliColors.oliveWoodLight],
                  selected: ref.watch(selectedBoardProvider) == 1,
                  onTap: () => _selectBoard(ref, 1),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _BoardOption(
                  index: 2,
                  name: 'Σμαραγδί',
                  subtitle: 'Mahogany & Teal',
                  colors: const [TavliColors.tealFrameDark, TavliColors.tealPointLight],
                  selected: ref.watch(selectedBoardProvider) == 2,
                  onTap: () => _selectBoard(ref, 2),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _BoardOption(
                  index: 3,
                  name: 'Νυχτερινό',
                  subtitle: 'Walnut & Navy',
                  colors: const [TavliColors.darkWalnutDark, TavliColors.navyDark],
                  selected: ref.watch(selectedBoardProvider) == 3,
                  onTap: () => _selectBoard(ref, 3),
                ),
              ],
            ),
            const SizedBox(height: TavliSpacing.lg),
            const _SectionTitle('Checkers'),
            const SizedBox(height: TavliSpacing.sm),
            Row(
              children: [
                _CheckerOption(
                  index: 1,
                  name: 'Κλασικό',
                  subtitle: 'Classic',
                  darkColor: TavliColors.checkerDark,
                  lightColor: TavliColors.checkerLight,
                  selected: ref.watch(selectedCheckersProvider) == 1,
                  onTap: () => _selectCheckers(ref, 1),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _CheckerOption(
                  index: 2,
                  name: 'Ρουμπίνι',
                  subtitle: 'Ruby',
                  darkColor: const Color(0xFF8B1A1A),
                  lightColor: TavliColors.checkerLight,
                  selected: ref.watch(selectedCheckersProvider) == 2,
                  onTap: () => _selectCheckers(ref, 2),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _CheckerOption(
                  index: 3,
                  name: 'Ελιά',
                  subtitle: 'Olive',
                  darkColor: const Color(0xFF4A4A4A),
                  lightColor: const Color(0xFF8B9A6B),
                  selected: ref.watch(selectedCheckersProvider) == 3,
                  onTap: () => _selectCheckers(ref, 3),
                ),
              ],
            ),
            const SizedBox(height: TavliSpacing.lg),
            const _SectionTitle('Dice'),
            const SizedBox(height: TavliSpacing.sm),
            Row(
              children: [
                _DiceOption(
                  index: 1,
                  name: 'Κλασικό',
                  color: const Color(0xFFFAF8F0),
                  pipColor: TavliColors.checkerDark,
                  selected: ref.watch(selectedDiceProvider) == 1,
                  onTap: () => _selectDice(ref, 1),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _DiceOption(
                  index: 2,
                  name: 'Ρουμπίνι',
                  color: const Color(0xFFFAF8F0),
                  pipColor: const Color(0xFF8B1A1A),
                  selected: ref.watch(selectedDiceProvider) == 2,
                  onTap: () => _selectDice(ref, 2),
                ),
                const SizedBox(width: TavliSpacing.sm),
                _DiceOption(
                  index: 3,
                  name: 'Ελιά',
                  color: const Color(0xFFF0EDE0),
                  pipColor: const Color(0xFF4A4A4A),
                  selected: ref.watch(selectedDiceProvider) == 3,
                  onTap: () => _selectDice(ref, 3),
                ),
              ],
            ),
            const SizedBox(height: TavliSpacing.xl),
            Container(
              decoration: BoxDecoration(
                color: TavliColors.primary,
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(color: TavliColors.background),
                boxShadow: TavliShadows.xsmall,
              ),
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: TavliColors.light, size: 20),
                  const SizedBox(width: TavliSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your selections will be applied in the next game.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: TavliColors.light,
                      ),
                    ),
                  ),
                ],
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _BoardOption extends StatelessWidget {
  final int index;
  final String name;
  final String subtitle;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  const _BoardOption({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$name board set, $subtitle',
        child: Material(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: TavliColors.background,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TavliRadius.sm),
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xs),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TavliColors.light,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: TavliColors.background,
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle, size: 16, color: TavliColors.light),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckerOption extends StatelessWidget {
  final int index;
  final String name;
  final String subtitle;
  final Color darkColor;
  final Color lightColor;
  final bool selected;
  final VoidCallback onTap;

  const _CheckerOption({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.darkColor,
    required this.lightColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$name checker set, $subtitle',
        child: Material(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: TavliColors.background,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: darkColor),
                      const SizedBox(width: TavliSpacing.xs),
                      CircleAvatar(radius: 16, backgroundColor: lightColor),
                    ],
                  ),
                  const SizedBox(height: TavliSpacing.xs),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TavliColors.light,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: TavliColors.background,
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle, size: 16, color: TavliColors.light),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceOption extends StatelessWidget {
  final int index;
  final String name;
  final Color color;
  final Color pipColor;
  final bool selected;
  final VoidCallback onTap;

  const _DiceOption({
    required this.index,
    required this.name,
    required this.color,
    required this.pipColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$name dice set',
        child: Material(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(
                  color: TavliColors.background,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(TavliSpacing.md),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(TavliRadius.sm),
                      border: Border.all(
                        color: pipColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xs),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TavliColors.light,
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle, size: 16, color: TavliColors.light),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
