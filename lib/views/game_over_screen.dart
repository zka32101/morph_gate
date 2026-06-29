import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/hive_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
import '../utils/constants.dart';
import '../viewmodels/game_viewmodel.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  const GameOverScreen({super.key});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _slideAnim;
  late Animation<int> _scoreAnim;

  int _finalScore = 0;
  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();

    final vm = ref.read(gameViewModelProvider);
    final highScore = HiveService.getHighScore();
    _finalScore = vm.score;
    _isNewRecord = vm.score >= highScore && vm.score > 0;

    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnim = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOutCubic);

    _scoreCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _scoreAnim = IntTween(begin: 0, end: _finalScore).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutExpo),
    );

    _confettiCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start sequence
    _entranceCtrl.forward().then((_) {
      _scoreCtrl.forward();
      if (_isNewRecord) _confettiCtrl.repeat();
    });

    _maybeShowInterstitial();
    _submitToFirebase();
    _showInterstitialAdIfEligible();
  }

  Future<void> _showInterstitialAdIfEligible() async {
    final hasNoAds = await IAPService().hasNoAds();
    if (!hasNoAds) {
      // Show interstitial ad every 3rd game
      final games = HiveService.getTotalGamesPlayed();
      if (games % 3 == 0) {
        await AdService().showInterstitial();
      }
    }
  }

  Future<void> _submitToFirebase() async {
    final vm = ref.read(gameViewModelProvider);
    final rank = _rankLabel(_finalScore);

    // Submit to Leaderboard
    await LeaderboardService.submitScore(
      score: _finalScore,
      rank: rank,
      jellifyLevel: vm.jellifyLevel,
      wallsPassed: vm.wallsPassed,
    );

    // Log Analytics
    await FirebaseAnalyticsService.logGameOver(
      score: _finalScore,
      rank: rank,
      wallsPassed: vm.wallsPassed,
      jellifyLevel: vm.jellifyLevel,
    );
  }

  Future<void> _maybeShowInterstitial() async {
    final games = HiveService.getTotalGamesPlayed();
    if (games % 3 == 0) {
      await AdService().showInterstitial();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _confettiCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  String _rankLabel(int score) {
    if (score >= 10000) return 'SS';
    if (score >= 5000) return 'S';
    if (score >= 2000) return 'A';
    if (score >= 800) return 'B';
    if (score >= 300) return 'C';
    if (score >= 100) return 'D';
    return 'F';
  }

  String? _rankImagePath(String rank) {
    switch (rank) {
      case 'S':
        return 'assets/images/rank_badges/rank_badge_s.jpg';
      case 'F':
        return 'assets/images/rank_badges/rank_badge_f.jpg';
      default:
        return null; // F/S only for now
    }
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'SS':
        return const Color(0xFFFF6B35);
      case 'S':
        return const Color(0xFFFFD700);
      case 'A':
        return const Color(0xFFE040FB);
      case 'B':
        return const Color(0xFF64B5F6);
      case 'C':
        return const Color(0xFF66FFB2);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(gameViewModelProvider);
    final highScore = HiveService.getHighScore();
    final rank = _rankLabel(_finalScore);
    final rankColor = _rankColor(rank);

    return Scaffold(
      backgroundColor: const Color(0xFF060212),
      body: Stack(
        children: [
          // Confetti for new record
          if (_isNewRecord)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(_confettiCtrl.value),
              ),
            ),

          SafeArea(
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Opacity(
                opacity: _slideAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _slideAnim.value)),
                  child: child,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // ── Title ──────────────────────────────────────
                      if (_isNewRecord)
                        _NewRecordBanner()
                      else
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Rank Badge (Leonardo AI or Custom) ──────────
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: _rankImagePath(rank) != null
                            ? Image.asset(
                                _rankImagePath(rank)!,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: rankColor, width: 3),
                                  color: rankColor.withOpacity(0.12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: rankColor.withOpacity(0.35),
                                        blurRadius: 20)
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    rank,
                                    style: TextStyle(
                                      color: rankColor,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // ── Score Card ─────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1A0A2E),
                              _isNewRecord
                                  ? AppColors.gold.withOpacity(0.12)
                                  : const Color(0xFF2D1B4E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _isNewRecord
                                ? AppColors.gold.withOpacity(0.6)
                                : AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: _isNewRecord
                              ? [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.2),
                                    blurRadius: 24,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            // Score count-up
                            Text(
                              'SCORE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: _scoreAnim,
                              builder: (_, __) => Text(
                                '${_scoreAnim.value}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            const Divider(
                                color: Colors.white12, height: 28, thickness: 1),

                            _StatRow(
                                label: 'ベスト',
                                value: '$highScore',
                                color: _isNewRecord ? AppColors.gold : null),
                            _StatRow(
                                label: '通過した壁',
                                value: '${vm.wallsPassed}'),
                            _StatRow(
                                label: '最大コンボ',
                                value:
                                    'x${vm.comboMultiplier.toStringAsFixed(1)}',
                                color: vm.comboMultiplier >= 2.5
                                    ? const Color(0xFFE040FB)
                                    : null),
                            _StatRow(
                                label: 'ジェリーLv',
                                value: EvolutionConfig.names[vm.jellifyLevel]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // AI message
                      if (vm.lastAIMessage != null &&
                          vm.lastAIMessage!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Text('🤖 ',
                                  style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  vm.lastAIMessage!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Rewarded ad
                      if (AdService().isRewardedReady)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gold,
                              side: const BorderSide(color: AppColors.gold),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Text('📺',
                                style: TextStyle(fontSize: 18)),
                            label: const Text(
                              '広告を見てコイン +50',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              AdService().showRewarded(
                                onRewarded: () {
                                  HiveService.addCoins(50);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('コイン +50 獲得！'),
                                      backgroundColor: AppColors.gold,
                                      duration: Duration(seconds: 2),
                                    ));
                                  }
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 10),

                      // もう一度プレイ — gradient button
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6A0DAD),
                                  Color(0xFFE040FB)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE040FB)
                                      .withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'もう一度プレイ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                          (route) => false,
                        ),
                        child: const Text(
                          'ホームへ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Record Banner ──────────────────────────────────────────────────────
class _NewRecordBanner extends StatefulWidget {
  @override
  State<_NewRecordBanner> createState() => _NewRecordBannerState();
}

class _NewRecordBannerState extends State<_NewRecordBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnim = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
        ).createShader(bounds),
        child: const Text(
          '🎉 NEW RECORD!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ── Confetti Painter ──────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _pieces = List.generate(60, (i) {
    return _ConfettiPiece(
      x: _rng.nextDouble(),
      startY: -0.1 - _rng.nextDouble() * 0.6,
      speed: 0.15 + _rng.nextDouble() * 0.25,
      drift: (_rng.nextDouble() - 0.5) * 0.1,
      size: 4.0 + _rng.nextDouble() * 6.0,
      color: [
        const Color(0xFFFFD700),
        const Color(0xFFE040FB),
        const Color(0xFF64B5F6),
        const Color(0xFF66FFB2),
        const Color(0xFFFF6B35),
        Colors.white,
      ][i % 6],
      rotation: _rng.nextDouble() * 2 * pi,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 4,
      isRect: _rng.nextBool(),
    );
  });

  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _pieces) {
      final x = (p.x + p.drift * t) * size.width;
      final y = ((p.startY + p.speed * t) % 1.2) * size.height;
      final opacity = (y / size.height).clamp(0.0, 1.0) < 0.9
          ? 0.85
          : 0.0;
      if (opacity <= 0) continue;

      paint.color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.isRect) {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size * 1.4, height: p.size * 0.6),
            paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.55, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

class _ConfettiPiece {
  final double x, startY, speed, drift, size, rotation, rotationSpeed;
  final Color color;
  final bool isRect;
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isRect,
  });
}

// ── Stat Row ──────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
