import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/shape_utils.dart';

class WallComponent extends PositionComponent with HasGameRef {
  final ShapeType? holeShapeType;
  final CompositeShape? holeCompositeShape;
  final bool isCompositeHole;
  final bool isReverseRule;
  final bool isReverse;
  final double holeRadius;
  final double speed;
  final WallTier tier;

  bool _passed = false;
  bool missed = false;
  double _time = 0;

  // 壁が通過済みになった瞬間のフラッシュ
  double _passFlash = 0.0;

  // プレイヤーへの近接度（0.0 = 遠い, 1.0 = 重なっている）— wall_gameが更新
  double proximityRatio = 0.0;

  // Particle effects on pass
  final List<_Particle> _particles = [];

  /// 0.0=左端寄り 0.5=中央(デフォルト) 1.0=右端寄り
  final double holeXRatio;

  /// 1.0=通常 0.6=薄い(速い) 1.4=厚い(圧迫感)
  final double thicknessRatio;

  WallComponent({
    required Vector2 position,
    required double width,
    required this.speed,
    required this.holeRadius,
    this.holeShapeType,
    this.holeCompositeShape,
    this.isCompositeHole = false,
    this.isReverseRule = false,
    this.isReverse = false,
    this.tier = WallTier.normal,
    this.holeXRatio = 0.5,
    this.thicknessRatio = 1.0,
  }) : super(
          position: position,
          size: Vector2(width, GameConfig.wallThickness * thicknessRatio),
        );

  bool get passed => _passed;

  void markPassed() {
    _passed = true;
    _passFlash = 1.0;
    _spawnPassParticles();
  }

  Offset get _holeCenterLocal =>
      Offset(size.x * holeXRatio, size.y / 2);

  void _spawnPassParticles() {
    final rng = Random();
    final hc = _holeCenterLocal;
    for (int i = 0; i < 20; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed_ = rng.nextDouble() * 150 + 60;
      _particles.add(_Particle(
        x: hc.dx + (rng.nextDouble() - 0.5) * holeRadius * 1.5,
        y: hc.dy,
        vx: cos(angle) * speed_,
        vy: sin(angle) * speed_ - 80,
        color: HSVColor.fromAHSV(
          1.0,
          rng.nextDouble() * 80 + 260, // 紫〜青〜シアン系
          0.9,
          1.0,
        ).toColor(),
        life: 0.6 + rng.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += (isReverse ? -speed : speed) * dt;
    _time += dt;

    if (_passFlash > 0) {
      _passFlash = (_passFlash - dt * 4).clamp(0.0, 1.0);
    }

    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.dead);
  }

  bool isPlayerInHoleZone(Vector2 playerPos) {
    final hc = _holeCenterLocal;
    final holeCenter = Vector2(hc.dx, hc.dy);
    final relative = playerPos - position - holeCenter;
    return relative.length <= holeRadius;
  }

  bool checkCollision(Vector2 playerWorldPos) {
    if (_passed || missed) return false;
    final relX = playerWorldPos.x - position.x;
    final relY = playerWorldPos.y - position.y;
    if (relY < 0 || relY > size.y) return false;

    final hc = _holeCenterLocal;
    final distToHole = Vector2(relX, relY).distanceTo(Vector2(hc.dx, hc.dy));
    return distToHole > holeRadius * (1 + GameConfig.collisionTolerance);
  }

  // Tier-based wall colors
  List<Color> get _tierBaseColors {
    final w = proximityRatio.clamp(0.0, 1.0);
    if (isReverseRule) {
      return [
        Color.lerp(const Color(0xFF4A3000), const Color(0xFF8B4000), w)!,
        Color.lerp(const Color(0xFF7A5000), const Color(0xFFCC6000), w)!,
      ];
    }
    switch (tier) {
      case WallTier.bonus:
        return [
          Color.lerp(const Color(0xFF003A20), const Color(0xFF006040), w)!,
          Color.lerp(const Color(0xFF005030), const Color(0xFF008860), w)!,
        ];
      case WallTier.danger:
        return [
          Color.lerp(const Color(0xFF3A1800), const Color(0xFF7A2800), w)!,
          Color.lerp(const Color(0xFF5A2800), const Color(0xFFAA4000), w)!,
        ];
      case WallTier.normal:
        return [
          Color.lerp(const Color(0xFF3A0F7C), const Color(0xFF8B1A1A), w)!,
          Color.lerp(const Color(0xFF6B1FA2), const Color(0xFFCC2222), w)!,
        ];
    }
  }

  Color get _tierEdgeColor {
    final w = proximityRatio.clamp(0.0, 1.0);
    if (isReverseRule) return Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF8800), w)!;
    switch (tier) {
      case WallTier.bonus:
        return Color.lerp(const Color(0xFF66FFB2), const Color(0xFF00FF80), w)!;
      case WallTier.danger:
        return Color.lerp(const Color(0xFFFFAA44), const Color(0xFFFF6600), w)!;
      case WallTier.normal:
        return Color.lerp(const Color(0xFFCE93D8), const Color(0xFFFF6666), w)!;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final warningIntensity = proximityRatio.clamp(0.0, 1.0);

    // ── 壁本体 ────────────────────────────────────────────────────
    final baseColors = _tierBaseColors;
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: baseColors,
      ).createShader(rect);
    canvas.drawRect(rect, wallPaint);

    // ── ボーナス壁 ストライプアクセント ──────────────────────────
    if (tier == WallTier.bonus) {
      final stripePaint = Paint()
        ..color = const Color(0xFF00FF80).withOpacity(0.06 + 0.04 * sin(_time * 2))
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      for (double x = -size.y; x < size.x + size.y; x += 24) {
        canvas.drawLine(Offset(x, 0), Offset(x + size.y, size.y), stripePaint);
      }
    }

    // ── デンジャー壁 警告グリッド ─────────────────────────────────
    if (tier == WallTier.danger) {
      final gridPaint = Paint()
        ..color = const Color(0xFFFF6600).withOpacity(0.10 + 0.05 * sin(_time * 3))
        ..strokeWidth = 1.0;
      for (double x = 0; x < size.x; x += 18) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
      }
    }

