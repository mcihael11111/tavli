/// The human's selection on the board (design §3, `UiSelection`).
library;

import 'package:flutter/foundation.dart';
import 'package:tavli_bot/tavli_bot.dart' show StepQuality;
import 'package:tavli_core/tavli_core.dart';

/// One legal destination of the selected source.
@immutable
final class Highlight {
  const Highlight(this.step, {this.hit = false, this.quality});

  /// The step a tap on [to] plays (the die already disambiguated).
  final Step step;

  /// The destination lands on a lone opposing checker: a hit in hitting
  /// games, a pin in pinning games.
  final bool hit;

  /// Teaching mode: how good [step] is; null without an analysis.
  final StepQuality? quality;

  /// Player-relative destination pip (0 = borne off).
  int get to => step.to;
  int get die => step.die;

  Highlight withQuality(StepQuality? q) =>
      Highlight(step, hit: hit, quality: q);

  @override
  bool operator ==(Object other) =>
      other is Highlight &&
      other.step == step &&
      other.hit == hit &&
      other.quality == quality;

  @override
  int get hashCode => Object.hash(step, hit, quality);

  @override
  String toString() =>
      'Highlight($step${hit ? ' hit' : ''}${quality == null ? '' : ' ${quality!.name}'})';
}

/// The selection state of the side to move. All pips are player-relative
/// for that side (25 = bar, 0 = off); the board maps them through its
/// `ViewTransform`.
@immutable
final class UiSelection {
  UiSelection({
    this.source,
    this.activeDie,
    List<Highlight> highlights = const [],
    Set<int> sources = const {},
  })  : highlights = List.unmodifiable(highlights),
        sources = Set.unmodifiable(sources);

  /// Nothing selectable (not the human's moving phase).
  static final none = UiSelection();

  /// The selected source pip, if any.
  final int? source;

  /// The die value [quickMove] tries first, among the dice still to play;
  /// null outside a moving phase. Tapping the dice swaps it.
  final int? activeDie;

  /// One per legal destination of [source], in `nextSteps` order.
  final List<Highlight> highlights;

  /// Every pip a step can start from now.
  final Set<int> sources;

  /// The highlight for [to], if [to] is a legal destination.
  Highlight? at(int to) {
    for (final h in highlights) {
      if (h.to == to) return h;
    }
    return null;
  }

  UiSelection copyWith({int? activeDie, List<Highlight>? highlights}) =>
      UiSelection(
        source: source,
        activeDie: activeDie ?? this.activeDie,
        highlights: highlights ?? this.highlights,
        sources: sources,
      );

  @override
  bool operator ==(Object other) =>
      other is UiSelection &&
      other.source == source &&
      other.activeDie == activeDie &&
      listEquals(other.highlights, highlights) &&
      setEquals(other.sources, sources);

  @override
  int get hashCode => Object.hash(source, activeDie, Object.hashAll(highlights),
      Object.hashAllUnordered(sources));

  @override
  String toString() =>
      'UiSelection(source: $source, die: $activeDie, $highlights)';
}
