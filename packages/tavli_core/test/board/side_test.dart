import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void main() {
  test('G1 Side.opponent swaps the two sides', () {
    expect(Side.one.opponent, Side.two);
    expect(Side.two.opponent, Side.one);
  });

  test('G1 there are exactly two sides', () {
    expect(Side.values.length, 2);
  });

  test('Side JSON round-trips', () {
    expect(Side.fromJson('one'), Side.one);
    for (final s in Side.values) {
      expect(Side.fromJson(s.toJson()), s);
    }
  });

  test('Side.fromJson rejects unknown names', () {
    expect(() => Side.fromJson('three'), throwsArgumentError);
  });
}