    // ── リバース壁 ゴールドパルス ─────────────────────────────────
    if (isReverseRule) {
      final pulse = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.08 + 0.06 * sin(_time * 4))
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, pulse);
    }

    // ── 壁エッジグロー ────────────────────────────────────────────
    final edgeOpacity = 0.5 + warningIntensity * 0.4;
    final edgePaint = Paint()
      ..color = _tierEdgeColor.withOpacity(edgeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, edgePaint);

    // ── 穴のエッジグロー（カットアウト前） ─────────────────────────
    _renderHoleEdgeGlow(canvas);

    // ── 穴のカットアウト ──────────────────────────────────────────
    _renderHoleCutout(canvas);

    // ── 通過フラッシュ（通過後の残光） ───────────────────────────
    if (_passFlash > 0) {
      final flashPaint = Paint()
        ..color = const Color(0xFFE040FB).withOpacity(_passFlash * 0.4);
      canvas.drawRect(rect, flashPaint);
    }

    // ── パーティクル ────────────────────────────────────────────
    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  void _renderHoleEdgeGlow(Canvas canvas) {
    final hc = _holeCenterLocal;
    const minAlert = 0.6; // 70%接近時に警告開始
    final isAlerting = proximityRatio > minAlert;
    final alertIntensity =
        isAlerting ? ((proximityRatio - minAlert) / (1.0 - minAlert)) : 0.0;

    // Multi-layer glow rings
    const glowLayerCount = 3;
    for (int layer = glowLayerCount; layer >= 1; layer--) {
      final radius = holeRadius * (1.0 + layer * 0.35);
      final blurAmount = 20.0 - layer * 4.0;
      final opacity = (0.08 + alertIntensity * 0.25) / layer;
      final color = isAlerting
          ? Color.lerp(
              _tierEdgeColor,
              const Color(0xFFFF3355),
              alertIntensity * 0.7,
            )!
          : _tierEdgeColor;

      canvas.drawCircle(
        Offset(hc.dx, hc.dy),
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount),
      );
    }

    // Pulsing danger ring when critical
    if (proximityRatio > 0.95) {
      final pulsePhase = (_time * 4) % 1.0;
      final pulseOpacity = sin(pulsePhase * pi) * 0.4;
      canvas.drawCircle(
        Offset(hc.dx, hc.dy),
        holeRadius * 1.15,
        Paint()
          ..color = const Color(0xFFFF3355).withOpacity(pulseOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  void _renderHoleCutout(Canvas canvas) {
    final holeCenter = _holeCenterLocal;

    if (isCompositeHole && holeCompositeShape != null) {
      ShapeUtils.drawCompositeShape(
        canvas,
        holeCompositeShape!,
        holeCenter,
        holeRadius,
        const Color(0xFF080415),
      );
      // 複合穴のアウトライングロー
      ShapeUtils.drawCompositeShape(
        canvas,
        holeCompositeShape!,
        holeCenter,
        holeRadius,
        Colors.cyanAccent.withOpacity(0.4 + 0.2 * sin(_time * 3)),
        glowing: true,
      );
    } else if (holeShapeType != null) {
      ShapeUtils.drawShape(
        canvas,
        holeShapeType!,
        holeCenter,
        holeRadius,
        const Color(0xFF080415),
      );
      // 穴の輝くアウトライン（色は壁に合わせる）
      final holeGlowColor = Color.lerp(
        Colors.white,
        Colors.orangeAccent,
        proximityRatio,
      )!.withOpacity(0.55 + 0.2 * sin(_time * 3));
      ShapeUtils.drawShape(
        canvas,
        holeShapeType!,
        holeCenter,
        holeRadius,
        holeGlowColor,
        glowing: true,
      );
    }
  }
}

class _Particle {
  double x, y, vx, vy;
  final Color color;
  double life;
  final double maxLife;
  double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
  })  : maxLife = life,
        size = 4.0;

  bool get dead => life <= 0;
  double get opacity => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 200 * dt; // gravity
    life -= dt;
    size = 4.5 * opacity;
  }
}
