import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;    // 2.8s overall
  late AnimationController _ringCtrl;    // repeating rings
  late AnimationController _particleCtrl; // repeating particles

  static const _shapes = [
    ShapeType.circle,
    ShapeType.square,
    ShapeType.star,
    ShapeType.triangle,
  ];
  static const _shapeColors = [
    Color(0xFF5DADE2),
    Color(0xFF3498DB),
    Color(0xFFFFD700),
    Color(0xFFE74C3C),
  ];

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..forward();

    _ringCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _particleCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _ringCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF04010E),
      body: Stack(
        children: [
          // ── Leonardo AI splash background ──────────────────────────
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash/splash_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Expanding rings ────────────────────────────────────────
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _RingsPainter(_ringCtrl.value),
            ),
          ),

          // ── Flying particles ───────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Center + title ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _mainCtrl,
            builder: (_, __) {
              final t = _mainCtrl.value; // 0-1 over 2.8s

              // Shape cycling: 4 shapes × 0.25 each
              final rawIndex = (t / 0.25).floor();
              final shapeIndex = rawIndex.clamp(0, 3);
              final shapeT = (t % 0.25) / 0.25;

              // Scale: bounce in at start of each shape
              final shapeScale = shapeT < 0.18
                  ? _easeOutBack(shapeT / 0.18)
                  : 1.0;

              // Background radial opacity
              final bgAlpha = (t / 0.2).clamp(0.0, 1.0);

              // Title appears at t=0.35
              final titleAlpha = ((t - 0.35) / 0.25).clamp(0.0, 1.0);
              final titleSlide = (1.0 - titleAlpha) * 20;

              // Studio name appears at t=0.6
              final studioAlpha = ((t - 0.6) / 0.2).clamp(0.0, 1.0);

              final shapeColor = _shapeColors[shapeIndex];

              return Stack(
                children: [
                  // Radial glow from center
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            shapeColor.withOpacity(bgAlpha * 0.22),
                            const Color(0xFF9B59B6).withOpacity(bgAlpha * 0.10),
                            Colors.transparent,
                          ],
                          radius: 0.5,
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // ── Morphing shape ────────────────────────────
                        Transform.scale(
                          scale: shapeScale,
                          child: SizedBox(
                            width: 130,
                            height: 130,
                            child: CustomPaint(
                              painter: _SplashShapePainter(
                                shape: _shapes[shapeIndex],
                                color: shapeColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        // ── MORPH GATE title ──────────────────────────
                        Transform.translate(
                          offset: Offset(0, titleSlide),
                          child: Opacity(
                            opacity: titleAlpha,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xFFCE93D8),
                                      Color(0xFFFFFFFF),
                                      Color(0xFFE040FB),
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'MORPH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 10,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'GATE',
                                  style: TextStyle(
                                    color: Color(0xFFD8C0F0),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 16,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Opacity(
                          opacity: studioAlpha,
                          child: Text(
                            'Petit Works Apps',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }
}

// ── Expanding rings painter ────────────────────────────────────────────────
class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxR = 280.0;

    for (int i = 0; i < 4; i++) {
      final rt = (t + i * 0.25) % 1.0;
      final radius = rt * maxR;
      final opacity = (1.0 - rt) * 0.18;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF9B59B6).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.t != t;
}

// ── Flying particles painter ──────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = Random(77);
  static final _particles = List.generate(20, (i) {
    final angle = i * (2 * pi / 20) + _rng.nextDouble() * 0.3;
    return (
      angle: angle,
      speed: 60.0 + _rng.nextDouble() * 80,
      size: 2.0 + _rng.nextDouble() * 2.5,
      phase: _rng.nextDouble(),
      color: [
        const Color(0xFF9B59B6),
        const Color(0xFFE040FB),
        const Color(0xFF5DADE2),
        const Color(0xFFFFD700),
      ][i % 4],
    );
  });

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in _particles) {
      final pt = (t + p.phase) % 1.0;
      final dist = pt * p.speed * 2;
      final x = center.dx + cos(p.angle) * dist;
      final y = center.dy + sin(p.angle) * dist;
      final opacity = pt < 0.5 ? pt * 2 * 0.7 : (1.0 - pt) * 2 * 0.7;

      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - pt * 0.5),
        Paint()..color = p.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ── Splash shape painter ──────────────────────────────────────────────────
class _SplashShapePainter extends CustomPainter {
  final ShapeType shape;
  final Color color;
  _SplashShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 44.0;

    // Outer glow
    canvas.drawCircle(
      center,
      radius * 1.6,
      Paint()
        ..color = color.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // Inner glow
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()
        ..color = color.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Shape
    ShapeUtils.drawShape(canvas, shape, center, radius, color, glowing: true);

    // Highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.35),
      radius * 0.28,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashShapePainter old) =>
      old.shape != shape || old.color != color;
}
