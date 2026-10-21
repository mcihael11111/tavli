/// Builds the SP3 game assets (design §5.5) into `assets/images/game/`:
///
/// - `board_set{1,2,3}.webp`: the baked-bear-off boards, 1200 px wide;
/// - `table.webp`: the table background, 1600 × 1000;
/// - `checkers.{webp,json}`: one checker atlas (light/dark × normal,
///   selected, shadow, vertical), discs at 192 px, for every board set;
/// - `dice.{webp,json}`: die faces 1–6 (+ shadows) at native size and the
///   doubling cube faces (+ shadows) at 192 px.
///
/// Sprites are cropped to their alpha > 0 bounds; each JSON frame records
/// its atlas rect and its group's visible content (alpha ≥ 128) so the
/// board can register shadows and size the on-edge bear-off sliver.
///
/// Decoding, cropping, resizing and packing use package:image (a dev
/// dependency); WebP encoding shells out to `cwebp` (`brew install webp`;
/// the committed outputs were made with cwebp 1.6.0, libsharpyuv 0.4.2),
/// since package:image cannot encode WebP. Run from the app root:
///
///     dart run tool/assets/build_game_assets.dart
///
/// The outputs are committed; re-run only when the source art changes.
library;

import 'dart:io';

import 'package:image/image.dart' as img;

import 'atlas_builder.dart';
import 'image_ops.dart';

const _src = 'assets/images';
const _out = 'assets/images/game';

/// Checker discs are 222 px in the 400 px source; the atlas holds 192.
const _checkerScale = 192 / 222;

/// Doubling-cube faces are 205 px in the source; the atlas holds 192.
const _cubeScale = 192 / 205;

final _report = <List<Object>>[];

void _measure(String label, List<String> before, List<String> after) {
  int bytes(List<String> fs) => fs.fold(0, (s, f) => s + File(f).lengthSync());
  int rgba(List<String> fs, {bool webp = false}) => fs.fold(0, (s, f) {
        final im = webp
            ? img.decodeWebP(File(f).readAsBytesSync())!
            : img.decodePng(File(f).readAsBytesSync())!;
        return s + im.width * im.height * 4;
      });
  _report.add([
    label,
    bytes(before),
    rgba(before),
    bytes(after),
    rgba(after, webp: true),
  ]);
}

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync() || !Directory(_src).existsSync()) {
    stderr.writeln('Run from the app root (where pubspec.yaml is).');
    exit(64);
  }
  Directory(_out).createSync(recursive: true);
  final tmp = Directory.systemTemp.createTempSync('tavli_assets_');
  try {
    await _build(tmp);
  } finally {
    tmp.deleteSync(recursive: true);
  }
  _printReport();
}

Future<void> _build(Directory tmp) async {
  // Boards: 2102 × 2374 → 1200 × 1355 (aspect kept within 0.03 %).
  for (final set in const [1, 2, 3]) {
    final src = readPng('$_src/boards/set${set}_board.png');
    final w = 1200, h = (src.height * w / src.width).round();
    await writeWebp(resize(src, w, h), '$_out/board_set$set.webp',
        ['-q', '90', '-alpha_q', '100', '-m', '6'], tmp);
  }
  _measure('boards ×3', [
    for (final s in const [1, 2, 3]) '$_src/boards/set${s}_board.png'
  ], [
    for (final s in const [1, 2, 3]) '$_out/board_set$s.webp'
  ]);

  // Table: 4320 × 2700 → 1600 × 1000 (same 1.6 aspect).
  await writeWebp(resize(readPng('$_src/backgrounds/table.png'), 1600, 1000),
      '$_out/table.webp', ['-q', '85', '-m', '6', '-noalpha'], tmp);
  _measure('table', ['$_src/backgrounds/table.png'], ['$_out/table.webp']);

  // Checkers: the three sets are byte-identical, so set 1 serves all.
  final checkerSources = <String>[];
  final checkers = <SpriteSpec>[];
  for (final tone in const ['light', 'dark']) {
    final normal = '$_src/checkers/set1_${tone}_normal.png';
    for (final frame in const ['normal', 'selected', 'shadow', 'vertical']) {
      final path = '$_src/checkers/set1_${tone}_$frame.png';
      checkerSources.add(path);
      checkers.add(SpriteSpec('${tone}_$frame', path, _checkerScale,
          visibleFrom: frame == 'vertical' ? path : normal));
    }
  }
  await buildAtlas(checkers, _out, 'checkers.webp', 'checkers.json', tmp);
  _measure('checkers (per set)', checkerSources, ['$_out/checkers.webp']);

  final diceSources = <String>[];
  final dice = <SpriteSpec>[];
  for (var face = 1; face <= 6; face++) {
    final active = '$_src/dice/set1_die_${face}_active.png';
    final shadow = '$_src/dice/set1_die_${face}_shadow.png';
    diceSources.addAll([active, shadow]);
    dice
      ..add(SpriteSpec('die_$face', active, 1))
      ..add(SpriteSpec('die_${face}_shadow', shadow, 1, visibleFrom: active));
  }
  for (final v in const [2, 4, 8, 16, 32, 64]) {
    final face = '$_src/dice/doubling_cube_$v.png';
    final shadow = '$_src/dice/doubling_cube_${v}_shadow.png';
    diceSources.addAll([face, shadow]);
    dice
      ..add(SpriteSpec('cube_$v', face, _cubeScale))
      ..add(SpriteSpec('cube_${v}_shadow', shadow, _cubeScale,
          visibleFrom: face));
  }
  await buildAtlas(dice, _out, 'dice.webp', 'dice.json', tmp);
  _measure('dice + cube', diceSources, ['$_out/dice.webp']);
}

void _printReport() {
  String mb(Object b) => ((b as int) / (1 << 20)).toStringAsFixed(2);
  stdout
    ..writeln('| asset | before bytes | before RGBA MB '
        '| after bytes | after RGBA MB |')
    ..writeln('|---|---:|---:|---:|---:|');
  for (final r in _report) {
    stdout
        .writeln('| ${r[0]} | ${r[1]} | ${mb(r[2])} | ${r[3]} | ${mb(r[4])} |');
  }
}
