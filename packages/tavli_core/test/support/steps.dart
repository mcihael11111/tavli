/// Helpers for single-step rule tests.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

typedef S = Side;

final hitRules = StepRules(Variant.portes.rules);
final pinRules = StepRules(Variant.plakoto.rules);
final blockRules = StepRules(Variant.fevga.rules);

Set<Step> stepsOf(StepRules r, BoardView p, Side s, int die) =>
    r.basicSteps(p, s, die).toSet();

Set<Step> allStepsOf(StepRules r, BoardView p, Side s) => {
      for (var d = 1; d <= 6; d++) ...r.basicSteps(p, s, d),
    };

/// Applies [step], checks [after], undoes, and checks exact restoration.
AppliedStep roundTrip(
  StepRules r,
  Position p,
  Side s,
  Step step, {
  Position? after,
}) {
  final m = p.toMutable();
  final a = r.apply(m, s, step);
  expect(a.step, step);
  if (after != null) expect(m.freeze(), after);
  r.undo(m, s, a);
  expect(m.freeze(), p, reason: 'undo(apply(x)) == x');
  return a;
}
