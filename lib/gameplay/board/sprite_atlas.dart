import 'dart:convert';
import 'dart:ui';

/// One atlas frame: [rect] in the atlas image, and [visible], the solid
/// content (alpha ≥ 128) of the frame's group reference in frame pixels.
///
/// A shadow or selected frame carries its normal sprite's [visible] rect,
/// so drawing every frame of a group with [destFor] the same target keeps
/// them registered. The vertical sliver's [visible] is its own content.
class AtlasFrame {
  const AtlasFrame(this.rect, this.visible);

  final Rect rect;
  final Rect visible;

  /// Width / height of the visible content (the sliver aspect for layout).
  double get visibleAspect => visible.width / visible.height;

  /// Where to draw the whole frame so its [visible] rect lands on [target].
  Rect destFor(Rect target) {
    final sx = target.width / visible.width;
    final sy = target.height / visible.height;
    return Rect.fromLTWH(target.left - visible.left * sx,
        target.top - visible.top * sy, rect.width * sx, rect.height * sy);
  }
}

/// Frame data of an atlas written by `tool/assets/build_game_assets.dart`.
class SpriteAtlas {
  SpriteAtlas._(this.image, this.size, this.frames);

  /// Parses the atlas JSON ([image] is relative to the JSON's directory).
  factory SpriteAtlas.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    Rect rect(Object? o) {
      final m = o! as Map<String, dynamic>;
      return Rect.fromLTWH(
          (m['x'] as num).toDouble(),
          (m['y'] as num).toDouble(),
          (m['w'] as num).toDouble(),
          (m['h'] as num).toDouble());
    }

    final frames = <String, AtlasFrame>{
      for (final MapEntry(:key, :value)
          in (json['frames'] as Map<String, dynamic>).entries)
        key: AtlasFrame(rect(value), rect((value as Map)['visible'])),
    };
    return SpriteAtlas._(
        json['image'] as String,
        Size((json['width'] as num).toDouble(),
            (json['height'] as num).toDouble()),
        Map.unmodifiable(frames));
  }

  final String image;
  final Size size;
  final Map<String, AtlasFrame> frames;

  /// Throws [ArgumentError] for a missing frame.
  AtlasFrame operator [](String name) =>
      frames[name] ?? (throw ArgumentError.value(name, 'name', 'no frame'));
}
