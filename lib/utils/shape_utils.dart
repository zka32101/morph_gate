import 'dart:math';
import 'package:flutter/material.dart';

enum ShapeType { square, circle, star, triangle }

enum CompositeShape { crescent, crown, spiral, diamond }

class ShapeUtils {
  /// Returns true if the player shape fits through the hole shape
  /// with a tolerance of ±10%
  static bool shapeFits(ShapeType playerShape, ShapeType holeShape) {
    return playerShape == holeShape;
  }

  static bool compositeFits(
      CompositeShape playerComposite, CompositeShape holeComposite) {
    return playerComposite == holeComposite;
  }

  /// Determine composite shape from two single shapes
  static CompositeShape? toComposite(ShapeType a, ShapeType b) {
    final pair = {a, b};
    if (pair.containsAll([ShapeType.circle, ShapeType.triangle])) {
      return CompositeShape.crescent;
    }
    if (pair.containsAll([ShapeType.square, ShapeType.star])) {
      return CompositeShape.crown;
    }
    if (pair.containsAll([ShapeType.circle, ShapeType.star])) {
      return CompositeShape.spiral;
    }
    if (pair.containsAll([ShapeType.square, ShapeType.circle])) {
      return CompositeShape.diamond;
    }
    return null;
  }

  /// Draw player shape on canvas
  static void drawShape(
    Canvas canvas,
    ShapeType shape,
    Offset center,
    double radius,
    Color color, {
    bool glowing = false,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (glowing) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      _drawShapePath(canvas, shape, center, radius * 1.3, glowPaint);
    }

    _drawShapePath(canvas, shape, center, radius, paint);
  }

  static void _drawShapePath(
      Canvas canvas, ShapeType shape, Offset center, double radius, Paint paint) {
    switch (shape) {
      case ShapeType.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
            Radius.circular(radius * 0.15),
          ),
          paint,
        );
      case ShapeType.circle:
        canvas.drawCircle(center, radius, paint);
      case ShapeType.star:
        canvas.drawPath(_starPath(center, radius, 5), paint);
      case ShapeType.triangle:
        canvas.drawPath(_trianglePath(center, radius), paint);
    }
  }

  static Path _starPath(Offset center, double outerRadius, int points) {
    final innerRadius = outerRadius * 0.4;
    final path = Path();
    final angleStep = pi / points;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _trianglePath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius * sin(pi / 6));
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius * sin(pi / 6));
    path.close();
    return path;
  }

  static void drawCompositeShape(
    Canvas canvas,
    CompositeShape shape,
    Offset center,
    double radius,
    Color color, {
    bool glowing = false,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (glowing) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      _drawCompositePath(canvas, shape, center, radius, glowPaint);
    }
    _drawCompositePath(canvas, shape, center, radius, paint);
  }

  static void _drawCompositePath(
      Canvas canvas, CompositeShape shape, Offset center, double radius, Paint paint) {
    switch (shape) {
      case CompositeShape.crescent:
        // circle minus offset circle
        final path = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radius))
          ..addOval(Rect.fromCircle(
            center: Offset(center.dx + radius * 0.4, center.dy - radius * 0.2),
            radius: radius * 0.8,
          ));
        canvas.drawPath(
          Path.combine(PathOperation.difference, path,
              Path()
                ..addOval(Rect.fromCircle(
                  center: Offset(center.dx + radius * 0.4, center.dy - radius * 0.2),
                  radius: radius * 0.8,
                ))),
          paint,
        );
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: center, radius: radius)),
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.fill,
        );
        // Simplified crescent: just draw it as a circle with flat side
        final crescentPath = Path();
        crescentPath.addOval(Rect.fromCircle(center: center, radius: radius));
        final cutPath = Path();
        cutPath.addOval(Rect.fromCircle(
          center: Offset(center.dx + radius * 0.5, center.dy),
          radius: radius * 0.75,
        ));
        canvas.drawPath(
          Path.combine(PathOperation.difference, crescentPath, cutPath),
          paint,
        );
      case CompositeShape.crown:
        final path = Path();
        // Base rectangle
        path.addRect(Rect.fromLTWH(
          center.dx - radius, center.dy, radius * 2, radius * 0.6,
        ));
        // Three spikes
        for (int i = 0; i < 3; i++) {
          final x = center.dx - radius + (i * radius);
          path.moveTo(x, center.dy);
          path.lineTo(x + radius * 0.5, center.dy - radius);
          path.lineTo(x + radius, center.dy);
        }
        canvas.drawPath(path, paint);
      case CompositeShape.spiral:
        // Draw as circle + star overlay
        canvas.drawCircle(center, radius * 0.6, paint);
        canvas.drawPath(_starPath(center, radius, 6), paint);
      case CompositeShape.diamond:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius * 0.7, center.dy);
        path.lineTo(center.dx, center.dy + radius);
        path.lineTo(center.dx - radius * 0.7, center.dy);
        path.close();
        canvas.drawPath(path, paint);
    }
  }

  static String shapeLabel(ShapeType shape) {
    switch (shape) {
      case ShapeType.square:
        return '■';
      case ShapeType.circle:
        return '●';
      case ShapeType.star:
        return '★';
      case ShapeType.triangle:
        return '▲';
    }
  }

  static String compositeShapeLabel(CompositeShape shape) {
    switch (shape) {
      case CompositeShape.crescent:
        return '☽';
      case CompositeShape.crown:
        return '♛';
      case CompositeShape.spiral:
        return '✦';
      case CompositeShape.diamond:
        return '♦';
    }
  }
}
