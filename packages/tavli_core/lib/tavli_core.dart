/// Tavli rules engine and game model.
///
/// Pure Dart: no Flutter, no I/O, no randomness. Shared verbatim by the
/// mobile app and the Cloud Run game server so both always agree on rules.
library;

export 'src/board/board_view.dart';
export 'src/board/geometry.dart';
export 'src/board/position.dart';
export 'src/board/side.dart';
export 'src/game/cube.dart';
export 'src/game/dice.dart';
export 'src/game/game_action.dart';
export 'src/game/game_event.dart';
export 'src/game/game_result.dart';
export 'src/game/game_state.dart';
export 'src/game/rule_violation.dart';
export 'src/match/match.dart';
export 'src/match/match_action.dart';
export 'src/match/match_config.dart';
export 'src/match/match_event.dart';
export 'src/play/play.dart';
export 'src/play/play_generator.dart';
export 'src/play/step.dart';
export 'src/rules/game_end.dart';
export 'src/rules/step_rules.dart';
export 'src/rules/step_validators.dart';
export 'src/rules/turn_context.dart';
export 'src/serial/game_log.dart';
export 'src/serial/json_read.dart' show tavliCoreSchemaVersion;
export 'src/variant/catalog.dart';
export 'src/variant/variant.dart';
export 'src/variant/variant_rules.dart';
