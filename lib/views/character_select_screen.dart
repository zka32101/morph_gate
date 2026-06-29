import 'dart:math';
import 'package:flutter/material.dart';
import '../models/character_model.dart';
import '../services/character_service.dart';
import '../services/hive_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  late String _selectedId;
  late List<String> _unlocked;
  late int _coins;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _refresh();
    _bgCtrl = AnimationController(
        duration: const Duration(seconds: 8), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    _selectedId = CharacterService.getSelectedId();
    _unlocked = CharacterService.getUnlocked();
    _coins = HiveService.getOrCreateUser().coins;
  }

  void _onTap(CharacterDef def) {
    SoundService().playButton();
    if (CharacterService.isUnlocked(def.id)) {
      CharacterService.select(def.id);
      setState(() => _selectedId = def.id);
    } else {
      _showUnlockDialog(def);
    }
  }

  void _showUnlockDialog(CharacterDef def) {
    showDialog(
      context: context,
      builder: (_) => _UnlockDialog(
        def: def,
        coins: _coins,
        onUnlock: () {
          final ok = CharacterService.unlock(def.id);
          Navigator.pop(context);
          if (ok) {
            setState(() {
              _refresh();
              _selectedId = def.id;
              CharacterService.select(def.id);
            });
          }
        },
      ),
    );
  }

  CharacterDef get _selectedDef => CharacterCatalog.getById(_selectedId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04010E),
      body: Stack(
        children: [
          // ── Animated background ────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SelectBgPainter(_bgCtrl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSelectedPreview(),
                Expanded(child: _buildGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFCE93D8), Colors.white, Color(0xFFE040FB)],
              ).createShader(b),
              child: const Text(
                'JELLY SELECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // Coin display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D2900), Color(0xFF5C3D00)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.withOpacity(0.2),
                    blurRadius: 8)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPreview() {
    final def = _selectedDef;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              def.baseColor.withOpacity(0.12),
              const Color(0xFF0E0520),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: def.baseColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: def.glowColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            _LargeJellyPreview(def: def, bgCtrl: _bgCtrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        def.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        def.name,
                        style: TextStyle(
                          color: def.baseColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: def.glowColor, blurRadius: 8)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: def.baseColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: def.baseColor.withOpacity(0.4)),
                    ),
                    child: const Text(
                      '✓ 使用中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: CharacterCatalog.all.length,
      itemBuilder: (_, i) {
        final def = CharacterCatalog.all[i];
        final unlocked = _unlocked.contains(def.id);
        final selected = _selectedId == def.id;
        return _CharacterCard(
          def: def,
          unlocked: unlocked,
          selected: selected,
          index: i,
          onTap: () => _onTap(def),
        );
      },
    );
  }
}

