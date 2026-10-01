/// Tavli rules engine and game model.
///
/// Pure Dart: no Flutter, no I/O, no randomness. Shared verbatim by the
/// mobile app and the Cloud Run game server so both always agree on rules.
library;

/// Version of the serialized state / action-log format.
///
/// Bump when the wire format changes; readers must reject unknown versions.
const int tavliCoreSchemaVersion = 1;
