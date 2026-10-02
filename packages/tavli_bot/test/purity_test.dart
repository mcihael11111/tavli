import 'dart:io';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

/// Allowlist, not blocklist: tavli_bot is pure (no I/O, no Flutter, no
/// serialization). Beyond the core SDK libraries it may use dart:isolate, because the bot hosts its
/// own worker isolate, plus its own package and tavli_core. Anything else
/// matches and is reported.
final _notAllowed = RegExp(
  r'^(?!(dart:(core|async|collection|math|typed_data|isolate)$)'
  r'|package:tavli_bot/|package:tavli_core/)',
);

void main() {
  test('tavli_bot imports only allowlisted pure-Dart libraries', () {
    final lib = packageLibDir('tavli_bot');
    final violations = findForbiddenImports(
      lib,
      [_notAllowed],
      packageName: 'tavli_bot',
      libRoot: lib,
    );
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('allowlist does not flag relative imports inside the package', () {
    final tmp = Directory.systemTemp.createTempSync('purity_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final lib = Directory('${tmp.path}/lib')..createSync();
    File('${lib.path}/src/x.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    File('${lib.path}/a.dart').writeAsStringSync("export 'src/x.dart';\n");
    final violations = findForbiddenImports(
      lib,
      [_notAllowed],
      packageName: 'tavli_bot',
      libRoot: lib,
    );
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('allowlist regex flags disallowed imports and permits allowed ones', () {
    for (final bad in [
      'dart:io',
      'dart:convert',
      'package:flutter/material.dart',
      'package:flame/flame.dart',
    ]) {
      expect(_notAllowed.hasMatch(bad), isTrue, reason: bad);
    }
    for (final ok in [
      'dart:math',
      'dart:isolate',
      'package:tavli_bot/src/x.dart',
      'package:tavli_core/tavli_core.dart',
    ]) {
      expect(_notAllowed.hasMatch(ok), isFalse, reason: ok);
    }
  });

  test('declares the core schema version it was built against', () {
    expect(tavliBotCoreSchemaVersion, 1);
  });
}
