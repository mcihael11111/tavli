import '../../game/domain/engine/variants/game_variant.dart';

/// Data for the mechanic deep-dive comparison screens.
class MechanicComparison {
  final String title;
  final String description;
  final List<GameVariant> variants;
  final List<ComparisonRow> rows;

  const MechanicComparison({
    required this.title,
    required this.description,
    required this.variants,
    required this.rows,
  });
}

class ComparisonRow {
  final String rule;
  final Map<GameVariant, String> values;

  const ComparisonRow({
    required this.rule,
    required this.values,
  });
}

const hittingComparison = MechanicComparison(
  title: 'Hitting Games Compared',
  description: 'Four hitting variants across traditions — '
      'same core mechanic, different rules.',
  variants: [
    GameVariant.portes,
    GameVariant.tavla,
    GameVariant.shortNard,
    GameVariant.sheshBesh,
  ],
  rows: [
    ComparisonRow(
      rule: 'Hit-and-run',
      values: {
        GameVariant.portes: 'No',
        GameVariant.tavla: 'No',
        GameVariant.shortNard: 'Yes',
        GameVariant.sheshBesh: 'Yes',
      },
    ),
    ComparisonRow(
      rule: 'Doubling cube',
      values: {
        GameVariant.portes: 'No',
        GameVariant.tavla: 'No',
        GameVariant.shortNard: 'Yes',
        GameVariant.sheshBesh: 'No',
      },
    ),
    ComparisonRow(
      rule: 'Winner re-rolls',
      values: {
        GameVariant.portes: 'Yes',
        GameVariant.tavla: 'Yes',
        GameVariant.shortNard: 'No',
        GameVariant.sheshBesh: 'Yes',
      },
    ),
    ComparisonRow(
      rule: 'Backgammon (3×)',
      values: {
        GameVariant.portes: 'No',
        GameVariant.tavla: 'No',
        GameVariant.shortNard: 'Yes',
        GameVariant.sheshBesh: 'No',
      },
    ),
    ComparisonRow(
      rule: 'Jacoby rule',
      values: {
        GameVariant.portes: '—',
        GameVariant.tavla: '—',
        GameVariant.shortNard: 'Yes',
        GameVariant.sheshBesh: '—',
      },
    ),
  ],
);

const pinningComparison = MechanicComparison(
  title: 'Pinning Games Compared',
  description: 'Three pinning variants — the mother piece rule is the key difference.',
  variants: [
    GameVariant.plakoto,
    GameVariant.tapa,
    GameVariant.mahbusa,
  ],
  rows: [
    ComparisonRow(
      rule: 'Mother piece rule',
      values: {
        GameVariant.plakoto: 'Yes',
        GameVariant.tapa: 'No',
        GameVariant.mahbusa: 'Yes',
      },
    ),
    ComparisonRow(
      rule: 'Mother = auto-loss',
      values: {
        GameVariant.plakoto: '2 pts',
        GameVariant.tapa: '—',
        GameVariant.mahbusa: '2 pts',
      },
    ),
    ComparisonRow(
      rule: 'Both mothers pinned',
      values: {
        GameVariant.plakoto: 'Draw',
        GameVariant.tapa: '—',
        GameVariant.mahbusa: 'Draw',
      },
    ),
    ComparisonRow(
      rule: 'Movement direction',
      values: {
        GameVariant.plakoto: 'Opposite',
        GameVariant.tapa: 'Opposite',
        GameVariant.mahbusa: 'Opposite',
      },
    ),
  ],
);

const runningComparison = MechanicComparison(
  title: 'Running Games Compared',
  description: 'Four running variants — blocking without captures, each with a twist.',
  variants: [
    GameVariant.fevga,
    GameVariant.moultezim,
    GameVariant.longNard,
    GameVariant.gulBara,
  ],
  rows: [
    ComparisonRow(
      rule: 'Head rule',
      values: {
        GameVariant.fevga: 'No',
        GameVariant.moultezim: 'No',
        GameVariant.longNard: 'Yes',
        GameVariant.gulBara: 'No',
      },
    ),
    ComparisonRow(
      rule: 'Head exception',
      values: {
        GameVariant.fevga: '—',
        GameVariant.moultezim: '—',
        GameVariant.longNard: '3-3, 4-4, 6-6',
        GameVariant.gulBara: '—',
      },
    ),
    ComparisonRow(
      rule: 'Cascading doubles',
      values: {
        GameVariant.fevga: 'No',
        GameVariant.moultezim: 'No',
        GameVariant.longNard: 'No',
        GameVariant.gulBara: 'Yes',
      },
    ),
    ComparisonRow(
      rule: 'Cascade starts after',
      values: {
        GameVariant.fevga: '—',
        GameVariant.moultezim: '—',
        GameVariant.longNard: '—',
        GameVariant.gulBara: 'Roll 3',
      },
    ),
    ComparisonRow(
      rule: 'Advancement rule',
      values: {
        GameVariant.fevga: 'Yes',
        GameVariant.moultezim: 'Yes',
        GameVariant.longNard: 'No',
        GameVariant.gulBara: 'Yes',
      },
    ),
    ComparisonRow(
      rule: 'Max prime (trapping)',
      values: {
        GameVariant.fevga: '5',
        GameVariant.moultezim: '5',
        GameVariant.longNard: '5',
        GameVariant.gulBara: '5',
      },
    ),
  ],
);
