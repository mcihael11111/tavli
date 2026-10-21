import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Integer pixel rect.
class IRect {
  const IRect(this.x, this.y, this.w, this.h);
  final int x, y, w, h;

  IRect inflate(int d, int maxW, int maxH) {
    final l = math.max(0, x - d), t = math.max(0, y - d);
    return IRect(
        l, t, math.min(maxW, x + w + d) - l, math.min(maxH, y + h + d) - t);
  }

  Map<String, num> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

/// Decodes a PNG as 4-channel 8-bit RGBA.
img.Image readPng(String path) {
  final im = img.decodePng(File(path).readAsBytesSync());
  if (im == null) throw StateError('cannot decode $path');
  return im.convert(numChannels: 4, format: img.Format.uint8);
}

/// Bounding box of the pixels with alpha > [threshold] (null if none).
IRect? alphaBounds(img.Image im, {int threshold = 0}) {
  var x0 = im.width, y0 = im.height, x1 = -1, y1 = -1;
  for (final p in im) {
    if (p.a > threshold) {
      x0 = math.min(x0, p.x);
      y0 = math.min(y0, p.y);
      x1 = math.max(x1, p.x);
      y1 = math.max(y1, p.y);
    }
  }
  return x1 < 0 ? null : IRect(x0, y0, x1 - x0 + 1, y1 - y0 + 1);
}

void _premultiply(img.Image im, {required bool undo}) {
  for (final p in im) {
    final a = p.a.toInt();
    if (undo) {
      if (a == 0) {
        p
          ..r = 0
          ..g = 0
          ..b = 0;
      } else {
        p
          ..r = math.min(255, (p.r * 255 / a).round())
          ..g = math.min(255, (p.g * 255 / a).round())
          ..b = math.min(255, (p.b * 255 / a).round());
      }
    } else {
      p
        ..r = (p.r * a / 255).round()
        ..g = (p.g * a / 255).round()
        ..b = (p.b * a / 255).round();
    }
  }
}

/// Area-average resize in premultiplied alpha (no colour bleeding from
/// transparent pixels).
img.Image resize(img.Image src, int w, int h) {
  if (src.width == w && src.height == h) return src.clone();
  final pre = src.clone();
  _premultiply(pre, undo: false);
  final out = img.copyResize(pre,
      width: w, height: h, interpolation: img.Interpolation.average);
  _premultiply(out, undo: true);
  return out;
}

img.Image crop(img.Image src, IRect r) =>
    img.copyCrop(src, x: r.x, y: r.y, width: r.w, height: r.h);

/// Encodes [im] to WebP at [out] through `cwebp` (package:image has no
/// WebP encoder). [cwebpArgs] are the quality options.
Future<void> writeWebp(
    img.Image im, String out, List<String> cwebpArgs, Directory tmp) async {
  final png = File('${tmp.path}/${out.hashCode}.png')
    ..writeAsBytesSync(img.encodePng(im));
  final r = await Process.run(
      'cwebp', ['-quiet', '-mt', ...cwebpArgs, png.path, '-o', out]);
  if (r.exitCode != 0) throw StateError('cwebp failed for $out: ${r.stderr}');
}
