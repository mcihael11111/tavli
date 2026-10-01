import 'package:tavli_core/tavli_core.dart';
import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

/// Allowlist, not blocklist: tavli_core is pure (no I/O, no Flutter, no other
/// packages), so only these SDK libraries and its own package may be imported.
/// Anything else matches and is reported.
final _notAllowed = RegExp(
  r'^(?!(dart:(core|async|collection|convert|math|typed_data)$)|package:tavli_core/)',
);

void main() {
  test('tavli_core imports only allowlisted pure-Dart libraries', () {
    final lib = packageLibDir('tavli_core');
    final violations = findForbiddenImports(
      lib,
      [_notAllowed],
      packageName: 'tavli_core',
      libRoot: lib,
    );
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('allowlist regex flags disallowed imports and permits allowed ones', () {
    for (final bad in [
      'dart:io',
      'package:flutter/material.dart',
      'package:flame/flame.dart',
    ]) {
      expect(_notAllowed.hasMatch(bad), isTrue, reason: bad);
    }
    for (final ok in ['dart:math', 'package:tavli_core/src/x.dart']) {
      expect(_notAllowed.hasMatch(ok), isFalse, reason: ok);
    }
  });

  test('exposes a serialization schema version', () {
    expect(tavliCoreSchemaVersion, 1);
  });
}
