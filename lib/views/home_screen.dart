import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/character_model.dart';
import '../services/ad_service.dart';
import '../services/character_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/hive_service.dart';
import '../services/iap_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';
import 'character_select_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnim = Tween(begin: -1.0, end: 2.0).animate(_shimmerController);

    _bannerAd = AdService().createBanner();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    AdService().disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highScore = HiveService.getHighScore();
    final jellifyLevel = HiveService.getJellifyLevel();
    final selectedChar = CharacterService.getSelected();
    final coins = HiveService.getOrCreateUser().coins;

    return Scaffold(
      backgroundColor: const Color(0xFF060212),
      body: Stack(
        children: [
          const _FloatingShapes(),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopBadge(
                        icon: Icons.star,
                        label: '$highScore',
                        color: AppColors.gold,
                      ),
                      Row(
                        children: [
                          _TopBadge(
                            icon: Icons.monetization_on,
                            label: '$coins',
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: AppColors.textSecondary),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Logo ───────────────────────────────────────────────
                _GradientLogo(shimmerAnim: _shimmerAnim),
                const SizedBox(height: 6),
                Text(
                  'Shape  ·  Transform  ·  Survive',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Jelly character preview ────────────────────────────
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: _JellyPreview(
                      level: jellifyLevel,
                      characterColor: selectedChar.baseColor,
                      glowColor: selectedChar.glowColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  EvolutionConfig.names[jellifyLevel],
                  style: TextStyle(
                    color: _evolutionColor(jellifyLevel),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // キャラ選択
                GestureDetector(
                  onTap: () async {
                    SoundService().playButton();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CharacterSelectScreen()),
                    );
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selectedChar.baseColor.withOpacity(0.5),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: selectedChar.baseColor.withOpacity(0.12),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedChar.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          selectedChar.name,
                          style: TextStyle(
                              color: selectedChar.baseColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.swap_horiz,
                            color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── PLAY button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        SoundService().playButton();
                        final vm = ref.read(gameViewModelProvider);

                        // Log game start
                        await FirebaseAnalyticsService.logGameStart(
                          jellifyLevel: vm.jellifyLevel,
                          difficulty: vm.difficultyLevel.toString(),
                        );

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A0DAD), Color(0xFFE040FB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE040FB).withOpacity(0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'PLAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  color: Colors.white54,
                                  blurRadius: 12,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Shop Button ────────────────────────────────
                GestureDetector(
                  onTap: () {
                    SoundService().playButton();
                    _showShopMenu();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: const Color(0xFF66FFB2).withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            color: Color(0xFF66FFB2), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Shop',
                          style: TextStyle(
                            color: Color(0xFF66FFB2),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                if (_bannerAd != null)
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShopMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0415),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Premium Shop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.remove_ads, color: Color(0xFF66FFB2)),
            title: const Text('Remove Ads', style: TextStyle(color: Colors.white)),
            subtitle: const Text('¥99', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(context);
              final success = await IAPService().purchaseRemoveAds();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase successful!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.stars, color: Color(0xFFFFD700)),
            title: const Text('Premium Pass', style: TextStyle(color: Colors.white)),
            subtitle:
                const Text('¥499 - 2x multiplier + exclusive features', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(context);
              final success = await IAPService().purchasePremiumPass();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase successful!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFFE040FB)),
            title: const Text('Character Pack', style: TextStyle(color: Colors.white)),
            subtitle:
                const Text('¥299 - 4 exclusive characters', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(context);
              final success = await IAPService().purchaseCharacterPack();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase successful!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.white70),
            title: const Text('Restore Purchases', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final success = await IAPService().restorePurchases();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchases restored!')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _evolutionColor(int level) {
    switch (level) {
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
}

// ── グラデーションロゴ ─────────────────────────────────────────────────────
class _GradientLogo extends StatelessWidget {
  final Animation<double> shimmerAnim;
  const _GradientLogo({required this.shimmerAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) {
        final shimX = shimmerAnim.value;
        return Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(shimX - 1, 0),
                end: Alignment(shimX + 1, 0),
                colors: const [
                  Color(0xFF9B59B6),
                  Color(0xFFE040FB),
                  Color(0xFFFFFFFF),
                  Color(0xFFE040FB),
                  Color(0xFF7B2FBE),
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ).createShader(bounds),
              child: const Text(
                'MORPH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
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
                fontSize: 34,
                fontWeight: FontWeight.w200,
                letterSpacing: 16,
                height: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── TopBadge ─────────────────────────────────────────────────────────────
class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TopBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Jelly Preview ─────────────────────────────────────────────────────────
class _JellyPreview extends StatelessWidget {
  final int level;
  final Color? characterColor;
  final Color? glowColor;
  const _JellyPreview(
      {required this.level, this.characterColor, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
          painter: _JellyPainter(
              level: level,
              characterColor: characterColor,
              glowColor: glowColor)),
    );
  }
}

class _JellyPainter extends CustomPainter {
  final int level;
  final Color? characterColor;
  final Color? glowColor;

  _JellyPainter(
      {required this.level, this.characterColor, this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    final Color color;
    if (characterColor != null) {
      color = characterColor!;
    } else {
      switch (level) {
        case 0:
          color = AppColors.jellySteelBlue;
        case 1:
          color = AppColors.jellyGreen;
        case 2:
          color = AppColors.jellyCrystal;
        case 3:
          color = AppColors.jellyGhost;
        default:
          color = AppColors.jellyPrimordial;
      }
    }

    final effectGlow = glowColor ?? color;

    // Outer glow layer 1
    final glow1 = Paint()
      ..color = effectGlow.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, radius * 1.7, glow1);

    // Outer glow layer 2
    final glow2 = Paint()
      ..color = effectGlow.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius * 1.3, glow2);

    ShapeUtils.drawShape(canvas, ShapeType.circle, center, radius, color,
        glowing: level >= 2);

    // Inner highlight
    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(
        Offset(center.dx - radius * 0.28, center.dy - radius * 0.3),
        radius * 0.32,
        highlight);
  }

  @override
  bool shouldRepaint(covariant _JellyPainter old) =>
      old.characterColor != characterColor || old.level != level;
}

// ── Floating Background Shapes ────────────────────────────────────────────
class _FloatingShapes extends StatefulWidget {
  const _FloatingShapes();

  @override
  State<_FloatingShapes> createState() => _FloatingShapesState();
}

class _FloatingShapesState extends State<_FloatingShapes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _FloatingShapesPainter(_controller.value),
      ),
    );
  }
}

class _FloatingShapesPainter extends CustomPainter {
  final double t;

  // (shape, baseX, baseY, phase, size, color)
  static const _shapes = [
    (ShapeType.square, 0.08, 0.18, 0.0, 22.0),
    (ShapeType.circle, 0.82, 0.12, 0.3, 18.0),
    (ShapeType.star, 0.55, 0.08, 0.7, 26.0),
    (ShapeType.triangle, 0.12, 0.75, 1.1, 20.0),
    (ShapeType.square, 0.88, 0.82, 0.5, 16.0),
    (ShapeType.circle, 0.42, 0.92, 0.9, 22.0),
    (ShapeType.triangle, 0.72, 0.55, 0.2, 14.0),
    (ShapeType.star, 0.25, 0.45, 1.4, 18.0),
  ];

  static const _colors = [
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
    Color(0xFFFFD700),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFFE040FB),
  ];

  _FloatingShapesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _shapes.length; i++) {
      final (shape, bx, by, phase, sz) = _shapes[i];
      final color = _colors[i % _colors.length];
      final x = bx * size.width;
      final y = by * size.height + sin((t + phase) * 2 * pi) * 28;
      final opacity =
          (0.06 + 0.04 * sin((t * 1.3 + phase) * pi)).clamp(0.02, 0.12);
      final rotation = (t + phase) * pi * 0.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.translate(-x, -y);

      ShapeUtils.drawShape(
        canvas,
        shape,
        Offset(x, y),
        sz,
        color.withOpacity(opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingShapesPainter old) => old.t != t;
}
