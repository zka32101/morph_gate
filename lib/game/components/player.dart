import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/shape_utils.dart';

class PlayerComponent extends PositionComponent with HasGameRef {
  ShapeType activeShape = ShapeType.square;
  CompositeShape? activeComposite;
  bool isCompositeActive = false;
  int jellifyLevel = 0;
  Color? characterBaseColor;

  double _transformProgress = 1.0;
  bool _isTransforming = false;
  double _squishY = 1.0;
  bool _squishing = false;
  double _squishTime = 0;

  // Glow + breathe
  double _glowTime = 0;
  double _breathScale = 1.0;

  // Orbit particles (decorative dots spinning around player)
  double _orbitTime = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(GameConfig.playerRadius * 2);
    anchor = Anchor.center; // ← センターアンカーに変更
  }

  void transformTo(ShapeType shape) {
    if (shape == activeShape && !isCompositeActive) return;
    activeShape = shape;
    activeComposite = null;
    isCompositeActive = false;
    _transformProgress = 0.0;
    _isTransforming = true;
  }

  void transformToComposite(CompositeShape composite) {
    activeComposite = composite;
    isCompositeActive = true;
    _transformProgress = 0.0;
    _isTransforming = true;
  }

  void triggerSquish() {
    _squishing = true;
    _squishTime = 0;
  }

  Color get _playerColor {
    if (characterBaseColor != null) return characterBaseColor!;
    switch (jellifyLevel) {
      case 0:
        return AppColors.jellySteelBlue;
      case 1:
        return AppColors.jellyGreen;
      case 2:
        return AppColors.jellyCrystal;
      case 3:
        return AppColors.jellyGhost;
      default:
        return AppColors.jellyPrimordial;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isTransforming) {
      final duration = isCompositeActive
          ? GameConfig.shapeDurationComposite
          : GameConfig.shapeDurationSingle;
      _transformProgress = (_transformProgress + dt / duration).clamp(0.0, 1.0);
      if (_transformProgress >= 1.0) _isTransforming = false;
    }

    if (_squishing) {
      _squishTime += dt;
      if (_squishTime < 0.3) {
        _squishY = 1.0 - 0.4 * sin(_squishTime / 0.3 * pi);
      } else {
        _squishY = 1.0;
        _squishing = false;
      }
    }

    _glowTime += dt;
    _orbitTime += dt;
    // 呼吸スケール (±5%)
    _breathScale = 1.0 + 0.05 * sin(_glowTime * 1.8);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = GameConfig.playerRadius;
    final color = _playerColor;

    final glowStrength = (sin(_glowTime * 2) * 0.15 + 0.85).clamp(0.0, 1.0);
    final glowing = jellifyLevel >= 2;

    // ── パルスリング（外周の波紋） ──────────────────────────────────
    _drawPulseRings(canvas, center, radius, color);

    // ── オービット粒子（進化レベル1以上） ──────────────────────────────
    if (jellifyLevel >= 1 && !_squishing) {
      _drawOrbitParticles(canvas, center, radius, color);
    }

    // ── 外側グロー（2層） ───────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius * 1.7 * _breathScale,
      Paint()
        ..color = color.withOpacity(0.06 + 0.04 * sin(_glowTime * 2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.14 + 0.09 * sin(_glowTime * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius * 1.4 * _breathScale, outerGlowPaint);

    // ── スカッシュ変換 ──────────────────────────────────────────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, _squishY);
    canvas.translate(-center.dx, -center.dy);

    // ── 変形アニメーション ────────────────────────────────────────
    if (_isTransforming && _transformProgress < 1.0) {
      final scale = (_breathScale * (0.7 + 0.3 * _transformProgress));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);
    } else {
      // 呼吸スケール
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(_breathScale, _breathScale);
      canvas.translate(-center.dx, -center.dy);
    }

    if (isCompositeActive && activeComposite != null) {
      ShapeUtils.drawCompositeShape(
        canvas,
        activeComposite!,
        center,
        radius,
        color,
        glowing: glowing,
      );
    } else {
      ShapeUtils.drawShape(
        canvas,
        activeShape,
        center,
        radius * glowStrength,
        color,
        glowing: glowing,
      );
    }

    // ── ハイライト（内側の明るい反射） ──────────────────────────────
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.28),
      radius * 0.35,
      highlightPaint,
    );

    canvas.restore(); // transform/breathe
    canvas.restore(); // squish
  }

  void _drawPulseRings(Canvas canvas, Offset center, double radius, Color color) {
    // 2 expanding rings out of phase
    for (int i = 0; i < 2; i++) {
      final t = (_glowTime * 0.6 + i * 0.5) % 1.0;
      final ringRadius = radius * (1.0 + t * 1.1);
      final opacity = (1.0 - t) * 0.22;
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawOrbitParticles(Canvas canvas, Offset center, double radius, Color color) {
    final count = jellifyLevel >= 3 ? 5 : 3;
    final orbitRadius = radius + 14.0 + jellifyLevel * 2.0;
    final speed = 1.2 + jellifyLevel * 0.2;

    for (int i = 0; i < count; i++) {
      final angle = _orbitTime * speed + (2 * pi / count) * i;
      final px = center.dx + cos(angle) * orbitRadius;
      final py = center.dy + sin(angle) * orbitRadius * 0.5; // 楕円軌道

      final dotOpacity = 0.5 + 0.3 * sin(_orbitTime * 2 + i);
      final dotSize = 2.5 + 1.0 * sin(_orbitTime * 3 + i * 1.3);

      final paint = Paint()
        ..color = color.withOpacity(dotOpacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(px, py), dotSize, paint);
    }
  }
}