// ── Large preview in header ────────────────────────────────────────────────
class _LargeJellyPreview extends StatelessWidget {
  final CharacterDef def;
  final Animation<double> bgCtrl;
  const _LargeJellyPreview({required this.def, required this.bgCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: AnimatedBuilder(
        animation: bgCtrl,
        builder: (_, __) {
          final pulse = (sin(bgCtrl.value * 2 * pi) + 1) / 2;
          return def.assetImage != null
              ? Opacity(
                  opacity: 0.7 + pulse * 0.3,
                  child: Image.asset(
                    def.assetImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : CustomPaint(
                  painter: _JellyPainter(
                    color: def.baseColor,
                    glowColor: def.glowColor,
                    pulse: pulse,
                  ),
                );
        },
      ),
    );
  }
}

// ── Character card ─────────────────────────────────────────────────────────
class _CharacterCard extends StatefulWidget {
  final CharacterDef def;
  final bool unlocked;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.def,
    required this.unlocked,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _tapCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _tapAnim;
  late Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat(reverse: true);

    _tapCtrl = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _tapAnim = Tween(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    _entranceCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _entranceAnim = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tapCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final selected = widget.selected;
    final unlocked = widget.unlocked;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _tapAnim, _entranceAnim]),
      builder: (_, __) {
        final pulse = _pulseCtrl.value;
        final entrance = _entranceAnim.value;

        return Opacity(
          opacity: entrance,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - entrance)),
            child: Transform.scale(
              scale: _tapAnim.value,
              child: GestureDetector(
                onTapDown: (_) {
                  _tapCtrl.forward();
                  widget.onTap();
                },
                onTapUp: (_) => _tapCtrl.reverse(),
                onTapCancel: () => _tapCtrl.reverse(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selected
                          ? [
                              def.baseColor.withOpacity(0.22),
                              def.baseColor.withOpacity(0.06),
                            ]
                          : unlocked
                              ? [
                                  const Color(0xFF12062A),
                                  const Color(0xFF0A0318),
                                ]
                              : [
                                  const Color(0xFF0A0318),
                                  const Color(0xFF060210),
                                ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? def.baseColor.withOpacity(0.9)
                          : unlocked
                              ? def.baseColor.withOpacity(
                                  0.25 + 0.15 * pulse)
                              : Colors.white.withOpacity(0.06),
                      width: selected ? 2.0 : 1.0,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: def.glowColor.withOpacity(
                                  0.25 + 0.15 * pulse),
                              blurRadius: 18,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _JellyPreview(
                              def: def,
                              unlocked: unlocked,
                              pulse: pulse,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              def.name,
                              style: TextStyle(
                                color: unlocked
                                    ? def.baseColor
                                    : Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 3),
                            if (!unlocked)
                              _PriceTag(price: def.price, pulse: pulse)
                            else
                              Text(
                                def.description,
                                style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.35),
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      // Selected badge
                      if (selected)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [def.baseColor, def.glowColor],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: def.glowColor.withOpacity(0.4),
                                    blurRadius: 6)
                              ],
                            ),
                            child: const Text(
                              'ON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                      // Lock icon
                      if (!unlocked)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Icon(
                              Icons.lock,
                              color: Colors.white.withOpacity(0.4),
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Price tag ──────────────────────────────────────────────────────────────
class _PriceTag extends StatelessWidget {
  final int price;
  final double pulse;
  const _PriceTag({required this.price, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.15),
            AppColors.gold.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.gold.withOpacity(0.3 + 0.2 * pulse)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on,
              color: AppColors.gold.withOpacity(0.85), size: 10),
          const SizedBox(width: 2),
          Text(
            '$price',
            style: TextStyle(
              color: AppColors.gold.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jelly preview ──────────────────────────────────────────────────────────
class _JellyPreview extends StatelessWidget {
  final CharacterDef def;
  final bool unlocked;
  final double pulse;

  const _JellyPreview(
      {required this.def, required this.unlocked, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: def.assetImage != null
          ? Opacity(
              opacity: unlocked ? 1.0 : 0.25,
              child: Image.asset(
                def.assetImage!,
                fit: BoxFit.cover,
              ),
            )
          : CustomPaint(
              painter: _JellyPainter(
                color: unlocked ? def.baseColor : def.baseColor.withOpacity(0.25),
                glowColor: unlocked ? def.glowColor : def.glowColor.withOpacity(0.08),
                pulse: pulse,
              ),
            ),
    );
  }
}

class _JellyPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final double pulse;

  _JellyPainter(
      {required this.color, required this.glowColor, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36 * (1.0 + pulse * 0.05);

    // Outer glow
    canvas.drawCircle(
      center,
      radius * 1.5,
      Paint()
        ..color = glowColor.withOpacity(0.2 + pulse * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Inner glow
    canvas.drawCircle(
      center,
      radius * 1.1,
      Paint()
        ..color = glowColor.withOpacity(0.3 + pulse * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    ShapeUtils.drawShape(canvas, ShapeType.circle, center, radius, color,
        glowing: true);

    // Specular highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.28),
      radius * 0.28,
      Paint()
        ..color = Colors.white.withOpacity(0.22 + pulse * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Orbiting particle
    final angle1 = pulse * 2 * pi;
    final angle2 = pulse * 2 * pi + pi;
    for (final angle in [angle1, angle2]) {
      final px = center.dx + cos(angle) * (radius + 9);
      final py = center.dy + sin(angle) * (radius + 9) * 0.6;
      canvas.drawCircle(
        Offset(px, py),
        2.5,
        Paint()
          ..color = color.withOpacity(0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JellyPainter old) =>
      old.pulse != pulse || old.color != color;
}

// ── Background painter ─────────────────────────────────────────────────────
class _SelectBgPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _shapes = List.generate(12, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    speed: 0.03 + _rng.nextDouble() * 0.04,
    size: 12.0 + _rng.nextDouble() * 20,
    color: [
      const Color(0xFF7B2FBE),
      const Color(0xFF5DADE2),
      const Color(0xFF76FF03),
      const Color(0xFFFFD700),
      const Color(0xFFFF6B35),
      const Color(0xFFE040FB),
    ][i % 6],
    shape: ShapeType.values[i % 4],
    phase: _rng.nextDouble(),
  ));

  _SelectBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06011A), Color(0xFF040110)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Floating shapes
    for (final s in _shapes) {
      final pt = (t * s.speed + s.phase) % 1.0;
      final y = size.height * (1.0 - pt * 1.2 + s.y * 0.2);
      final x = s.x * size.width +
          sin(t * 2 * pi * s.speed + s.phase) * 20;
      final opacity = pt < 0.1
          ? pt * 10 * 0.06
          : (1.0 - pt) < 0.1
              ? (1.0 - pt) * 10 * 0.06
              : 0.06;

      ShapeUtils.drawShape(
        canvas,
        s.shape,
        Offset(x, y),
        s.size,
        s.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectBgPainter old) => old.t != t;
}

// ── Unlock dialog ──────────────────────────────────────────────────────────
class _UnlockDialog extends StatefulWidget {
  final CharacterDef def;
  final int coins;
  final VoidCallback onUnlock;

  const _UnlockDialog({
    required this.def,
    required this.coins,
    required this.onUnlock,
  });

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this)
      ..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final canAfford = widget.coins >= def.price;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0A2E),
                def.baseColor.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: def.baseColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: def.glowColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Jelly preview
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _JellyPainter(
                    color: def.baseColor,
                    glowColor: def.glowColor,
                    pulse: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                def.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                def.name,
                style: TextStyle(
                  color: def.baseColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: def.glowColor, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                def.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Price
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withOpacity(canAfford ? 0.2 : 0.08),
                      AppColors.gold.withOpacity(canAfford ? 0.08 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.gold
                          .withOpacity(canAfford ? 0.5 : 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on,
                        color: AppColors.gold
                            .withOpacity(canAfford ? 1.0 : 0.5),
                        size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${def.price}',
                      style: TextStyle(
                        color: AppColors.gold
                            .withOpacity(canAfford ? 1.0 : 0.5),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '(所持: ${widget.coins})',
                      style: TextStyle(
                        color: (canAfford
                                ? AppColors.textSecondary
                                : AppColors.accent)
                            .withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                      child: const Text('キャンセル',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canAfford ? widget.onUnlock : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.white12;
                          }
                          return null;
                        }),
                        foregroundColor:
                            WidgetStateProperty.all(Colors.white),
                      ),
                      child: Ink(
                        decoration: canAfford
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [def.baseColor, def.glowColor],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          def.glowColor.withOpacity(0.4),
                                      blurRadius: 10)
                                ],
                              )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            '解放する',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
