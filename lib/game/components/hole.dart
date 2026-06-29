import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/shape_utils.dart';

class HoleComponent extends PositionComponent {
  final ShapeType? shapeType;
  final CompositeShape? compositeShape;
  final bool isComposite;
  final double holeRadius;

  HoleComponent({
    required Vector2 position,
    required this.holeRadius,
    this.shapeType,
    this.compositeShape,
    this.isComposite = false,
  }) : super(position: position);

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    if (isComposite && compositeShape != null) {
      ShapeUtils.drawCompositeShape(
        canvas,
        compositeShape!,
        center,
        holeRadius * 1.1,
        Colors.white.withOpacity(0.15),
      );
      ShapeUtils.drawCompositeShape(
        canvas,
        compositeShape!,
        center,
        holeRadius,
        Colors.transparent,
      );
    } else if (shapeType != null) {
      ShapeUtils.drawShape(
        canvas,
        shapeType!,
        center,
        holeRadius * 1.1,
        Colors.white.withOpacity(0.2),
      );
    }
  }
}
