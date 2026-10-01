# SP0 Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the scaffolding every later sub-project stands on:
- a Dart pub workspace with pure-Dart `tavli_core` / `tavli_bot` packages;
- a shared test kit (benchmark + import-lint helpers);
- architecture boundary tests;
- a legacy performance baseline;
- an on-device profile harness;
- a CI that is green on Flutter 3.41 and runs exactly what developers run locally.

**Architecture:**
- The Flutter app at `tavli/` becomes the root of a Dart pub workspace (Dart ≥ 3.6), with three members under `tavli/packages/`.
- `tavli_testkit` is a dev-only helper package used by every member and the app.
- One script, `tool/ci/check.sh`, is the single definition of "green". CI invokes it, and developers run it locally.

**Tech Stack:** Dart 3.11 / Flutter 3.41.5, pub workspaces, `package:test`, `flutter_test`, `integration_test` + `flutter_driver` (timeline summaries), GitHub Actions, bash.

**Spec:** `docs/superpowers/specs/2026-10-01-gameplay-rewrite-program-design.md` §5, §6 (SP0 row), §7.

**Conventions for every task:**
- **Working directory:** `/Users/michaelpapanikolaou/Documents/1_programs/Tavli/tavli` (abbreviated `$APP`).
- **Flutter binary:** `/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin` is not on PATH. Prefix every command with `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" &&`.
- **Branch:** `rewrite/gameplay` (already checked out).
- **Commit trailer:** every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Formatting:** run `dart format <each new or changed new-code file>` before every commit. New code must pass `dart format --set-exit-if-changed`. Legacy code is not reformatted in SP0; it is deleted by later sub-projects.

---

## File Structure

| Path | Responsibility |
|---|---|
| `pubspec.yaml` (modify) | Workspace root: SDK ≥ 3.6, `workspace:` member list, dev deps on `tavli_testkit` and `flutter_driver` |
| `dart_test.yaml` (create) | Tag config: `legacy-bench` skipped unless run explicitly |
| `packages/tavli_testkit/` | `bench.dart` (BenchStats, measure, budget scaling), `import_lint.dart` (forbidden-import scanner) + their tests |
| `packages/tavli_core/` | Empty-but-real core package: schema version constant, strict analysis options, no-Flutter import-lint test |
| `packages/tavli_bot/` | Empty-but-real bot package depending on core; import-lint test |
| `test/architecture/gameplay_boundaries_test.dart` | `lib/gameplay/**` must not import legacy gameplay code |
| `test/bench/legacy_engine_bench_test.dart` | Baseline numbers for the legacy engine/AI → `build/bench/legacy_baseline.json` |
| `integration_test/perf/legacy_game_perf_test.dart` | On-device scripted legacy game under `traceAction` |
| `test_driver/perf_driver.dart` | Writes timeline summaries to `build/perf/` |
| `tool/ci/check.sh` | The single "green" definition (analyze, format new code, all tests) |
| `tool/device/check_device.sh`, `tool/device/profile_run.sh` | Device detection + profile-mode drive runs |
| `tool/doctor.sh` | Toolchain/disk checklist (SP0 prerequisites from spec §7) |
| `.github/workflows/ci.yml` (modify) | Flutter 3.41.x, runs `tool/ci/check.sh` on pushes/PRs to `main` and `rewrite/**` |
| `lib/features/dualboard/data/ble_board_impl.dart` (modify) | Silence 3 analyzer warnings on a stub slated for SP5 rewrite |
| `docs/superpowers/perf/2026-10-01-legacy-baseline.md` (create) | Committed baseline report (desktop now, device section filled when phone connected) |

---

### Task 1: Make `dart analyze --fatal-infos` clean

**Files:**
- Modify: `lib/features/dualboard/data/ble_board_impl.dart:28,40,262`

- [ ] **Step 1: Confirm the failure**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && dart analyze --fatal-infos`
Expected: `3 issues found.`:
- `unused_field` × 2: `_connectedDeviceId`, `_localCalibration`
- `unused_element` × 1: `_onDataReceived`

- [ ] **Step 2: Add targeted ignores**

This file is a BLE stub. It is rewritten in SP5, where dual-board moves onto `MatchTransport`, so the members are kept, not deleted. Edit the three declarations so they read exactly:

```dart
  // ignore: unused_field — consumed by the SP5 BLE transport rewrite.
  String? _connectedDeviceId;
```

```dart
  // ignore: unused_field — consumed by the SP5 BLE transport rewrite.
  ScreenCalibration? _localCalibration;
