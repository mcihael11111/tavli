import 'dart:io';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('tavli_bot never imports Flutter, dart:ui, or the app', () {
    final violations = findForbiddenImports(
      Directory('lib'),
      [
        RegExp(r'^package:flutter'),
        'dart:ui',
        'package:tavli/',
      ],
      packageName: 'tavli_bot',
      libRoot: Directory('lib'),
    );
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('declares the core schema version it was built against', () {
    expect(tavliBotCoreSchemaVersion, 1);
  });
}
