/// Element-wise list equality (internal; not exported).
library;

/// Whether [a] and [b] have equal elements in the same order.
bool listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
