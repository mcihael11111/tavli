/// Whether `assert` statements run in this test isolate (debug mode).
///
/// Tests of debug-only checks return early when this is false.
final bool assertsOn = () {
  var on = false;
  assert(on = true);
  return on;
}();
