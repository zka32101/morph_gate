import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class BackgroundComponent extends Component with HasGameRef {
  final List<_Star> _stars = [];
  final List<_StreamParticle> _streams = [];
  final List<_NebulaOrb> _orbs = [];
  final Random _rng = Random();
  double _time = 0;
  DifficultyLevel difficultyLevel = DifficultyLevel.easy;
  double _diffTransition = 0.0; // 0=easy 1=expert (smooth lerp)

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generateStars();
    _generateStreams();
    _generateOrbs();
  }

  void _generateOrbs() {
    _orbs.clear();
    const palette = [
      Color(0xFF7B2FBE),
      Color(0xFF2F6FBE),
      Color(0xFFBE2F8F),
      Color(0xFF2FBE9F),
    ];
    for (int i = 0; i < 5; i++) {
      _orbs.add(_NebulaOrb(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 90 + _rng.nextDouble() * 120,
        driftX: (_rng.nextDouble() - 0.5) * 0.02,
        driftSpeed: 0.15 + _rng.nextDouble() * 0.25,
        phase: _rng.nextDouble() * pi * 2,
        color: palette[i % palette.length],
      ));
    }
  }

  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 80; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble() * 400,
        y: _rng.nextDouble() * 800,
        radius: _rng.nextDouble() * 2 + 0.5,
        opacity: _rng.nextDouble() * 0.7 + 0.3,
        twinkleSpeed: _rng.nextDouble() * 2 + 0.5,
      ));
    }
  }

  void _generateStreams() {
    _streams.clear();
    for (int i = 0; i < 30; i++) {
      _streams.add(_StreamParticle(
        x: _rng.nextDouble() * 400,
        y: _rng.nextDouble() * 800,
        speed: _rng.nextDouble() * 50 + 25,
        length: _rng.nextDouble() * 22 + 8,
        opacity: _rng.nextDouble() * 0.18 + 0.04,
      ));
    }
  }

  List<Color> get _bgGradient {
    switch (difficultyLevel) {
      case DifficultyLevel.easy:
        return const [Color(0xFF080415), Color(0xFF120820), Color(0xFF1E0D35)];
      case DifficultyLevel.normal:
        return const [Color(0xFF060420), Color(0xFF0D0A38), Color(0xFF180F50)];
      case DifficultyLevel.hard:
        return const [Color(0xFF100408), Color(0xFF2A0C14), Color(0xFF3E1020)];
      case DifficultyLevel.expert:
        return const [Color(0xFF0E0000), Color(0xFF1C0408), Color(0xFF2C0A12)];
    }
  }

  Color get _laneAccent {
    switch (difficultyLevel) {
      case DifficultyLevel.easy:
        return const Color(0xFF7B2FBE);
      case DifficultyLevel.normal:
        return const Color(0xFF2F5FBE);
      case DifficultyLevel.hard:
        return const Color(0xFFBE7B2F);
      case DifficultyLevel.expert:
        return const Color(0xFFBE2F2F);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final targetTransition = difficultyLevel.index / 3.0;
    _diffTransition += (targetTransition - _diffTransition) * dt * 0.8;

    final speedMul = 1.0 + difficultyLevel.index * 0.4;
    for (final p in _streams) {
      p.update(dt * speedMul, gameRef.size.y);
    }
    for (final s in _stars) {
      s.update(dt);
    }
    for (final o in _orbs) {
      o.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final sz = gameRef.size;

    // Background gradient (difficulty-based)
    final colors = _bgGradient;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, sz.x, sz.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), bgPaint);

    // Floating nebula orbs (deep ambient color)
    _drawNebulaOrbs(canvas, sz);

    // Far-depth stars
    _drawStars(canvas);

    // Streaming ambient particles
    final lc = _laneAccent;
    for (final p in _streams) {
      final paint = Paint()
        ..color = lc.withOpacity(p.opacity)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(p.x, p.y), Offset(p.x, p.y - p.length), paint);
    }

    _drawCenterLane(canvas, sz, lc);
    _drawScanlines(canvas, sz);
    _drawVignette(canvas, sz);
  }

  void _drawNebulaOrbs(Canvas canvas, Vector2 sz) {
    final intensity = 0.10 + _diffTransition * 0.06;
    for (final o in _orbs) {
      final cx = o.currentX * sz.x;
      final cy = o.y * sz.y;
      final breathe = 1.0 + 0.12 * sin(_time * o.driftSpeed + o.phase);
      final r = o.radius * breathe;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            o.color.withOpacity(intensity),
            o.color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _drawVignette(Canvas canvas, Vector2 sz) {
    final rect = Rect.fromLTWH(0, 0, sz.x, sz.y);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(0.30),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawStars(Canvas canvas) {
    for (final star in _stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.currentOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(star.x, star.y), star.radius, paint);
    }
  }

  void _drawCenterLane(Canvas canvas, Vector2 size, Color laneColor) {
    final cx = size.x / 2;
    final laneW = size.x * 0.22;

    final pulse = 0.06 + 0.02 * sin(_time * 0.8);
    final lanePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          laneColor.withOpacity(pulse),
          laneColor.withOpacity(pulse * 1.5),
          laneColor.withOpacity(pulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(cx - laneW, 0, laneW * 2, size.y));
    canvas.drawRect(Rect.fromLTWH(cx - laneW, 0, laneW * 2, size.y), lanePaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05 + 0.03 * sin(_time * 1.2))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.y), linePaint);

    final edgePaint = Paint()
      ..color = laneColor.withOpacity(0.10)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx - laneW, 0), Offset(cx - laneW, size.y), edgePaint);
    canvas.drawLine(Offset(cx + laneW, 0), Offset(cx + laneW, size.y), edgePaint);
  }

  void _drawScanlines(Canvas canvas, Vector2 size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.y; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), linePaint);
    }
  }
}

class _Star {
  double x, y;
  final double radius, opacity, twinkleSpeed;
  double _t = 0;
  _Star({required this.x, required this.y, required this.radius,
      required this.opacity, required this.twinkleSpeed});
  double get currentOpacity => opacity * (0.5 + 0.5 * sin(_t * twinkleSpeed));
  void update(double dt) => _t += dt;
}

class _StreamParticle {
  double x, y;
  final double speed, length, opacity;
  _StreamParticle({required this.x, required this.y, required this.speed,
      required this.length, required this.opacity});
  void update(double dt, double screenH) {
    y += speed * dt;
    if (y > screenH + length) y = -length;
  }
}

class _NebulaOrb {
  final double x, y, radius, driftX, driftSpeed, phase;
  final Color color;
  double _t = 0;
  _NebulaOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.driftX,
    required this.driftSpeed,
    required this.phase,
    required this.color,
  });
  double get currentX =>
      (x + sin(_t * driftSpeed + phase) * 0.08).clamp(0.0, 1.0);
  void update(double dt) => _t += dt;
}
