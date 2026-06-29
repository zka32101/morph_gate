import '../utils/shape_utils.dart';
import 'components/wall.dart';
import 'game_state.dart';

class CollisionResult {
  final bool isCollision;
  final bool isPass;
  final double accuracy;
  final bool usedMorphCharge;

  const CollisionResult({
    required this.isCollision,
    required this.isPass,
    this.accuracy = 0,
    this.usedMorphCharge = false,
  });
}

class CollisionHandler {
  static CollisionResult check({
    required WallComponent wall,
    required GameState state,
    required double playerX,
    required double playerY,
  }) {
    if (wall.passed || wall.missed) {
      return const CollisionResult(isCollision: false, isPass: false);
    }

    final wallTop = wall.position.y;
    final wallBottom = wall.position.y + wall.size.y;

    // Player is within wall Y range
    if (playerY < wallTop || playerY > wallBottom) {
      return const CollisionResult(isCollision: false, isPass: false);
    }

    final holeCenterX = wall.position.x + wall.size.x * wall.holeXRatio;
    final holeCenterY = wall.position.y + wall.size.y / 2;
    final dx = playerX - holeCenterX;
    final dy = playerY - holeCenterY;
    final distToHole = (dx * dx + dy * dy).sqrt();
    final tolerance = wall.holeRadius * (1 + 0.10);

    // Shape match check (Morph Charge can bypass shape)
    bool shapeMatch;
    bool usedCharge = false;
    if (state.isMorphCharged) {
      shapeMatch = true;
      usedCharge = true;
      state.isMorphCharged = false; // Use charge
    } else if (wall.isCompositeHole && wall.holeCompositeShape != null) {
      if (state.isCompositeActive && state.activeComposite != null) {
        shapeMatch = ShapeUtils.compositeFits(
            state.activeComposite!, wall.holeCompositeShape!);
      } else {
        shapeMatch = false;
      }
    } else if (wall.holeShapeType != null) {
      if (!state.isCompositeActive) {
        shapeMatch = ShapeUtils.shapeFits(state.activeShape, wall.holeShapeType!);
      } else {
        shapeMatch = false;
      }
    } else {
      shapeMatch = false;
    }

    // Reverse rule: logic inverted (avoid the hole instead of entering it)
    if (wall.isReverseRule) {
      if (distToHole <= tolerance) {
        // Too close to hole — collision (should have avoided it)
        return const CollisionResult(isCollision: true, isPass: false);
      } else {
        // Passed by avoiding the hole
        final accuracy = (distToHole / tolerance).clamp(0.0, 1.0);
        return CollisionResult(
          isCollision: false,
          isPass: true,
          accuracy: accuracy,
          usedMorphCharge: usedCharge,
        );
      }
    }

    if (!shapeMatch) {
      // Wrong shape — collision
      return const CollisionResult(isCollision: true, isPass: false);
    }

    if (distToHole <= tolerance) {
      // Passed through
      final accuracy = (1.0 - (distToHole / tolerance)).clamp(0.0, 1.0);
      return CollisionResult(
        isCollision: false,
        isPass: true,
        accuracy: accuracy,
        usedMorphCharge: usedCharge,
      );
    }

    // Right shape but hit the wall border
    return const CollisionResult(isCollision: true, isPass: false);
  }
}

extension on double {
  double sqrt() => this < 0 ? 0 : this == 0 ? 0 : _sqrt(this);

  static double _sqrt(double x) {
    // Newton-Raphson
    double est = x / 2;
    for (int i = 0; i < 8; i++) {
      est = (est + x / est) / 2;
    }
    return est;
  }
}