```

```dart
  /// Called when data is received from the BLE characteristic.
  // ignore: unused_element — wired to the platform BLE plugin in SP5.
  void _onDataReceived(List<int> data) {
```

- [ ] **Step 3: Verify clean**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && dart analyze --fatal-infos`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/dualboard/data/ble_board_impl.dart
git commit -m "Silence analyzer warnings in BLE stub pending SP5 rewrite

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Workspace root + `tavli_testkit` package (bench helpers)

**Files:**
- Modify: `pubspec.yaml` (environment + workspace + dev_dependencies)
- Create: `packages/tavli_testkit/pubspec.yaml`
- Create: `packages/tavli_testkit/analysis_options.yaml`
- Create: `packages/tavli_testkit/lib/tavli_testkit.dart`
- Create: `packages/tavli_testkit/lib/src/bench.dart`
- Test: `packages/tavli_testkit/test/bench_test.dart`

- [ ] **Step 1: Create the package manifest and analysis options**

`packages/tavli_testkit/pubspec.yaml`:

```yaml
name: tavli_testkit
description: Dev-only test helpers (benchmarks, import lint) shared across the Tavli workspace.
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: '>=3.6.0 <4.0.0'

dev_dependencies:
  lints: '>=3.0.0 <7.0.0'
  test: ^1.25.0
```

`packages/tavli_testkit/analysis_options.yaml` (the same content is reused verbatim by `tavli_core` and `tavli_bot`):

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_single_quotes
    - avoid_print
    - unawaited_futures
    - always_declare_return_types
```

- [ ] **Step 2: Turn the app into the workspace root**

In `pubspec.yaml`, replace:

```yaml
environment:
  sdk: '>=3.2.0 <4.0.0'
```

with:

```yaml
environment:
  sdk: '>=3.6.0 <4.0.0'

workspace:
  - packages/tavli_testkit
```

In the `dev_dependencies:` block, add after `flutter_lints: ^3.0.0`:

```yaml
  flutter_driver:
    sdk: flutter
  tavli_testkit:
    path: packages/tavli_testkit
```

- [ ] **Step 2b: Remove unused code-generation and dead dependencies (resolution blocker)**

Flutter 3.41.5's `flutter_test` pins `test_api 0.7.10`. Every compatible `package:test` needs `analyzer >= 8`, but the legacy code-gen dev dependencies require an older analyzer, so the workspace cannot resolve.

Verified on 2026-10-01 that **none of these are used**: zero `part '*.g.dart'`/`*.freezed.dart` files, zero code-gen annotations, and zero imports anywhere in `lib/` or `test/`.

In `pubspec.yaml`:
- Delete from `dependencies:` the lines (and their comment headers if left empty) for:
  - `riverpod_annotation`
  - `hive`, `hive_flutter`
  - `drift`, `sqlite3_flutter_libs`
  - `dio`
  - `freezed_annotation`, `json_annotation`
- Delete from `dev_dependencies:`:
  - `build_runner`, `freezed`, `json_serializable`
  - `riverpod_generator`, `drift_dev`, `hive_generator`

Re-run the grep below to prove zero usage before deleting. It must print nothing:

`grep -rlE "package:(hive|hive_flutter|drift|sqlite3_flutter_libs|dio|freezed_annotation|json_annotation|riverpod_annotation)/" lib test integration_test`

List the removed packages in the Task 2 commit body.

- [ ] **Step 3: Resolve and confirm the app still analyzes and tests**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter pub get && dart analyze --fatal-infos`
Expected:
- `pub get` succeeds.
- A single `pubspec.lock` and `.dart_tool/` exist at `$APP`; none under `packages/tavli_testkit/`.
- `No issues found!`

If raising the language version to 3.6 surfaces new lints in legacy code, fix them minimally in the same commit and list each change in the commit body.

- [ ] **Step 4: Write the failing test**

`packages/tavli_testkit/test/bench_test.dart`:

```dart
import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  group('measure', () {
    test('collects the requested number of samples', () {
      var calls = 0;
      final stats = measure(() => calls++, warmup: 5, samples: 50);
      expect(stats.samples, 50);
      expect(calls, 55);
    });

    test('percentiles are ordered p50 <= p95 <= max', () {
      final stats = measure(() {
        var x = 0;
        for (var i = 0; i < 1000; i++) {
          x += i;
        }
        if (x < 0) throw StateError('unreachable');
      }, samples: 100);
      expect(stats.p50 <= stats.p95, isTrue);
      expect(stats.p95 <= stats.max, isTrue);
    });
  });

  group('BenchStats.fromMicros', () {
    test('computes nearest-rank percentiles', () {
      final stats = BenchStats.fromMicros(
        'x',
        List<int>.generate(100, (i) => i + 1), // 1..100 us
      );
      expect(stats.p50, const Duration(microseconds: 50));
      expect(stats.p95, const Duration(microseconds: 95));
      expect(stats.max, const Duration(microseconds: 100));
      expect(stats.mean, const Duration(microseconds: 50)); // 50.5 truncated
    });

    test('rejects empty input', () {
      expect(() => BenchStats.fromMicros('x', const []), throwsArgumentError);
    });
  });

  group('budget', () {
    final stats = BenchStats.fromMicros('gen', List<int>.filled(10, 1500));

    test('within budget at scale 1', () {
      expect(stats.withinBudget(const Duration(milliseconds: 2), scale: 1),
          isTrue);
    });

    test('over budget at scale 1', () {
      expect(stats.withinBudget(const Duration(milliseconds: 1), scale: 1),
          isFalse);
    });

    test('scale relaxes the budget (slow CI runners)', () {
      expect(stats.withinBudget(const Duration(milliseconds: 1), scale: 2),
          isTrue);
    });

    test('benchScale defaults to 1.0 for a missing/invalid env value', () {
      expect(benchScale(const {}), 1.0);
      expect(benchScale(const {'TAVLI_BENCH_SCALE': 'abc'}), 1.0);
      expect(benchScale(const {'TAVLI_BENCH_SCALE': '2.5'}), 2.5);
    });
  });

  test('toJson exposes microsecond fields', () {
    final json = BenchStats.fromMicros('gen', const [10, 20, 30]).toJson();
    expect(json['name'], 'gen');
    expect(json['samples'], 3);
    expect(json['p50_us'], 20);
    expect(json['p95_us'], 30);
    expect(json['max_us'], 30);
    expect(json['mean_us'], 20);
  });
}
```

`packages/tavli_testkit/lib/tavli_testkit.dart`:

```dart
/// Dev-only helpers shared by every package in the Tavli workspace.
library;

export 'src/bench.dart';
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_testkit && dart test`
Expected: FAIL with a compilation error (`src/bench.dart` not found).

- [ ] **Step 6: Implement**

`packages/tavli_testkit/lib/src/bench.dart`:

```dart
import 'dart:io' show Platform;

/// Summary statistics for a micro-benchmark.
class BenchStats {
  final String name;
  final int samples;
  final Duration p50;
  final Duration p95;
  final Duration max;
  final Duration mean;

  const BenchStats({
    required this.name,
    required this.samples,
    required this.p50,
    required this.p95,
    required this.max,
    required this.mean,
  });

  /// Builds stats from raw microsecond samples using nearest-rank percentiles.
  factory BenchStats.fromMicros(String name, List<int> micros) {
    if (micros.isEmpty) {
      throw ArgumentError.value(micros, 'micros', 'must not be empty');
    }
    final sorted = List<int>.of(micros)..sort();
    int rank(double p) => sorted[((p * sorted.length).ceil() - 1)
        .clamp(0, sorted.length - 1)];
    final total = sorted.fold<int>(0, (a, b) => a + b);
    return BenchStats(
      name: name,
      samples: sorted.length,
      p50: Duration(microseconds: rank(0.50)),
      p95: Duration(microseconds: rank(0.95)),
      max: Duration(microseconds: sorted.last),
      mean: Duration(microseconds: total ~/ sorted.length),
    );
  }

  /// True when p95 is within [budget] multiplied by [scale].
  ///
  /// [scale] defaults to [benchScale] so slow CI runners can relax budgets
  /// via the `TAVLI_BENCH_SCALE` environment variable without code changes.
  bool withinBudget(Duration budget, {double? scale}) {
    final s = scale ?? benchScale();
    return p95.inMicroseconds <= budget.inMicroseconds * s;
  }

  Map<String, Object> toJson() => {
        'name': name,
        'samples': samples,
        'p50_us': p50.inMicroseconds,
        'p95_us': p95.inMicroseconds,
        'max_us': max.inMicroseconds,
        'mean_us': mean.inMicroseconds,
      };

  @override
  String toString() => '$name: n=$samples p50=${p50.inMicroseconds}us '
      'p95=${p95.inMicroseconds}us max=${max.inMicroseconds}us';
}

/// Runs [body] [warmup] times untimed, then [samples] times timed.
BenchStats measure(
  void Function() body, {
  String name = 'bench',
  int warmup = 20,
  int samples = 200,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final micros = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < samples; i++) {
    sw
      ..reset()
      ..start();
    body();
    sw.stop();
    micros.add(sw.elapsedMicroseconds);
  }
  return BenchStats.fromMicros(name, micros);
}

/// Budget multiplier from `TAVLI_BENCH_SCALE` (default 1.0).
double benchScale([Map<String, String>? env]) {
  final raw = (env ?? Platform.environment)['TAVLI_BENCH_SCALE'];
  final parsed = raw == null ? null : double.tryParse(raw);
  return (parsed == null || parsed <= 0) ? 1.0 : parsed;
}
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_testkit && dart test && dart format --output=none --set-exit-if-changed .`
Expected: `All tests passed!` and no formatting changes.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/tavli_testkit
git commit -m "Add pub workspace root and tavli_testkit bench helpers

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Import-lint helper in `tavli_testkit`

**Files:**
- Create: `packages/tavli_testkit/lib/src/import_lint.dart`
- Modify: `packages/tavli_testkit/lib/tavli_testkit.dart`
- Test: `packages/tavli_testkit/test/import_lint_test.dart`

- [ ] **Step 1: Write the failing test**

`packages/tavli_testkit/test/import_lint_test.dart`:

```dart
import 'dart:io';

import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('import_lint_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void write(String rel, String content) {
    File('${tmp.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('reports forbidden imports and exports with file and line', () {
    write('lib/a.dart', "import 'dart:math';\nimport 'package:flutter/material.dart';\n");
    write('lib/src/b.dart', "export 'package:flutter/foundation.dart';\n");

    final violations = findForbiddenImports(
      Directory('${tmp.path}/lib'),
      [RegExp(r'^package:flutter/')],
    );

    expect(violations, hasLength(2));
    final a = violations.singleWhere((v) => v.file.endsWith('a.dart'));
    expect(a.line, 2);
    expect(a.uri, 'package:flutter/material.dart');
    expect(violations.any((v) => v.file.endsWith('b.dart')), isTrue);
  });

  test('handles double quotes and ignores non-dart files and comments', () {
    write('lib/a.dart', '// import \'package:flutter/x.dart\';\nimport "dart:ui";\n');
    write('lib/readme.md', "import 'package:flutter/material.dart';\n");

    final violations = findForbiddenImports(
      Directory('${tmp.path}/lib'),
      [RegExp(r'^package:flutter/'), 'dart:ui'],
    );

    expect(violations, hasLength(1));
    expect(violations.single.uri, 'dart:ui');
  });

  test('missing directory yields no violations', () {
    expect(
      findForbiddenImports(Directory('${tmp.path}/nope'), ['dart:ui']),
      isEmpty,
    );
  });

  test('toString is human readable for test failure messages', () {
    const v = ImportViolation(file: 'lib/a.dart', line: 3, uri: 'dart:ui');
    expect(v.toString(), 'lib/a.dart:3 imports dart:ui');
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_testkit && dart test test/import_lint_test.dart`
Expected: FAIL (`findForbiddenImports` undefined).

- [ ] **Step 3: Implement**

`packages/tavli_testkit/lib/src/import_lint.dart`:

```dart
import 'dart:io';

/// One forbidden `import`/`export` directive found in a Dart source file.
class ImportViolation {
  final String file;
  final int line;
  final String uri;

  const ImportViolation({
    required this.file,
    required this.line,
    required this.uri,
  });

  @override
  String toString() => '$file:$line imports $uri';
}

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

/// Scans every `.dart` file under [root] for import/export URIs matching any
/// of [forbidden] (a `String` matches exactly or as a prefix; a `RegExp`
/// matches via `hasMatch`). Commented-out lines are ignored.
List<ImportViolation> findForbiddenImports(
  Directory root,
  List<Pattern> forbidden,
) {
  if (!root.existsSync()) return const [];
  final violations = <ImportViolation>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = _directive.firstMatch(lines[i]);
      if (match == null) continue;
      final uri = match.group(1)!;
      if (forbidden.any((p) => _matches(p, uri))) {
        violations.add(ImportViolation(file: file.path, line: i + 1, uri: uri));
      }
    }
  }
  return violations;
}

bool _matches(Pattern pattern, String uri) => switch (pattern) {
      final RegExp r => r.hasMatch(uri),
      final String s => uri == s || uri.startsWith(s),
      _ => pattern.allMatches(uri).isNotEmpty,
    };
```

In `packages/tavli_testkit/lib/tavli_testkit.dart`, add the export so the file reads:

```dart
/// Dev-only helpers shared by every package in the Tavli workspace.
library;

export 'src/bench.dart';
export 'src/import_lint.dart';
```

- [ ] **Step 4: Verify**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_testkit && dart test && dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos`
Expected: all pass, `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add packages/tavli_testkit
git commit -m "Add forbidden-import scanner to tavli_testkit

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `tavli_core` package skeleton with purity guard

**Files:**
- Create: `packages/tavli_core/pubspec.yaml`
- Create: `packages/tavli_core/analysis_options.yaml`
- Create: `packages/tavli_core/lib/tavli_core.dart`
- Test: `packages/tavli_core/test/purity_test.dart`
- Modify: `pubspec.yaml` (workspace list + app dependency)

- [ ] **Step 1: Create manifest and analysis options**

`packages/tavli_core/pubspec.yaml`:

```yaml
name: tavli_core
description: Pure-Dart Tavli rules engine and game model shared by the app and server.
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: '>=3.6.0 <4.0.0'

dev_dependencies:
  lints: '>=3.0.0 <7.0.0'
  tavli_testkit:
    path: ../tavli_testkit
  test: ^1.25.0
```

`packages/tavli_core/analysis_options.yaml`: copy `packages/tavli_testkit/analysis_options.yaml` verbatim (content shown in Task 2 Step 1).

In the root `pubspec.yaml`:
- Extend `workspace:` to:

  ```yaml
  workspace:
    - packages/tavli_testkit
    - packages/tavli_core
  ```

- Under `dependencies:`, add after `flutter_localizations:`'s `sdk: flutter` line:

  ```yaml
    tavli_core:
      path: packages/tavli_core
  ```

- [ ] **Step 2: Write the failing purity test**

`packages/tavli_core/test/purity_test.dart`:

```dart
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
```

- [ ] **Step 3: Run to verify it fails**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter pub get && cd packages/tavli_core && dart test`
Expected: FAIL (`lib/tavli_core.dart` missing / `tavliCoreSchemaVersion` undefined).

- [ ] **Step 4: Implement**

`packages/tavli_core/lib/tavli_core.dart`:

```dart
/// Tavli rules engine and game model.
///
/// Pure Dart: no Flutter, no I/O, no randomness. Shared verbatim by the
/// mobile app and the Cloud Run game server so both always agree on rules.
library;

/// Version of the serialized state / action-log format.
///
/// Bump when the wire format changes; readers must reject unknown versions.
const int tavliCoreSchemaVersion = 1;
```

- [ ] **Step 5: Verify**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_core && dart test && dart format --output=none --set-exit-if-changed . && cd ../.. && dart analyze --fatal-infos`
Expected: tests pass; `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/tavli_core
git commit -m "Add tavli_core package skeleton with purity guard

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: `tavli_bot` package skeleton with purity guard

**Files:**
- Create: `packages/tavli_bot/pubspec.yaml`
- Create: `packages/tavli_bot/analysis_options.yaml`
- Create: `packages/tavli_bot/lib/tavli_bot.dart`
- Test: `packages/tavli_bot/test/purity_test.dart`
- Modify: `pubspec.yaml` (workspace list + app dependency)

- [ ] **Step 1: Create manifest and analysis options**

`packages/tavli_bot/pubspec.yaml`:

```yaml
name: tavli_bot
description: Pure-Dart Tavli bot (evaluation + search). Runs in a worker isolate in the app and in-process on the server.
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  tavli_core:
    path: ../tavli_core

dev_dependencies:
  lints: '>=3.0.0 <7.0.0'
  tavli_testkit:
    path: ../tavli_testkit
  test: ^1.25.0
```

`packages/tavli_bot/analysis_options.yaml`: copy `packages/tavli_testkit/analysis_options.yaml` verbatim.

Root `pubspec.yaml`:
- Extend `workspace:` with `  - packages/tavli_bot`.
- Under `dependencies:`, add after the `tavli_core` entry:

  ```yaml
    tavli_bot:
      path: packages/tavli_bot
  ```

- [ ] **Step 2: Write the failing purity test**

`packages/tavli_bot/test/purity_test.dart`:

```dart
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
```

- [ ] **Step 3: Run to verify it fails**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter pub get && cd packages/tavli_bot && dart test`
Expected: FAIL (`tavliBotCoreSchemaVersion` undefined).

- [ ] **Step 4: Implement**

`packages/tavli_bot/lib/tavli_bot.dart`:

```dart
/// Tavli bot: position evaluation and time-budgeted search.
///
/// Pure Dart. In the app it runs inside a long-lived worker isolate so no
/// search ever touches the UI isolate.
library;

import 'package:tavli_core/tavli_core.dart';

/// The core schema version this bot build understands. Worker requests carrying
/// a different version are rejected rather than mis-decoded.
const int tavliBotCoreSchemaVersion = tavliCoreSchemaVersion;
```

- [ ] **Step 5: Verify**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && cd packages/tavli_bot && dart test && dart format --output=none --set-exit-if-changed . && cd ../.. && dart analyze --fatal-infos`
Expected: tests pass; `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/tavli_bot
git commit -m "Add tavli_bot package skeleton with purity guard

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: App architecture boundary test

New gameplay code under `lib/gameplay/` must never depend on the legacy gameplay code it replaces, so that code can be deleted per mode.

**Files:**
- Create: `test/architecture/gameplay_boundaries_test.dart`

- [ ] **Step 1: Write the test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli_testkit/tavli_testkit.dart';

/// Legacy gameplay code that the rewrite replaces. New code under
/// lib/gameplay/ must not import it, so each legacy mode can be deleted as
/// soon as its replacement ships (spec §6.1).
const _legacy = <Pattern>[
  'package:tavli/flame_game/',
  'package:tavli/features/game/domain/',
  'package:tavli/features/game/data/models/',
  'package:tavli/features/game/presentation/providers/',
  'package:tavli/features/ai/engine/',
  'package:tavli/features/ai/models/',
  'package:tavli/features/multiplayer/data/',
  'package:tavli/features/multiplayer/matchmaking/',
  'package:tavli/features/multiplayer/presentation/online_game_provider.dart',
];

List<ImportViolation> _scan(Directory gameplay, Directory lib) =>
    findForbiddenImports(
      gameplay,
      _legacy,
      packageName: 'tavli',
      libRoot: lib,
      // lib/gameplay is created in SP3; until then there is nothing to scan.
      allowMissing: true,
    );

void main() {
  test('lib/gameplay does not import legacy gameplay code', () {
    final violations = _scan(Directory('lib/gameplay'), Directory('lib'));
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('positive controls (guard against a vacuous pass)', () {
    late Directory lib;

    setUp(() {
      final tmp = Directory.systemTemp.createTempSync('boundary_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      lib = Directory('${tmp.path}/lib')..createSync();
    });

    void write(String content) => File('${lib.path}/gameplay/x.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('package: import of legacy code is caught', () {
      write("import 'package:tavli/flame_game/tavli_game.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });

    test('relative import of legacy code is caught', () {
      write("import '../flame_game/tavli_game.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });

    test('conditional import of legacy code is caught', () {
      write("import 'stub.dart' if (dart.library.io) "
          "'package:tavli/features/ai/engine/ai_player.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });
  });
}
```

- [ ] **Step 2: Run it**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter test test/architecture`
Expected: `All tests passed!` The first test passes because `lib/gameplay` does not exist yet; the second proves the guard works.

- [ ] **Step 3: Commit**

```bash
git add test/architecture
git commit -m "Add architecture test: new gameplay code must not import legacy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Legacy engine/AI baseline benchmark

**Files:**
- Create: `dart_test.yaml`
- Create: `test/bench/legacy_engine_bench_test.dart`

- [ ] **Step 1: Tag config so the slow baseline never runs by accident**

`dart_test.yaml`:

```yaml
tags:
  legacy-bench:
    skip: "Slow baseline. Run: flutter test --run-skipped --tags legacy-bench test/bench"
  legacy-slow:
    skip: "Legacy full games at medium/hard difficulty take 30+ min (the UI-thread search SP2 replaces). Run: flutter test --run-skipped --tags legacy-slow"
```

Then tag the one legacy test that never finishes. In `test/integration/game_flow_test.dart`, find the test named `two AIs can play a complete game to conclusion` and add the named argument `tags: ['legacy-slow'],` to its `test(...)` call. Also tag `AI at every difficulty can complete a game` (it plays full medium games too). Change nothing else in that file. SP2 deletes these tests along with the legacy AI.

- [ ] **Step 2: Write the benchmark**

`test/bench/legacy_engine_bench_test.dart`:

```dart
@Tags(['legacy-bench'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';
import 'package:tavli_testkit/tavli_testkit.dart';

/// Baseline numbers for the LEGACY engine and AI, recorded before the rewrite
/// so every later sub-project can show its improvement against them.
/// Reports only — no budget assertions (the legacy code cannot meet them).
void main() {
  test('legacy engine + AI baseline', () {
    const gen = MoveGenerator();
    const eng = GameEngine();
    // Seeded so the AI's tie-breaking/randomness is identical across runs.
    final ai = AiPlayer(rng: Random(7));
    // Dice seed 42 + AI seed 7 => identical positions every run.
    final rng = Random(42);

    // Positions come from a seeded (dice Random(42), AI Random(7)) easy-vs-easy
    // self-play: opening to early-middle plies, always with player 2 to move
    // (every second ply is kept). Identical across runs.
    final positions = <BoardState>[];
    var board = BoardState.initial();
    for (var ply = 0; ply < 60 && positions.length < 12; ply++) {
      final turn =
          ai.selectTurn(board, DiceRoll.random(rng), DifficultyLevel.easy);
      if (turn != null) board = eng.applyMoves(board, turn.moves);
      if (eng.isGameOver(board)) break;
      board = eng.endTurn(board);
      if (ply.isEven) positions.add(board);
    }

    final rolls = [
      for (var d1 = 1; d1 <= 6; d1++)
        for (var d2 = d1; d2 <= 6; d2++) DiceRoll(die1: d1, die2: d2),
    ];
    final doubles = rolls.where((r) => r.isDoubles).toList();

    // Index rolls fastest and positions slowest so the samples sweep the full
    // positions x rolls cross product (a shared stride would pin each roll to
    // a subset of positions). `all_rolls` therefore weights the 21 distinct
    // rolls equally (doubles count once, not 1/36).
    var i = 0;
    final results = <BenchStats>[
      // Bodies return their result so the bench sink keeps the work alive.
      measure(name: 'legacy.movegen.all_rolls', samples: 500, () {
        final p = positions[(i ~/ rolls.length) % positions.length];
        return gen.generateAllLegalTurns(p, rolls[i++ % rolls.length]);
      }),
      measure(name: 'legacy.movegen.doubles', samples: 300, () {
        final p = positions[(i ~/ doubles.length) % positions.length];
        return gen.generateAllLegalTurns(p, doubles[i++ % doubles.length]);
      }),
      measure(name: 'legacy.ai.easy.selectTurn', samples: 200, () {
        final p = positions[(i ~/ rolls.length) % positions.length];
        return ai.selectTurn(
            p, rolls[i++ % rolls.length], DifficultyLevel.easy);
      }),
      // Two samples only: each takes seconds to minutes (the core problem).
      measure(
          name: 'legacy.ai.medium.selectTurn',
          warmup: 0,
          minWarmup: Duration.zero,
          samples: 2, () {
        final p = positions[i++ % positions.length];
        return ai.selectTurn(
            p, const DiceRoll(die1: 3, die2: 1), DifficultyLevel.medium);
      }),
    ];

    final out = File('build/bench/legacy_baseline.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ')
          .convert([for (final r in results) r.toJson()]));
    for (final r in results) {
      debugPrint(r.toString());
    }
    debugPrint('Wrote ${out.path}');
    expect(results, hasLength(4));
  }, timeout: const Timeout(Duration(minutes: 9)));
}
```

- [ ] **Step 3: Confirm it is skipped by default**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter test test/bench`
Expected: the test is reported as skipped; exit code 0.

- [ ] **Step 4: Run it explicitly**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter test --run-skipped --tags legacy-bench test/bench`
Expected:
- PASS, with four stat lines printed.
- `build/bench/legacy_baseline.json` exists.
- Medium p95 is in seconds; this is expected and is the problem being fixed.

- [ ] **Step 5: Commit**

```bash
git add dart_test.yaml test/bench test/integration/game_flow_test.dart
git commit -m "Add legacy engine/AI baseline benchmark (tagged, opt-in)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: On-device profile harness

**Files:**
- Create: `test_driver/perf_driver.dart`
- Create: `integration_test/perf/legacy_game_perf_test.dart`
- Create: `tool/device/check_device.sh`
- Create: `tool/device/profile_run.sh`

- [ ] **Step 1: Driver that writes timeline summaries**

`test_driver/perf_driver.dart`:

```dart
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Host-side driver for `flutter drive --profile`. Every `traceAction`
/// reportKey from the device becomes `build/perf/<key>.timeline_summary.json`
/// (frame build/raster percentiles, missed-frame counts) plus the raw timeline.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic> ||
            !value.containsKey('traceEvents')) {
          continue;
        }
        final timeline = driver.Timeline.fromJson(value);
        final summary = driver.TimelineSummary.summarize(timeline);
        await summary.writeTimelineToFile(
          entry.key,
          destinationDirectory: 'build/perf',
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
```

- [ ] **Step 2: Scripted legacy game under trace**

`integration_test/perf/legacy_game_perf_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/app/theme.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_state.dart';
import 'package:tavli/features/game/domain/engine/variants/game_variant.dart';
import 'package:tavli/features/game/presentation/game_screen.dart';
import 'package:tavli/features/game/presentation/providers/game_provider.dart';
import 'package:tavli/shared/services/copy_service.dart';
import 'package:tavli/shared/services/settings_service.dart';

/// Baseline frame timings for the LEGACY game screen (vs Easy bot, Portes).
///
/// Player moves are applied through the provider: they bypass the Flame tap
/// path AND skip the player move animation (the board snaps), so this baseline
/// measures rebuild/render/bot cost rather than hit-testing or animation. Run on the
/// Galaxy S with: tool/device/profile_run.sh legacy_game_perf
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('legacy game: 6 player turns vs easy bot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();

    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: TavliTheme.light,
        home: const GameScreen(
          difficulty: DifficultyLevel.easy,
          variant: GameVariant.portes,
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    // GameScreen.initState overrides the orientation; re-assert the lock.
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    GameState state() => container.read(gameProvider);

    Future<void> idle(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    var playerTurns = 0;
    await binding.traceAction(() async {
      // Opening roll: wait until the button is on screen.
      final openingBtn = find.text(TavliCopy.rollButton);
      final openingDeadline = DateTime.now().add(const Duration(seconds: 5));
      while (openingBtn.evaluate().isEmpty &&
          DateTime.now().isBefore(openingDeadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(openingBtn, findsWidgets,
          reason: 'Opening "${TavliCopy.rollButton}" button never appeared');
      await tester.tap(openingBtn.first);
      await idle(1500);

      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (playerTurns < 6 &&
          state().phase != GamePhase.gameOver &&
          DateTime.now().isBefore(deadline)) {
        final s = state();
        final rollBtn = find.text(TavliCopy.roll);
        if (s.isPlayerTurn &&
            s.phase == GamePhase.playerTurnStart &&
            rollBtn.evaluate().isNotEmpty) {
          await tester.tap(rollBtn.first);
          await idle(600);
        } else if (s.isPlayerTurn &&
            s.phase == GamePhase.movingCheckers &&
            s.legalTurns.isNotEmpty) {
          final notifier = container.read(gameProvider.notifier);
          for (final move in s.legalTurns.first.moves) {
            notifier.selectChecker(move.fromPoint);
            await idle(150);
            notifier.makeMove(move.toPoint);
            await idle(250);
          }
          playerTurns++;
        } else {
          await idle(200); // bot turn / transitions
        }
      }
    }, reportKey: 'legacy_game_easy');

    expect(playerTurns, 6,
        reason: 'Script stalled (phase=${state().phase}); the timeline '
            'would not represent a full 6-turn game.');
  });
}
```

- [ ] **Step 3: Device scripts**

`tool/device/check_device.sh`:

```bash
#!/usr/bin/env bash
# Lists connected Android devices (id + model). Exits 1 when none are usable.
set -euo pipefail
if command -v adb >/dev/null 2>&1; then
  ADB="$(command -v adb)"
else
  ADB=""
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
    if [ -n "$root" ] && [ -x "$root/platform-tools/adb" ]; then
      ADB="$root/platform-tools/adb"
      break
    fi
  done
fi
if [ -z "$ADB" ]; then
  echo "adb not found. Put it on PATH or set ANDROID_HOME / ANDROID_SDK_ROOT." >&2
  exit 1
fi
devices=$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [ -z "$devices" ]; then
  if "$ADB" devices | awk 'NR>1 && $2=="unauthorized" {f=1} END{exit !f}'; then
    echo "Device is unauthorized: authorize USB debugging on the phone." >&2
  else
    echo "No Android device connected. Enable USB debugging and plug in the phone." >&2
  fi
  exit 1
fi
for d in $devices; do
  model=$("$ADB" -s "$d" shell getprop ro.product.model | tr -d '\r')
  echo "$d $model"
done
```

`tool/device/profile_run.sh`:

```bash
#!/usr/bin/env bash
# Runs integration_test/perf/<scenario>_test.dart in PROFILE mode on a device
# and writes build/perf/<reportKey>.timeline_summary.json.
# Usage: tool/device/profile_run.sh <scenario> [device-id]
set -euo pipefail
cd "$(dirname "$0")/../.."
scenario="${1:?usage: profile_run.sh <scenario> [device-id]}"
if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH." >&2
  exit 1
fi
devices_out=$(tool/device/check_device.sh)
device="${2:-$(printf '%s\n' "$devices_out" | awk 'NR==1{print $1}')}"
echo "Using device: $(printf '%s\n' "$devices_out" | awk -v d="$device" '$1==d{print}')"
rm -rf build/perf
# --no-dds: traceAction needs a direct VM-service connection (DDS blocks it).
# --endless-trace-buffer: keep the start of a ~30 s trace.
flutter drive --profile --no-dds --endless-trace-buffer \
  --driver=test_driver/perf_driver.dart \
  --target="integration_test/perf/${scenario}_test.dart" \
  -d "$device"
echo "Summaries:"
ls -1 build/perf/*.timeline_summary.json
```

Run: `chmod +x tool/device/check_device.sh tool/device/profile_run.sh`

- [ ] **Step 4: Verify everything compiles (device run happens in Task 11)**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && dart analyze --fatal-infos && bash -n tool/device/check_device.sh && bash -n tool/device/profile_run.sh`
Expected: `No issues found!`; `bash -n` prints nothing.

- [ ] **Step 5: Commit**

```bash
git add test_driver integration_test/perf tool/device
git commit -m "Add on-device profile harness (flutter drive --profile + timeline summaries)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Single CI definition + GitHub Actions on 3.41

**Files:**
- Create: `tool/ci/check.sh`
- Modify: `.github/workflows/ci.yml` (full replacement)

- [ ] **Step 1: The single "green" script**

`tool/ci/check.sh`:

```bash
#!/usr/bin/env bash
# The one definition of "green". CI runs exactly this; so should you before
# every commit that claims to pass.
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "== pub get"
flutter pub get

echo "== analyze (whole workspace)"
dart analyze --fatal-infos

echo "== format (new code only — legacy code is deleted, not reformatted)"
fmt_paths=()
for p in packages lib/gameplay server test/architecture test/bench \
         integration_test/perf test_driver; do
  [ -e "$p" ] && fmt_paths+=("$p")
done
dart format --output=none --set-exit-if-changed "${fmt_paths[@]}"

echo "== package tests"
for pkg in packages/*/; do
  (cd "$pkg" && dart test --reporter=compact)
done

echo "== app tests"
flutter test --reporter=compact

echo "ALL GREEN"
```

Run: `chmod +x tool/ci/check.sh`

- [ ] **Step 2: Run it locally**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && tool/ci/check.sh`
Expected: ends with `ALL GREEN`. App tests include `test/unit`, `test/widget`, `test/integration`, `test/architecture` and `test/widget_test.dart`; `test/bench` reports skipped. If a legacy test in `test/integration` fails, record its name and failure, fix only if it is a test-environment issue, and otherwise stop and report. Do not weaken the test.

- [ ] **Step 3: Replace the workflow**

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, 'rewrite/**']
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
          channel: stable
          cache: true

      - name: Check (analyze, format, all tests)
        env:
          TAVLI_BENCH_SCALE: '3'
        run: tool/ci/check.sh
```

The git repository root *is* the app directory (`git rev-parse --show-toplevel` → `.../Tavli/tavli`), so no `working-directory` is needed.

The old `build-android` job is dropped: `google-services.json` is gitignored, so CI Android builds cannot succeed without secrets. Release builds return in SP5 with secrets-based signing.

- [ ] **Step 4: Validate YAML**

Run: `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "ok"'`
Expected: `ok`

- [ ] **Step 5: Commit**

```bash
git add tool/ci .github/workflows/ci.yml
git commit -m "Single CI definition (tool/ci/check.sh); CI on Flutter 3.41.5

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Toolchain doctor

**Files:**
- Create: `tool/doctor.sh`

- [ ] **Step 1: Write the script**

`tool/doctor.sh`:

```bash
#!/usr/bin/env bash
# Checks the machine is ready for the gameplay rewrite (spec §7 prerequisites).
# Prints a checklist; exits non-zero if any REQUIRED item fails.
set -uo pipefail
fail=0
ok()   { printf '  \xE2\x9C\x93 %s\n' "$1"; }
bad()  { printf '  \xE2\x9C\x97 %s\n' "$1"; [ "${2:-req}" = req ] && fail=1; }

echo "Required"
free_gb=$(df -g / | awk 'NR==2 {print $4}')
if [ "${free_gb:-0}" -ge 15 ]; then ok "disk free ${free_gb} GB (>= 15)"; else bad "disk free ${free_gb} GB — need >= 15 GB for Android builds"; fi
if command -v flutter >/dev/null; then
  v=$(flutter --version 2>/dev/null | head -1)
  case "$v" in *"3.41."*) ok "$v";; *) bad "Flutter 3.41.x required, found: $v";; esac
else bad "flutter not on PATH"; fi
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
if [ -x "$ADB" ]; then ok "adb at $ADB"; else bad "adb not found"; fi

echo "Needed for device verification"
if "$(dirname "$0")/device/check_device.sh" >/dev/null 2>&1; then
  ok "device: $("$(dirname "$0")/device/check_device.sh" | head -1)"
else bad "no Android device connected (USB debugging)" opt; fi

echo "Needed from SP4 (online)"
if command -v firebase >/dev/null; then ok "firebase CLI $(firebase --version)"; else bad "firebase CLI missing — npm i -g firebase-tools" opt; fi
if command -v gcloud >/dev/null; then ok "gcloud $(gcloud --version 2>/dev/null | head -1)"; else bad "gcloud missing — https://cloud.google.com/sdk/docs/install" opt; fi
if /usr/libexec/java_home >/dev/null 2>&1; then ok "java $(/usr/libexec/java_home)"; else bad "JDK missing (Firebase emulators need Java 11+)" opt; fi

echo "Optional"
if command -v xcodebuild >/dev/null && xcodebuild -version >/dev/null 2>&1; then ok "Xcode"; else bad "Xcode not installed — iOS verification deferred" opt; fi

exit $fail
```

Run: `chmod +x tool/doctor.sh`

- [ ] **Step 2: Run it**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && tool/doctor.sh; echo "exit=$?"`
Expected: the checklist prints. With today's machine (≈ 1.9 GB free) the disk line shows ✗ and `exit=1`; that is the correct report, not a script bug.

- [ ] **Step 3: Commit**

```bash
git add tool/doctor.sh
git commit -m "Add tool/doctor.sh toolchain + disk readiness checklist

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Baseline report

**Files:**
- Create: `docs/superpowers/perf/2026-10-01-legacy-baseline.md`

- [ ] **Step 1: Generate desktop numbers**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && flutter test --run-skipped --tags legacy-bench test/bench && cat build/bench/legacy_baseline.json`

- [ ] **Step 2: Attempt the device run**

Run: `tool/device/check_device.sh`
- If a device is listed (and `tool/doctor.sh` shows ≥ 15 GB free), run `export PATH=...flutter/bin:$PATH && tool/device/profile_run.sh legacy_game_perf` and read `build/perf/legacy_game_easy.timeline_summary.json`.
- If no device is connected or disk is insufficient, skip and mark the device section **PENDING**.

- [ ] **Step 3: Write the report**

`docs/superpowers/perf/2026-10-01-legacy-baseline.md`, using real values from the JSON files. Never invent numbers; write `PENDING (reason)` where a value was not measured.

```markdown
# Legacy Baseline — 2026-10-01

Reference numbers for the pre-rewrite app. Every later sub-project reports
against these. Source: `flutter test --run-skipped --tags legacy-bench test/bench`
(desktop, Dart VM JIT) and `tool/device/profile_run.sh legacy_game_perf` (device, profile).

## Desktop (Mac, Dart VM JIT)

| Benchmark | p50 | p95 | max | samples |
|---|---|---|---|---|
| legacy.movegen.all_rolls | … | … | … | … |
| legacy.movegen.doubles | … | … | … | … |
| legacy.ai.easy.selectTurn | … | … | … | … |
| legacy.ai.medium.selectTurn | … | … | … | … |

## Device (Galaxy S, profile) — legacy_game_easy

| Metric | Value |
|---|---|
| average_frame_build_time_millis | … |
| 90th_percentile_frame_build_time_millis | … |
| 99th_percentile_frame_build_time_millis | … |
| average_frame_rasterizer_time_millis | … |
| 99th_percentile_frame_rasterizer_time_millis | … |
| missed_frame_build_budget_count | … |
| missed_frame_rasterizer_budget_count | … |
| frame_count | … |

## Targets (spec §3.3)
Medium bot ≤ 80 ms p95 (off UI isolate), legal-play generation ≤ 2 ms p95,
≥ 99 % frames within budget on the Galaxy S.
```

- [ ] **Step 4: Run the full gate once more**

Run: `export PATH="/Users/michaelpapanikolaou/Documents/1_programs/flutter/bin:$PATH" && tool/ci/check.sh`
Expected: `ALL GREEN`

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/perf
git commit -m "Record legacy performance baseline

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## SP0 exit checklist (spec §6)

- [x] Workspace with `tavli_testkit`, `tavli_core`, `tavli_bot` resolves; purity guards pass.
- [x] `tool/ci/check.sh` prints `ALL GREEN` locally.
- [x] CI workflow on Flutter 3.41.5 runs `tool/ci/check.sh` (written + validated). **OPEN GATE (a):** Remote CI goes green once the branch is pushed; **pushing requires user approval**.
- [x] Legacy desktop baseline recorded.
- [ ] **OPEN GATE (b) — must close before SP3:** Galaxy S device baseline recorded, or explicitly PENDING on device connection and ≥ 15 GB free disk (user actions).
