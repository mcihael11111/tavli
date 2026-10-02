/// Evaluator dispatch: race or family (design spec SP2 §4).
library;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';
import 'features.dart';
import 'hitting_eval.dart';
import 'pinning_eval.dart';
import 'race_eval.dart';
import 'running_eval.dart';

/// The evaluator for [r]: a [DispatchEvaluator] over its family.
DispatchEvaluator evaluatorFor(VariantRules r) =>
    DispatchEvaluator(familyEvaluatorFor(r));

/// The family evaluator for [r], by contact type: hit, pin or block.
Evaluator familyEvaluatorFor(VariantRules r) => switch (r.contact) {
      Contact.hit => const HittingEvaluator(),
      Contact.pin => const PinningEvaluator(),
      Contact.block => const RunningEvaluator(),
    };

/// Uses [race] for a no-contact race ([isRace]) and [family] otherwise.
/// [isRace] does not depend on the side, so this stays antisymmetric.
final class DispatchEvaluator implements Evaluator {
  const DispatchEvaluator(this.family, {this.race = const RaceEvaluator()});

  final Evaluator family;
  final Evaluator race;

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) =>
      isRace(p, r) ? race.evaluate(p, me, r) : family.evaluate(p, me, r);
}
