import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'image_ops.dart';

/// One atlas sprite: [source] PNG, scaled by [scale] after cropping to
/// its alpha > 0 bounds. [visibleFrom] is the PNG whose solid content
/// (alpha ≥ 128) defines the frame's `visible` rect: the group reference
/// (the normal disc / die face), so shadows and selections stay registered
/// with it. All sources of a group share one canvas size.
class SpriteSpec {
  const SpriteSpec(this.name, this.source, this.scale, {String? visibleFrom})
      : visibleFrom = visibleFrom ?? source;
  final String name, source, visibleFrom;
  final double scale;
}

class _Packed {
  _Packed(this.spec, this.image, this.visible);
  final SpriteSpec spec;
  final img.Image image;
  final List<double> visible; // x, y, w, h in frame pixels
  int x = 0, y = 0;
}

const _padding = 4;
const _visibleThreshold = 127; // alpha ≥ 128

/// Crops, scales and shelf-packs [specs] into [imageName] + [jsonName]
/// under [outDir]. Returns the atlas image for the size report.
Future<img.Image> buildAtlas(List<SpriteSpec> specs, String outDir,
    String imageName, String jsonName, Directory tmp,
    {int atlasWidth = 1024}) async {
  final sprites = <_Packed>[];
  for (final s in specs) {
    final src = readPng(s.source);
    final ref = s.visibleFrom == s.source ? src : readPng(s.visibleFrom);
    if (ref.width != src.width || ref.height != src.height) {
      throw StateError('${s.name}: ${s.visibleFrom} is not on the same canvas');
    }
    final cropR =
        alphaBounds(src)!.inflate(1, src.width, src.height); // keep AA edge
    final vis = alphaBounds(ref, threshold: _visibleThreshold)!;
    final w = math.max(1, (cropR.w * s.scale).round());
    final h = math.max(1, (cropR.h * s.scale).round());
    final fx = w / cropR.w, fy = h / cropR.h;
    sprites.add(_Packed(s, resize(crop(src, cropR), w, h), [
      (vis.x - cropR.x) * fx,
      (vis.y - cropR.y) * fy,
      vis.w * fx,
      vis.h * fy,
    ]));
  }

  // Shelf packing, tallest first (deterministic: ties by name).
  final order = [...sprites]..sort((a, b) {
      final c = b.image.height.compareTo(a.image.height);
      return c != 0 ? c : a.spec.name.compareTo(b.spec.name);
    });
  var x = _padding, y = _padding, shelf = 0;
  for (final s in order) {
    if (x + s.image.width + _padding > atlasWidth) {
      x = _padding;
      y += shelf + _padding;
      shelf = 0;
    }
    s
      ..x = x
      ..y = y;
    x += s.image.width + _padding;
    shelf = math.max(shelf, s.image.height);
  }
  final height = y + shelf + _padding;
  final atlas = img.Image(width: atlasWidth, height: height, numChannels: 4);
  for (final s in order) {
    img.compositeImage(atlas, s.image,
        dstX: s.x, dstY: s.y, blend: img.BlendMode.direct);
  }

  double r2(double v) => (v * 100).round() / 100;
  final json = {
    'image': imageName,
    'width': atlasWidth,
    'height': height,
    'generator': 'tool/assets/build_game_assets.dart',
    'visibleAlphaMin': _visibleThreshold + 1,
    'frames': {
      for (final s in sprites)
        s.spec.name: {
          ...IRect(s.x, s.y, s.image.width, s.image.height).toJson(),
          'visible': {
            'x': r2(s.visible[0]),
            'y': r2(s.visible[1]),
            'w': r2(s.visible[2]),
            'h': r2(s.visible[3]),
          },
          'source': s.spec.source,
          'scale': s.spec.scale,
        },
    },
  };
  File('$outDir/$jsonName').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  await writeWebp(atlas, '$outDir/$imageName', ['-lossless', '-z', '9'], tmp);
  return atlas;
}
