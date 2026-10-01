/// Tavli bot: position evaluation and time-budgeted search.
///
/// Pure Dart. In the app it runs inside a long-lived worker isolate so no
/// search ever touches the UI isolate.
library;

import 'package:tavli_core/tavli_core.dart';

/// The core schema version this bot build understands. Worker requests carrying
/// a different version are rejected rather than mis-decoded.
const int tavliBotCoreSchemaVersion = tavliCoreSchemaVersion;
