/// Tavli bot: position evaluation and time-budgeted search.
///
/// Pure Dart. In the app it runs inside a long-lived worker isolate so no
/// search ever touches the UI isolate.
library;

import 'package:tavli_core/tavli_core.dart';

export 'src/bot.dart';
export 'src/cube/cube_policy.dart';
export 'src/eval/eval_dispatch.dart';
export 'src/eval/evaluator.dart';
export 'src/eval/features.dart';
export 'src/eval/hitting_eval.dart';
export 'src/eval/pinning_eval.dart';
export 'src/eval/race_eval.dart';
export 'src/eval/running_eval.dart';
export 'src/level/bot_level.dart';
export 'src/search/search.dart';
export 'src/teach/analysis.dart';
export 'src/teach/analysis_types.dart';
export 'src/tournament/match_runner.dart';
export 'src/tournament/pairing_summary.dart';
export 'src/worker/bot_worker.dart';
export 'src/worker/protocol.dart';
export 'src/worker/request_builder.dart';

/// The core schema version this bot build was built against. Worker messages
/// stay inside one isolate group, so they share these Dart types directly and
/// carry no version; this records the version for serialized uses (logs).
const int tavliBotCoreSchemaVersion = tavliCoreSchemaVersion;
