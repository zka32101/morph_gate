import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../game/wall_game.dart';
import '../game/game_state.dart';
import '../services/ad_service.dart';
import '../services/hive_service.dart';
import '../services/iap_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';
import '../viewmodels/game_viewmodel.dart';
import 'game_over_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  WallGame? _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(gameViewModelProvider);
      vm.initGame();
      setState(() {
        _game = WallGame(gameState: vm, onGameOver: _onGameOver);
      });
      SoundService().startBgm();
    });
  }

  void _onGameOver() {
    SoundService().stopBgm();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameOverScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(gameViewModelProvider);

    if (_game == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GameWidget(game: _game!),
          _buildHUD(vm),
          _buildShapeButtons(vm),
          if (vm.showEvolutionOverlay) _buildEvolutionOverlay(vm),
          // ── Bottom Banner Ad ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FutureBuilder<bool>(
              future: IAPService().hasNoAds(),
              builder: (context, snapshot) {
                // Only show ads if user hasn't purchased no-ads
                if (snapshot.data == true) {
                  return const SizedBox.shrink();
                }
                return _buildBannerAd();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Ad ──────────────────────────────────────────────────────────
  Widget _buildBannerAd() {
    return SizedBox(
      height: 50,
      child: AdWidget(ad: AdService().createBanner()),
    );
  }

  // ── HUD ────────────────────────────────────────────────────────────────
  Widget _buildHUD(GameViewModel vm) {
    final best = HiveService.getHighScore();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 12,
          right: 12,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score panel ──────────────────────────────────────────
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${vm.score}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'BEST ${best > 0 ? best : '---'}',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Center info ──────────────────────────────────────────
            Column(
              children: [
                if (vm.comboMultiplier > 1.0)
                  _ComboDisplay(multiplier: vm.comboMultiplier),
                const SizedBox(height: 4),
                Text(
                  '${vm.wallsPassed} 壁',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                if (vm.hasGhost) ...[
                  const SizedBox(height: 2),
                  _GhostBadge(current: vm.score, ghost: vm.ghostScore),
                ],
              ],
            ),

            const Spacer(),

            // ── Mission status (bottom right) ────────────────────────
            if (vm.currentMission != null)
              _buildMissionStatus(vm.currentMission!)
            else
              const SizedBox(width: 140),

            const SizedBox(width: 8),

            // ── Jelly status ─────────────────────────────────────────
            _buildJellyStatus(vm),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionStatus(Mission mission) {
    final missionColor = switch (mission.type) {
      MissionType.wallsPassed => const Color(0xFF9C6FFF),
      MissionType.comboStreak => const Color(0xFFE040FB),
      MissionType.noShieldLoss => const Color(0xFF64B5F6),
      MissionType.dangerSurvive => const Color(0xFFFF5577),
      MissionType.bonusWalls => const Color(0xFF66FFB2),
    };

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                mission.icon,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                'MISSION',
                style: TextStyle(
                  color: missionColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mission.progressText,
            style: TextStyle(
              color: missionColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 90,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: LinearProgressIndicator(
                value: (mission.progress / mission.targetValue).clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(missionColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJellyStatus(GameViewModel vm) {
    final level = vm.jellifyLevel;
    final thresholds = EvolutionConfig.thresholds;
    final nextT = level < 4 ? thresholds[level + 1] : null;
    final progress = nextT != null
        ? (vm.wallsPassed / (nextT - thresholds[level])).clamp(0.0, 1.0)
        : 1.0;
    final color = _evolutionColor(level);

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            EvolutionConfig.names[level],
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shape buttons ───────────────────────────────────────────────────────
  Widget _buildShapeButtons(GameViewModel vm) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 14,
          left: 12,
          right: 12,
          top: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.92),
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Composite hint
            if (vm.isCompositeActive && vm.activeComposite != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE040FB).withOpacity(0.4),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Text(
                  '${ShapeUtils.compositeShapeLabel(vm.activeComposite!)} 複合形状',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 1,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '同時押し → 複合形状',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 1,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ],
                ),
              ),

            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ShapeType.values
                  .map((shape) => _ShapeButton(
                        shape: shape,
                        isActive: !vm.isCompositeActive &&
                            vm.activeShape == shape,
                        isHinted: false, // Disabled: mystery mode
                        onPressed: () => _game?.onShapeButtonPressed(shape),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Evolution overlay ───────────────────────────────────────────────────
  Widget _buildEvolutionOverlay(GameViewModel vm) {
    return _EvolutionOverlay(
      vm: vm,
      color: _evolutionColor(vm.jellifyLevel),
    );
  }

  Color _evolutionColor(int level) {
    switch (level) {
      case 0: return AppColors.jellySteelBlue;
      case 1: return AppColors.jellyGreen;
      case 2: return AppColors.jellyCrystal;
      case 3: return AppColors.jellyGhost;
      default: return AppColors.jellyPrimordial;
    }
  }
}

// ── Glass panel helper ─────────────────────────────────────────────────────
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: child,
    );
  }
}

// ── Combo display ──────────────────────────────────────────────────────────
class _ComboDisplay extends StatefulWidget {
  final double multiplier;
  const _ComboDisplay({required this.multiplier});

  @override
  State<_ComboDisplay> createState() => _ComboDisplayState();
}

class _ComboDisplayState extends State<_ComboDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.multiplier >= 2.5) return const Color(0xFFFF6B35);
    if (widget.multiplier >= 1.8) return const Color(0xFFE040FB);
    return const Color(0xFF64B5F6);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [c.withOpacity(0.85), c]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: c.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1)
            ],
          ),
          child: Text(
            'x${widget.multiplier.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ghost badge ────────────────────────────────────────────────────────────
class _GhostBadge extends StatelessWidget {
  final int current, ghost;
  const _GhostBadge({required this.current, required this.ghost});

  @override
  Widget build(BuildContext context) {
    final ahead = current - ghost;
    final color = ahead >= 0 ? AppColors.jellyGreen : AppColors.shapeTriangle;
    final sign = ahead >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text('👻 $sign$ahead',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Shape button ───────────────────────────────────────────────────────────
class _ShapeButton extends StatefulWidget {
  final ShapeType shape;
  final bool isActive;
  final bool isHinted;
  final VoidCallback onPressed;

  const _ShapeButton({
    required this.shape,
    required this.isActive,
    required this.onPressed,
    this.isHinted = false,
  });

  @override
  State<_ShapeButton> createState() => _ShapeButtonState();
}

class _ShapeButtonState extends State<_ShapeButton>
    with TickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late AnimationController _hintCtrl;
  late AnimationController _activeCtrl;
  late Animation<double> _tapAnim;
  late Animation<double> _hintAnim;
  late Animation<double> _activeAnim;

  @override
  void initState() {
    super.initState();

    _tapCtrl = AnimationController(
        duration: const Duration(milliseconds: 80), vsync: this);
    _tapAnim = Tween(begin: 1.0, end: 0.82).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    _hintCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..repeat(reverse: true);
    _hintAnim = CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut);

    _activeCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _activeAnim = CurvedAnimation(parent: _activeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    _hintCtrl.dispose();
    _activeCtrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.shape) {
      case ShapeType.square: return AppColors.shapeSquare;
      case ShapeType.circle: return AppColors.shapeCircle;
      case ShapeType.star: return AppColors.shapeStar;
      case ShapeType.triangle: return AppColors.shapeTriangle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;

    return GestureDetector(
      onTapDown: (_) {
        _tapCtrl.forward();
        widget.onPressed();
      },
      onTapUp: (_) => _tapCtrl.reverse(),
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapAnim, _hintAnim, _activeAnim]),
        builder: (_, __) {
          final scale = _tapAnim.value;
          final hint = _hintAnim.value;
          final active = _activeAnim.value;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _ShapeButtonPainter(
                  shape: widget.shape,
                  color: c,
                  isActive: widget.isActive,
                  isHinted: widget.isHinted,
                  hintValue: hint,
                  activeValue: active,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShapeButtonPainter extends CustomPainter {
  final ShapeType shape;
  final Color color;
  final bool isActive;
  final bool isHinted;
  final double hintValue;
  final double activeValue;

  _ShapeButtonPainter({
    required this.shape,
    required this.color,
    required this.isActive,
    required this.isHinted,
    required this.hintValue,
    required this.activeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    // ── Background ───────────────────────────────────────────────────
    if (isActive) {
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.28 + 0.06 * activeValue),
              color.withOpacity(0.12),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    } else {
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0E0520)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // ── Active outer glow ─────────────────────────────────────────────
    if (isActive) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-3, -3, size.width + 6, size.height + 6),
          const Radius.circular(23),
        ),
        Paint()
          ..color = color.withOpacity(0.25 + 0.15 * activeValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // ── Hint glow ─────────────────────────────────────────────────────
    if (isHinted && !isActive) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8),
          const Radius.circular(24),
        ),
        Paint()
          ..color = color.withOpacity(0.15 + 0.3 * hintValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // ── Border ────────────────────────────────────────────────────────
    final borderOpacity = isActive
        ? 0.85
        : isHinted
            ? 0.3 + 0.55 * hintValue
            : 0.28;
    final borderWidth = isActive ? 2.0 : 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          borderWidth / 2, borderWidth / 2,
          size.width - borderWidth, size.height - borderWidth,
        ),
        Radius.circular(20 - borderWidth / 2),
      ),
      Paint()
        ..color = color.withOpacity(borderOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // ── Shape glow ────────────────────────────────────────────────────
    if (isActive) {
      ShapeUtils.drawShape(
        canvas, shape, center, 26,
        color.withOpacity(0.3 + 0.1 * activeValue),
      );
    }

    // ── Shape ─────────────────────────────────────────────────────────
    final shapeOpacity = isActive
        ? 1.0
        : isHinted
            ? 0.55 + 0.35 * hintValue
            : 0.42;
    ShapeUtils.drawShape(
      canvas, shape, center, 22,
      color.withOpacity(shapeOpacity),
      glowing: isActive,
    );

    // ── Active inner highlight ────────────────────────────────────────
    if (isActive) {
      final hlPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, size.width - 8, 20),
          const Radius.circular(10),
        ),
        hlPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeButtonPainter old) =>
      old.isActive != isActive ||
      old.isHinted != isHinted ||
      old.hintValue != hintValue ||
      old.activeValue != activeValue ||
      old.shape != shape;
}

// ── Evolution overlay ──────────────────────────────────────────────────────
class _EvolutionOverlay extends StatefulWidget {
  final GameViewModel vm;
  final Color color;
  const _EvolutionOverlay({required this.vm, required this.color});

  @override
  State<_EvolutionOverlay> createState() => _EvolutionOverlayState();
}

class _EvolutionOverlayState extends State<_EvolutionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _scaleAnim = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut));
    _fadeAnim =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _particleCtrl = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final c = widget.color;

    return GestureDetector(
      onTap: vm.dismissEvolutionOverlay,
      child: Stack(
        children: [
          // Dark overlay
          AnimatedBuilder(
            animation: _fadeAnim,
            builder: (_, __) => Container(
              color: Colors.black.withOpacity(0.75 * _fadeAnim.value),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _EvolutionParticlePainter(_particleCtrl.value, c),
            ),
          ),

          // Card
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleAnim, _fadeAnim]),
              builder: (_, child) => Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(opacity: _fadeAnim.value, child: child),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A0A2E),
                      c.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.withOpacity(0.7), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: c.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 4),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.withOpacity(0.15),
                        border: Border.all(color: c.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: c.withOpacity(0.3), blurRadius: 16)
                        ],
                      ),
                      child: Center(
                        child: Text('✨',
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [c, Colors.white, c],
                      ).createShader(bounds),
                      child: const Text(
                        '進 化',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      EvolutionConfig.names[vm.jellifyLevel],
                      style: TextStyle(
                        color: c,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: c, blurRadius: 8)],
                      ),
                    ),

                    if (vm.evolutionStory != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Text(
                          vm.evolutionStory!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Text(
                      'タップして続ける',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionParticlePainter extends CustomPainter {
  final double t;
  final Color color;
  static final _rng = Random(123);
  static final _dots = List.generate(30, (i) => (
    x: _rng.nextDouble(),
    speed: 0.08 + _rng.nextDouble() * 0.12,
    drift: (_rng.nextDouble() - 0.5) * 0.04,
    size: 2.0 + _rng.nextDouble() * 3.0,
    phase: _rng.nextDouble(),
  ));

  _EvolutionParticlePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final pt = (t + d.phase) % 1.0;
      final y = size.height * (1.0 - pt * 1.2);
      final x = d.x * size.width + d.drift * size.width * t;
      final opacity = pt < 0.2 ? pt / 0.2 * 0.6 : (1.0 - pt) / 0.8 * 0.6;

      canvas.drawCircle(
        Offset(x, y),
        d.size * (1 - pt * 0.3),
        Paint()..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionParticlePainter old) =>
      old.t != t || old.color != color;
}
