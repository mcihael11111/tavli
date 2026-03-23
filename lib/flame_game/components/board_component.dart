import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../../core/constants/colors.dart';
import '../rendering/lighting.dart';
import '../rendering/wood_texture_renderer.dart';
import 'board_layout.dart';

/// 3D-rendered backgammon board with wood grain, frame depth, and lighting.
///
/// Renders the board with visible thickness (like looking down at a real
/// board on a table), recessed playing surface, and directional lighting.
class BoardComponent extends PositionComponent {
  late BoardLayout layout;

  // Board set colors.
  Color _frameColor = TavliColors.mahoganyDark;
  Color _frameGrain = const Color(0xFF6B2D15);
  Color _surfaceColor = TavliColors.oliveWoodLight;
  Color _pointColorA = TavliColors.mahoganyLight;
  Color _pointColorB = TavliColors.oliveWoodDark;
  Color _barColor = TavliColors.mahoganyDark;

  /// Visible depth of the frame (3D thickness).
  double get _frameDepth => layout.boardWidth * 0.012;

  BoardComponent({required Vector2 gameSize}) {
    layout = BoardLayout(gameSize);
  }

  void onResize(Vector2 gameSize) {
    layout = BoardLayout(gameSize);
  }

  void setBoardSet(int setIndex) {
    switch (setIndex) {
      case 1:
        _frameColor = TavliColors.mahoganyDark;
        _frameGrain = const Color(0xFF6B2D15);
        _surfaceColor = TavliColors.oliveWoodLight;
        _pointColorA = TavliColors.mahoganyLight;
        _pointColorB = TavliColors.oliveWoodDark;
        _barColor = TavliColors.mahoganyDark;
      case 2:
        _frameColor = TavliColors.tealFrameDark;
        _frameGrain = const Color(0xFF4A1E14);
        _surfaceColor = TavliColors.tealFrameLight;
        _pointColorA = TavliColors.tealPointLight;
        _pointColorB = TavliColors.paleMaple;
        _barColor = TavliColors.tealFrameDark;
      case 3:
        _frameColor = TavliColors.darkWalnutDark;
        _frameGrain = const Color(0xFF1A0D06);
        _surfaceColor = TavliColors.navyDark;
        _pointColorA = TavliColors.copperLight;
        _pointColorB = TavliColors.ashLight;
        _barColor = TavliColors.darkWalnutDark;
    }
  }

  @override
  void render(Canvas canvas) {
    _drawTableSurface(canvas);
    _drawBoardShadow(canvas);
    _drawFrameBase(canvas);
    _drawFrame3DEdges(canvas);
    _drawRecessedSurface(canvas);
    _drawBar(canvas);
    _drawBearOffTrays(canvas);
    _drawPoints(canvas);
    _drawPointNotches(canvas);
    _drawFrameInnerEdge(canvas);
    _drawHinges(canvas);
  }

  /// Dark table underneath the board.
  void _drawTableSurface(Canvas canvas) {
    final tableRect = Rect.fromLTWH(
      0, 0,
      layout.gameSize.x, layout.gameSize.y,
    );
    WoodTextureRenderer.paintWoodRect(
      canvas, tableRect,
      baseColor: const Color(0xFF2A1A0E),
      grainColor: const Color(0xFF1A0D06),
      grainDensity: 20,
      lightIntensity: 0.6,
    );
  }

