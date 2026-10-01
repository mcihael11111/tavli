/// Strict readers for decoded JSON: every failure is a [FormatException].
library;

import '../board/side.dart';

/// Version of the serialized state / action-log format.
///
/// Bump when the wire format changes; readers reject other versions.
const int tavliCoreSchemaVersion = 1;

/// Typed access to one JSON object; [what] names it in error messages.
final class JsonReader {
  JsonReader(Object? json, this.what)
      : _j = json is Map<String, Object?>
            ? json
            : throw FormatException('$what: not a JSON object', json);

  final Map<String, Object?> _j;
  final String what;

  Never fail(String key, String expected) => throw FormatException(
      '$what: "$key" must be $expected', _j.containsKey(key) ? _j[key] : null);

  /// Throws unless `schemaVersion` equals [tavliCoreSchemaVersion].
  void checkSchema() {
    final v = _j['schemaVersion'];
    if (v != tavliCoreSchemaVersion) {
      throw FormatException('$what: unsupported schemaVersion $v '
          '(want $tavliCoreSchemaVersion)');
    }
  }

  Object? raw(String key) => _j[key];

  int integer(String key, {int min = 0, int max = 1 << 30}) {
    final v = _j[key];
    if (v is! int || v < min || v > max) fail(key, 'an int in $min..$max');
    return v;
  }

  int? nullableInt(String key, {int min = 0, int max = 1 << 30}) =>
      _j[key] == null ? null : integer(key, min: min, max: max);

  bool boolean(String key) {
    final v = _j[key];
    if (v is! bool) fail(key, 'a bool');
    return v;
  }

  List<Object?> list(String key) {
    final v = _j[key];
    if (v is! List<Object?>) fail(key, 'a list');
    return v;
  }

  List<int> ints(String key, {int min = 0, int max = 1 << 30}) => [
        for (final v in list(key))
          if (v is int && v >= min && v <= max)
            v
          else
            fail(key, 'a list of ints in $min..$max'),
      ];

  T byName<T extends Enum>(String key, List<T> values) {
    final v = _j[key];
    for (final e in values) {
      if (e.name == v) return e;
    }
    fail(key, 'one of ${values.map((e) => e.name).join(', ')}');
  }

  T? nullableByName<T extends Enum>(String key, List<T> values) =>
      _j[key] == null ? null : byName(key, values);

  Side side(String key) => byName(key, Side.values);
  Side? nullableSide(String key) => nullableByName(key, Side.values);
}
