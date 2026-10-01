/// Tavli rules engine and game model.
///
/// Pure Dart: no Flutter, no I/O, no randomness. Shared verbatim by the
/// mobile app and the Cloud Run game server so both always agree on rules.
library;

export 'src/board/board_view.dart';
export 'src/board/geometry.dart';
export 'src/board/position.dart';
export 'src/board/side.dart';
export 'src/variant/catalog.dart';
export 'src/variant/variant.dart';
export 'src/variant/variant_rules.dart';

/// Version of the serialized state / action-log format.
///
/// Bump when the wire format changes; readers must reject unknown versions.
const int tavliCoreSchemaVersion = 1;