  /// Soft shadow underneath the board.
  void _drawBoardShadow(Canvas canvas) {
    final shadowRect = Rect.fromLTWH(
      layout.boardLeft + 4,
      layout.boardTop + 6,
      layout.boardWidth + 2,
      layout.boardHeight + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(4)),
      LightingSystem.dropShadowPaint(opacity: 0.5, blur: 12),
    );
  }

  /// Main frame top face with wood grain.
  void _drawFrameBase(Canvas canvas) {
    final frameRect = Rect.fromLTWH(
      layout.boardLeft,
      layout.boardTop,
      layout.boardWidth,
      layout.boardHeight,
    );

    // Rounded corners.
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(4)));

    WoodTextureRenderer.paintWoodRect(
      canvas, frameRect,
      baseColor: _frameColor,
      grainColor: _frameGrain,
      grainDensity: 16,
      lightIntensity: LightingSystem.topFaceLighting,
    );

    canvas.restore();
  }

  /// 3D edges of the frame (visible thickness).
  void _drawFrame3DEdges(Canvas canvas) {
    final rect = Rect.fromLTWH(
      layout.boardLeft,
      layout.boardTop,
      layout.boardWidth,
      layout.boardHeight,
    );

    WoodTextureRenderer.paintBeveledEdge(
      canvas,
      outerRect: rect,
      thickness: layout.frameThickness,
      color: _frameColor,
      depth: _frameDepth,
    );
  }

  /// Recessed playing surface — sits below the frame.
  void _drawRecessedSurface(Canvas canvas) {
    final f = layout.frameThickness;
    final surfaceRect = Rect.fromLTWH(
      layout.boardLeft + f,
      layout.boardTop + f,
      layout.boardWidth - f * 2,
      layout.boardHeight - f * 2,
    );

    // Inner shadow (recess effect).
    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRect(surfaceRect.inflate(1), innerShadowPaint);

    // Surface — lighter felt for contrast with triangular points.
    WoodTextureRenderer.paintFeltRect(
      canvas, surfaceRect,
      baseColor: _surfaceColor,
      lightIntensity: LightingSystem.topFaceLighting * 1.1,
    );

    // Subtle inner bevel highlight (top edge catches light).
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(surfaceRect.left, surfaceRect.top),
      Offset(surfaceRect.right, surfaceRect.top),
      highlightPaint,
    );
  }

  /// Center bar with 3D depth.
  void _drawBar(Canvas canvas) {
    final barX = layout.boardLeft + layout.boardWidth / 2 - layout.barWidth / 2;
    final barRect = Rect.fromLTWH(
      barX,
      layout.boardTop,
      layout.barWidth,
      layout.boardHeight,
    );

    WoodTextureRenderer.paintWoodRect(
      canvas, barRect,
      baseColor: _barColor,
      grainColor: _frameGrain,
      grainDensity: 8,
      lightIntensity: LightingSystem.topFaceLighting,
      isVertical: true,
    );

    // Bar side edges (3D).
    final edgePaint = Paint()
      ..color = LightingSystem.applyShadow(_barColor, 0.2);
    canvas.drawLine(
      Offset(barX, layout.boardTop),
      Offset(barX, layout.boardTop + layout.boardHeight),
      edgePaint..strokeWidth = 1.5,
    );
    final lightEdge = Paint()
      ..color = LightingSystem.applyLight(_barColor, 0.8).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(barX + layout.barWidth, layout.boardTop),
      Offset(barX + layout.barWidth, layout.boardTop + layout.boardHeight),
      lightEdge,
    );

    // Diamond inlay.
    _drawCenterDiamond(canvas);
  }

  void _drawCenterDiamond(Canvas canvas) {
    final cx = layout.boardLeft + layout.boardWidth / 2;
    final cy = layout.boardTop + layout.boardHeight / 2;
    final ds = layout.barWidth * 0.55;

    // Shadow under diamond.
    final shadowPath = Path()
      ..moveTo(cx, cy - ds - 1)
      ..lineTo(cx + ds * 0.6 + 1, cy)
      ..lineTo(cx, cy + ds + 1)
      ..lineTo(cx - ds * 0.6 - 1, cy)
      ..close();
    canvas.drawPath(shadowPath, Paint()
      ..color = Colors.black.withValues(alpha: 0.3));

    // Diamond fill.
    final diamondPath = Path()
      ..moveTo(cx, cy - ds)
      ..lineTo(cx + ds * 0.6, cy)
      ..lineTo(cx, cy + ds)
      ..lineTo(cx - ds * 0.6, cy)
      ..close();

    canvas.drawPath(diamondPath, Paint()
      ..color = _pointColorB.withValues(alpha: 0.6));

    // Diamond outline.
    canvas.drawPath(diamondPath, Paint()
      ..color = _pointColorA.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Inner diamond.
    final ids = ds * 0.5;
    final innerPath = Path()
      ..moveTo(cx, cy - ids)
      ..lineTo(cx + ids * 0.6, cy)
      ..lineTo(cx, cy + ids)
      ..lineTo(cx - ids * 0.6, cy)
      ..close();
    canvas.drawPath(innerPath, Paint()
      ..color = _pointColorA.withValues(alpha: 0.3));
  }

  /// Bear-off trays with recessed look.
  void _drawBearOffTrays(Canvas canvas) {
    final f = layout.frameThickness;

    for (final isRight in [true, false]) {
      final x = isRight
          ? layout.boardLeft + layout.boardWidth - f - layout.bearOffWidth
          : layout.boardLeft + f;

      final trayRect = Rect.fromLTWH(
        x, layout.boardTop + f,
        layout.bearOffWidth, layout.boardHeight - f * 2,
      );

      // Recessed tray.
      canvas.drawRect(
        trayRect,
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );
      canvas.drawRect(
        trayRect.deflate(1),
        Paint()..color = LightingSystem.applyShadow(_frameColor, 0.4),
      );

      // Top edge highlight.
      canvas.drawLine(
        Offset(trayRect.left, trayRect.top),
        Offset(trayRect.right, trayRect.top),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 0.5,
      );
    }
  }

  /// 3D triangular points with shading gradient.
  void _drawPoints(Canvas canvas) {
    for (int i = 0; i < 24; i++) {
      final isAColor = i % 2 == 0;
      final baseColor = isAColor ? _pointColorA : _pointColorB;

      final vertices = layout.pointTriangle(i);
      if (vertices.length != 3) continue;

      final path = Path()
        ..moveTo(vertices[0].x, vertices[0].y)
        ..lineTo(vertices[1].x, vertices[1].y)
        ..lineTo(vertices[2].x, vertices[2].y)
        ..close();

      // Gradient fill — lighter at base, darker at tip (3D depth illusion).
      final baseMid = Offset(
        (vertices[0].x + vertices[1].x) / 2,
        (vertices[0].y + vertices[1].y) / 2,
      );
      final tip = Offset(vertices[2].x, vertices[2].y);

      // Solid fill first for strong visibility.
      canvas.drawPath(path, Paint()..color = baseColor);

      // Then gradient overlay for 3D depth.
      final gradient = Paint()
        ..shader = Gradient.linear(
          baseMid,
          tip,
          [
            LightingSystem.applyLight(baseColor, LightingSystem.topFaceLighting)
                .withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.35),
          ],
        );
      canvas.drawPath(path, gradient);

      // Outline for definition.
      final outlinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, outlinePaint);

      // Left edge shadow (3D depth).
      final leftEdge = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(vertices[0].x, vertices[0].y),
        Offset(vertices[2].x, vertices[2].y),
        leftEdge,
      );

      // Right edge highlight.
      final rightEdge = Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(vertices[1].x, vertices[1].y),
        Offset(vertices[2].x, vertices[2].y),
        rightEdge,
      );
    }
  }

  /// Small notch marks at the base of each point for visual anchoring.
  void _drawPointNotches(Canvas canvas) {
    final notchPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (int i = 0; i < 24; i++) {
      final vertices = layout.pointTriangle(i);
      if (vertices.length != 3) continue;

      // Draw a small line at the base center.
      final baseMid = Offset(
        (vertices[0].x + vertices[1].x) / 2,
        (vertices[0].y + vertices[1].y) / 2,
      );
      final isTop = i >= 12;
      final notchLen = layout.pointWidth * 0.15;
      if (isTop) {
        canvas.drawLine(
          Offset(baseMid.dx, baseMid.dy),
          Offset(baseMid.dx, baseMid.dy + notchLen),
          notchPaint,
        );
      } else {
        canvas.drawLine(
          Offset(baseMid.dx, baseMid.dy),
          Offset(baseMid.dx, baseMid.dy - notchLen),
          notchPaint,
        );
      }
    }
  }

  /// Inner edge of the frame (lip over the playing surface).
  void _drawFrameInnerEdge(Canvas canvas) {
    final f = layout.frameThickness;
    final innerRect = Rect.fromLTWH(
      layout.boardLeft + f,
      layout.boardTop + f,
      layout.boardWidth - f * 2,
      layout.boardHeight - f * 2,
    );

    // Shadow on the inner edge (frame overhangs the surface).
    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(innerRect, innerShadow);

    // Light catch on top inner edge.
    final topHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(innerRect.left + 1, innerRect.top),
      Offset(innerRect.right - 1, innerRect.top),
      topHighlight,
    );
  }

  /// Brass hinges on the frame edge.
  void _drawHinges(Canvas canvas) {
    const hingeColor = Color(0xFFB8960A);
    final hingeY1 = layout.boardTop + layout.boardHeight * 0.3;
    final hingeY2 = layout.boardTop + layout.boardHeight * 0.7;
    final hingeX = layout.boardLeft + layout.boardWidth - 2;
    const hingeW = 6.0;
    const hingeH = 14.0;

    for (final y in [hingeY1, hingeY2]) {
      final hingeRect = Rect.fromLTWH(hingeX - hingeW / 2, y - hingeH / 2, hingeW, hingeH);

      // Shadow.
      canvas.drawRRect(
        RRect.fromRectAndRadius(hingeRect.translate(1, 1), const Radius.circular(1)),
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );

      // Hinge body.
      canvas.drawRRect(
        RRect.fromRectAndRadius(hingeRect, const Radius.circular(1)),
        Paint()..color = hingeColor,
      );

      // Highlight.
      canvas.drawLine(
        Offset(hingeRect.left + 1, hingeRect.top + 2),
        Offset(hingeRect.left + 1, hingeRect.bottom - 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..strokeWidth = 0.5,
      );

      // Screw dots.
      final screwPaint = Paint()..color = const Color(0xFF8A7008);
      canvas.drawCircle(Offset(hingeRect.center.dx, hingeRect.top + 3), 1.2, screwPaint);
      canvas.drawCircle(Offset(hingeRect.center.dx, hingeRect.bottom - 3), 1.2, screwPaint);
    }
  }
}
