import 'dart:io';

import 'package:tavli_core/tavli_core.dart';
import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('tavli_core never imports Flutter, dart:ui, or other workspace packages',
      () {
    final violations = findForbiddenImports(
      Directory('lib'),
      [
        RegExp(r'^package:flutter'),
        'dart:ui',
        'package:tavli_bot/',
        'package:tavli/',
      ],
      packageName: 'tavli_core',
      libRoot: Directory('lib'),
    );
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('exposes a serialization schema version', () {
    expect(tavliCoreSchemaVersion, 1);
  });
}
