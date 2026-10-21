import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/board/board_layout.dart';
import 'package:tavli/gameplay/board/board_region.dart';
import 'package:tavli/gameplay/board/sprite_atlas.dart';
import 'package:tavli/gameplay/board/sprite_names.dart';

/// The committed outputs of `tool/assets/build_game_assets.dart` (design
/// §5.5) against the names the board components use.
void main() {
  SpriteAtlas atlas(String key) =>
      SpriteAtlas.fromJson(File(key).readAsStringSync());
  final checkers = atlas(SpriteNames.checkerAtlasData);
  final dice = atlas(SpriteNames.diceAtlasData);

  group('frames', () {
    for (final (name, a, names, image) in [
      (
        'checkers',
        checkers,
        SpriteNames.checkerFrames,
        SpriteNames.checkerAtlasImage
      ),
      ('dice', dice, SpriteNames.diceFrames, SpriteNames.diceAtlasImage),
    ]) {
      test('$name atlas holds every component name', () {
        expect(a.frames.keys, containsAll(names));
        expect(image, endsWith('/${a.image}'));
      });

      test('$name frames lie inside the atlas and do not overlap', () {
        final bounds = Offset.zero & a.size;
        final rects = a.frames.values.map((f) => f.rect).toList();
        for (var i = 0; i < rects.length; i++) {
          expect(bounds.contains(rects[i].topLeft), isTrue);
          expect(rects[i].right <= a.size.width, isTrue);
          expect(rects[i].bottom <= a.size.height, isTrue);
          for (var j = i + 1; j < rects.length; j++) {
            final o = rects[i].intersect(rects[j]);
            expect(o.width <= 0 || o.height <= 0, isTrue,
                reason: 'frames $i and $j overlap');
          }
        }
      });
    }
  });

  test('every set maps to the one checker atlas; unknown sets fall back', () {
    for (final s in SpriteNames.boardSets) {
      expect(SpriteNames.checkerAtlasFor(s), SpriteNames.checkerAtlasData);
      expect(File(SpriteNames.board(s)).existsSync(), isTrue);
    }
    expect(SpriteNames.board(9), SpriteNames.board(1));
  });

  test('checker discs keep the 2026 art visible ratio (222/400)', () {
    final raw = jsonDecode(
            File(SpriteNames.checkerAtlasData).readAsStringSync())['frames']
        as Map<String, dynamic>;
    for (final t in CheckerTone.values) {
      final name = SpriteNames.checker(t, CheckerFrame.normal);
      final scale = (raw[name] as Map)['scale'] as num;
      final v = checkers[name].visible;
      expect(v.width / scale / 400, closeTo(222 / 400, 0.005));
      expect(v.width, closeTo(v.height, 1), reason: 'disc is round');
    }
  });

  test('shadow and selected frames stay registered with the disc', () {
    for (final t in CheckerTone.values) {
      final disc = checkers[SpriteNames.checker(t, CheckerFrame.normal)];
      for (final f in [CheckerFrame.selected, CheckerFrame.shadow]) {
        final other = checkers[SpriteNames.checker(t, f)];
        // Visible rects come from the disc, so they match in size.
        expect(other.visible.width, closeTo(disc.visible.width, 1.5));
        expect(other.visible.height, closeTo(disc.visible.height, 1.5));
        // destFor puts the visible content exactly on the target.
        const target = Rect.fromLTWH(10, 20, 30, 30);
        final d = other.destFor(target);
        final k = d.width / other.rect.width;
        expect(d.left + other.visible.left * k, closeTo(target.left, 1e-9));
        expect(d.top + other.visible.top * d.height / other.rect.height,
            closeTo(target.top, 1e-9));
        expect(other.visible.width * k, closeTo(target.width, 1e-9));
      }
    }
    for (var face = 1; face <= 6; face++) {
      expect(dice[SpriteNames.dieShadow(face)].visible.width,
          closeTo(dice[SpriteNames.die(face)].visible.width, 1.5));
    }
  });

  test('bear-off slivers use the cropped vertical sprite aspect', () {
    final aspect =
        checkers[SpriteNames.checker(CheckerTone.light, CheckerFrame.vertical)]
            .visibleAspect;
    // The solid on-edge checker is about 47 × 172 px: far narrower than the
    // legacy 77/202 that squashed the whole 400 px square into the slot.
    expect(aspect, closeTo(47 / 172, 0.02));
    final layout = BoardLayout(const Size(412, 915), sliverAspect: aspect);
    final slot = layout.traySlot(ViewEdge.bottom, 3);
    expect(slot.width / slot.height, closeTo(aspect, 1e-9));
  });

  test('pubspec registers the game assets', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('- assets/images/game/'));
  });

  testWidgets('WebP outputs decode at their documented sizes', (t) async {
    Future<(int, int)> size(String key) async => (await t.runAsync(() async {
          final codec =
              await instantiateImageCodec(File(key).readAsBytesSync());
          final frame = await codec.getNextFrame();
          final r = (frame.image.width, frame.image.height);
          frame.image.dispose();
          codec.dispose();
          return r;
        }))!;

    for (final s in SpriteNames.boardSets) {
      expect(await size(SpriteNames.board(s)), (1200, 1355));
    }
    expect(await size(SpriteNames.table), (1600, 1000));
    expect(await size(SpriteNames.checkerAtlasImage),
        (checkers.size.width.toInt(), checkers.size.height.toInt()));
    expect(await size(SpriteNames.diceAtlasImage),
        (dice.size.width.toInt(), dice.size.height.toInt()));
  });
}
