part of 'position.dart';

final _directions = Direction.values.asNameMap();

/// See [Position.toJson] for schema v1. Every failure is a [FormatException].
Position _positionFromJson(Map<String, Object?> j) {
  final direction = _directions[j['direction']];
  if (direction == null) {
    throw FormatException('Position: bad direction', j['direction']);
  }
  final counts = Uint8List(2 * _stride);
  for (final (i, key) in const ['one', 'two'].indexed) {
    final list = j[key];
    if (list is! List<Object?> || list.length != _stride) {
      throw FormatException('Position: "$key" must be $_stride counts', list);
    }
    for (var pip = 0; pip < _stride; pip++) {
      final c = list[pip];
      if (c is! int || c < 0 || c > _checkers) {
        throw FormatException('Position: bad count in "$key"', c);
      }
      counts[i * _stride + pip] = c;
    }
  }
  final p = Position._(
    direction,
    counts,
    _jsonMask(j['pinnedOne'], 'pinnedOne'),
    _jsonMask(j['pinnedTwo'], 'pinnedTwo'),
  );
  try {
    _validateBoard(p);
  } on ArgumentError catch (e) {
    throw FormatException('Position: invalid position: ${e.message}', j);
  }
  return p;
}

int _jsonMask(Object? v, String name) {
  if (v is! List<Object?>) {
    throw FormatException('Position: "$name" must be a list of pips', v);
  }
  var mask = 0;
  for (final p in v) {
    if (p is! int || p < 1 || p > 24) {
      throw FormatException('Position: "$name" pips must be ints 1..24', p);
    }
    if ((mask >> p) & 1 == 1) {
      throw FormatException('Position: duplicate pip in "$name"', p);
    }
    mask |= 1 << p;
  }
  return mask;
}

List<int> _pipsOf(int mask) => [
      for (var p = 1; p <= 24; p++)
        if ((mask >> p) & 1 == 1) p,
    ];
