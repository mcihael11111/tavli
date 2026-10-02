/// Element-wise collection equality (internal; not exported).
library;

/// Whether [a] and [b] have equal elements in the same order.
bool listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Whether [a] and [b] hold equal values under the same keys.
bool mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

/// An order-independent hash of [m], consistent with [mapEq].
int mapHash<K, V>(Map<K, V> m) => Object.hashAllUnordered(
    [for (final e in m.entries) Object.hash(e.key, e.value)]);
